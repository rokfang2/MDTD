"""Run the Godot checks in a copy; never run progression tests on a personal save."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN') or shutil.which('godot') or shutil.which('godot4'))
    args = parser.parse_args()
    if not args.godot:
        parser.error('Use --godot PATH or set GODOT_BIN to the Godot 4.7.2 executable.')
    engine = str(Path(args.godot).resolve())
    source = Path(__file__).resolve().parents[1]
    sandbox = Path(tempfile.mkdtemp(prefix='mdtd-qa-')).resolve()
    logs = sandbox / 'qa-logs'
    logs.mkdir()
    print('QA_COPY:', sandbox, flush=True)
    manifest = {}
    for folder in ('scripts', 'scenes', 'assets', 'tests'):
        shutil.copytree(source / folder, sandbox / folder)
        for path in (source / folder).rglob('*'):
            if path.is_file():
                manifest[str(path.relative_to(source))] = hashlib.sha256(path.read_bytes()).hexdigest()
    project = (source / 'project.godot').read_text(encoding='utf-8')
    project = re.sub(r'^config/(?:use_custom_user_dir|custom_user_dir_name)=.*\n?', '', project, flags=re.M)

    def namespace(name):
        isolated = project.replace('[application]', '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="' + name + '"')
        (sandbox / 'project.godot').write_text(isolated, encoding='utf-8')

    namespace('MushroomsStationaryPrayerQA')
    (sandbox / 'tests/qa_namespace.gd').write_text('extends SceneTree\nfunc _initialize():\n\tprint("QA_USER_DIR: ",OS.get_user_data_dir())\n\tquit()\n', encoding='utf-8')
    entries = []

    def run(label, arguments):
        result = subprocess.run([engine, '--headless', '--path', str(sandbox)] + arguments,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=240)
        output = result.stdout.decode('utf-8', errors='replace')
        (logs / (label + '.log')).write_text(output, encoding='utf-8')
        passed = result.returncode == 0 and not re.search(r'SCRIPT ERROR:|FAIL:|ERROR:', output)
        counts = [list(map(int, pair)) for pair in re.findall(r'RESULT:\s*(\d+)\s*/\s*(\d+)', output)]
        if not counts:
            successes = len(re.findall(r'^PASS:', output, re.M))
            failures = len(re.findall(r'^FAIL:', output, re.M))
            if successes + failures:
                counts = [[successes, successes + failures]]
        entry = {'suite': label, 'exit_code': result.returncode, 'ok': passed, 'counts': counts}
        entries.append(entry)
        print(json.dumps(entry), flush=True)
        return entry, output

    entry, output = run('import', ['--editor', '--import', '--quit'])
    if not entry['ok'] and entry['exit_code'] in (-1073741819, 3221225477) and not re.search(r'SCRIPT ERROR:|ERROR:', output):
        print('Native importer exit failure; preserving first log and retrying once.', flush=True)
        entry, output = run('import_retry', ['--editor', '--import', '--quit'])
    if not entry['ok']:
        raise RuntimeError('Import failed. Logs: ' + str(logs))
    helpers = source / 'review/borders_boss/tester'
    for name in ('environment_cohesion', 'soil_geometry', 'boss_counterplay'):
        shutil.copy2(helpers / (name + '.gd'), sandbox / 'tests' / ('qa_' + name + '.gd'))
    suites = ['verify', 'movement_review', 'review_regressions', 'map_expansion',
              'readability_review', 'art_presentation', 'motion_animation', 'motion_wood',
              'arm_swing', 'full_motion_cycle', 'run_cadence', 'sword_cut', 'resource_visibility',
              'stationary_prayer', 'new_map_routes', 'map_projection', 'qa_environment_cohesion',
              'boss_encounter', 'qa_soil_geometry', 'qa_boss_counterplay']
    current_namespace = None
    for suite in suites:
        required = 'MushroomsNewMapRoutesQA' if suite == 'new_map_routes' else 'MushroomsStationaryPrayerQA'
        if required != current_namespace:
            namespace(required)
            probe, output = run('namespace_' + suite, ['--script', 'res://tests/qa_namespace.gd'])
            if not probe['ok'] or not re.search(r'QA_USER_DIR: .*[/\\]' + required + r'\s*$', output, re.M):
                raise RuntimeError('QA namespace not confirmed; refusing progression tests.')
            current_namespace = required
        run(suite, ['--fixed-fps', '60', '--script', 'res://tests/' + suite + '.gd'])
    changed = [name for name, value in manifest.items() if hashlib.sha256((source / name).read_bytes()).hexdigest() != value]
    total = [pair for entry in entries for pair in entry['counts']]
    passed = sum(pair[0] for pair in total)
    expected = sum(pair[1] for pair in total)
    failures = [entry for entry in entries if not entry['ok'] and entry['suite'] != 'import']
    report = {'checks_passed': passed, 'checks_total': expected, 'suites': entries,
              'source_changed_during_tests': changed, 'scope': 'Engine automation; not human playtesting.'}
    (logs / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print('RESULT:', str(passed) + '/' + str(expected), 'Logs:', logs, flush=True)
    return 0 if not failures and not changed and passed == expected and expected > 0 else 1


if __name__ == '__main__':
    raise SystemExit(main())
