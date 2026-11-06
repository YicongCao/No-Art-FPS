#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out=builds/demo
mkdir -p "$out"
touch builds/.gdignore
"${GODOT_BIN:-godot}" --path . --resolution 1280x720 --disable-vsync --fixed-fps 30 \
  --write-movie "$out/no-art-fps.avi" --quit-after 1080 -- --qa --record-demo \
  > "$out/capture.log" 2>&1
rg 'DEMO_CAPTURE_PASS' "$out/capture.log"
frames=$(ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames \
  -of default=noprint_wrappers=1:nokey=1 "$out/no-art-fps.avi")
# Movie Maker includes the first few startup frames before the capture node runs.
start=$((frames - 900))
test "$start" -ge 0
ffmpeg -hide_banner -loglevel error -y -i "$out/no-art-fps.avi" \
  -vf "trim=start_frame=$start,setpts=PTS-STARTPTS" \
  -af "atrim=start_sample=$((start * 1600)),asetpts=PTS-STARTPTS,afade=t=out:st=29.7:d=0.3" \
  -t 30 -c:v libx264 -preset slow -crf 21 -pix_fmt yuv420p \
  -c:a aac -b:a 128k -movflags +faststart "$out/no-art-fps-demo.mp4"
