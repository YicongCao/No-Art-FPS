"""Bounded Godot checks that reject engine errors even when exit code is zero."""
import subprocess, sys
from pathlib import Path
command = ['godot', '--path', '.'] + sys.argv[1:]
try:
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=240)
except subprocess.TimeoutExpired as error:
    print(error.stdout.decode() if isinstance(error.stdout, bytes) else error.stdout)
    raise
Path('logs').mkdir(exist_ok=True)
Path('logs/latest-check.log').write_text(result.stdout)
print(result.stdout if len(result.stdout)<16000 else result.stdout[:8000]+"\n... full log: logs/latest-check.log ...\n"+result.stdout[-4000:])
if result.returncode or 'ERROR:' in result.stdout:
    raise SystemExit(1)
