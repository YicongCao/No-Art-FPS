"""Run isolated native normal/frenzy/transition trials for a model evolution stage."""
import argparse
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('map')
    parser.add_argument('version', choices=['before', 'after'])
    parser.add_argument('--seconds', type=float, default=8)
    parser.add_argument('--trials', type=int, default=3)
    parser.add_argument('--phases', nargs='+', choices=['normal','frenzy','transition','natural-transition'],
                        default=['normal','frenzy','transition'])
    args = parser.parse_args()
    assert args.seconds >= 1 and args.trials >= 3
    assert args.map.replace('_', '').isalnum()
    out = ROOT / 'artifacts/local/scene-evolution' / args.map
    out.mkdir(parents=True, exist_ok=True)
    for phase in args.phases:
        for trial in range(1, args.trials+1):
            stem = f'{args.version}-{phase}-{trial}'
            env = dict(os.environ, PERF_MAPS=args.map, PERF_SECONDS=str(args.seconds),
                       PERF_FRENZY=str(int(phase == 'frenzy')),
                       PERF_TRANSITION=str(int(phase == 'transition')),
                       PERF_NATURAL_TRANSITION=str(int(phase == 'natural-transition')),
                       PERF_OUTPUT=str(out / (stem+'.json')))
            with (out / (stem+'.log')).open('w') as log:
                result = subprocess.run(['godot', '--path', str(ROOT), '--script',
                    'tools/maps/capture_visual_performance.gd'], cwd=ROOT, env=env,
                    stdout=log, stderr=subprocess.STDOUT, timeout=120+args.seconds)
            text = (out / (stem+'.log')).read_text()
            assert result.returncode == 0 and 'ERROR:' not in text and 'VISUAL_PERF' in text, stem
            data = json.loads((out / (stem+'.json')).read_text())
            assert len(data['maps']) == 1 and data['maps'][0]['map'] == args.map, stem
            print(stem, 'PASS', flush=True)
