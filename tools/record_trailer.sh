#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

fps=60
frames=900
work=builds/trailer
output=artifacts/gameplay-trailer.mp4
mkdir -p "$work"
touch builds/.gdignore
filters=

record_take() {
  take=$1
  movie="$takes/$take.avi"
  log="$takes/$take.log"
  if ! "${GODOT_BIN:-godot}" --path "$project" --resolution 1280x720 --disable-vsync \
    --fixed-fps "$fps" --write-movie "$PWD/$movie" --quit-after 1320 \
    --script tools/record_trailer.gd -- "--$take" >"$log" 2>&1; then
    cat "$log" >&2
    return 1
  fi
}

trim_take() {
  take=$1
  input=$2
  movie="$takes/$take.avi"
  log="$takes/$take.log"
  rg 'TRAILER_TAKE_PASS' "$log"
  dimensions=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$movie")
  test "$dimensions" = 1920x1080
  captured=$(ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of csv=p=0 "$movie")
  rate=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of csv=p=0 "$movie")
  test "$((rate % fps))" -eq 0
  # Startup adds a few frames before the director begins. Take exactly the
  # last 900 frames and the corresponding audio samples from each recording.
  start=$((captured - frames))
  test "$start" -ge 0
  audio_start=$((start * rate / fps))
  audio_end=$((captured * rate / fps))
  filters="${filters}[${input}:v]trim=start_frame=$start:end_frame=$captured,setpts=PTS-STARTPTS[v$input];[${input}:a]atrim=start_sample=$audio_start:end_sample=$audio_end,asetpts=PTS-STARTPTS[a$input];"
}

if [ "$#" -eq 0 ]; then
  takes=$(mktemp -d "$work/takes.XXXXXX")
  project="$takes/project"
  mkdir "$project"
  "${GODOT_BIN:-godot}" --headless --path . --editor --import >"$takes/import.log" 2>&1
  cp project.godot "$project/"
  for directory in .godot assets data scenes scripts tools; do
    ln -s "$PWD/$directory" "$project/$directory"
  done
  # Movie Maker fixes the output size at startup. Render at 1080p even on
  # a monitor that cannot fit a 1920 × 1080 window.
  cat > "$project/override.cfg" <<'CONFIG'
[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="viewport"
CONFIG
  record_take yard
  record_take park
  record_take ferry
elif [ "$#" -eq 2 ] && [ "$1" = "--stitch" ] && [ -d "$2" ]; then
  takes=$2
else
  printf 'Usage: %s [--stitch builds/trailer/takes.DIRECTORY]\n' "$0" >&2
  exit 2
fi

trim_take yard 0
trim_take park 1
trim_take ferry 2

ffmpeg -hide_banner -loglevel error -y -i "$takes/yard.avi" -i "$takes/park.avi" -i "$takes/ferry.avi" \
  -filter_complex "${filters}[v0][a0][v1][a1][v2][a2]concat=n=3:v=1:a=1[v][mix];[mix]volume=5dB[a]" \
  -map '[v]' -map '[a]' -c:v libx264 -preset medium -crf 18 -maxrate 8M -bufsize 12M \
  -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "$takes/trailer.mp4"

metadata=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate,nb_frames -of csv=p=0 "$takes/trailer.mp4")
test "$metadata" = '1920,1080,60/1,2700'
duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$takes/trailer.mp4")
test "$duration" = 45.000000
mv "$takes/trailer.mp4" "$output"
printf 'Recorded %s (%s seconds). Source takes: %s\n' "$output" "$duration" "$takes"
