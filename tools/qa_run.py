"""Bounded Godot checks; fail immediately on script/engine errors."""
import subprocess, sys, threading
from pathlib import Path
command = ['godot', '--path', '.'] + sys.argv[1:]
process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
expired = []
def timeout():
    expired.append(True)
    process.kill()
timer = threading.Timer(240, timeout)
timer.start()
lines = []
failed = False
try:
    for line in process.stdout:
        lines.append(line)
        if 'ERROR:' in line:
            failed = True
            process.terminate()
    process.wait()
finally:
    timer.cancel()
output = ''.join(lines)
Path('logs').mkdir(exist_ok=True)
Path('logs/latest-check.log').write_text(output)
print(output if len(output)<16000 else output[:8000]+'\n... logs/latest-check.log ...\n'+output[-4000:])
if failed or expired or process.returncode:
    raise SystemExit(1)
