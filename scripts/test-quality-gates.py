"""Check quality gates in a disposable repository (requires Bash and jq)."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import textwrap

root = Path(__file__).resolve().parents[1]
bash = shutil.which("bash")
if os.name == "nt":
    bash = str(Path(shutil.which("git")).parents[1] / "bin/bash.exe")
assert shutil.which("jq"), "Install jq to verify real SAST result parsing"

with tempfile.TemporaryDirectory(prefix="spec-flow-gates-") as temporary:
    project = Path(temporary) / "project with spaces"
    scripts = project / ".spec-flow/scripts/bash"
    scripts.mkdir(parents=True)
    (project / "package.json").write_text('{"scripts":{"test":"exit 0"}}')
    nested = project / "nested"
    nested.mkdir()
    subprocess.run(["git", "init", "--quiet", str(project)], check=True)

    workflow = (root / ".github/workflows/quality-gates.yml").read_text(encoding="utf-8")
    state_diff = workflow.split("if git diff --quiet", 1)[1].split("; then", 1)[0]
    state = project / ".spec-flow/memory/state.yaml"
    for scenario, expected in (("absent", 0), ("unchanged", 0), ("modified", 1)):
        if scenario == "unchanged":
            state.parent.mkdir(parents=True)
            state.write_text("epic_mode: false\n")
            subprocess.run(["git", "add", str(state)], cwd=project, check=True)
        elif scenario == "modified":
            state.write_text("epic_mode: true\n")
        result = subprocess.run([bash, "-c", "git diff --quiet" + state_diff],
                                cwd=project, capture_output=True, text=True, timeout=10)
        assert result.returncode == expected, (scenario, result.stderr)

    for name in ("gate-ci.sh", "gate-sec.sh"):
        # Load the actual definitions without starting external checks or writing state.
        source = (root / ".spec-flow/scripts/bash" / name).read_text(encoding="utf-8")
        definitions, entrypoint = source.rsplit('main "$@"', 1)
        assert not entrypoint.strip()
        target = scripts / name
        target.write_text(definitions, encoding="utf-8", newline="\n")
        for cwd, prelude in ((project, ""), (nested, ""),
                             (nested, "git() { return 1; }; ")):
            result = subprocess.run(
                [bash, "-c", prelude + 'source "$1"; [[ "$(detect_project_type)" == node ]]',
                 "gate-test", target.as_posix()],
                cwd=cwd, capture_output=True, text=True, encoding="utf-8", timeout=10,
            )
            assert result.returncode == 0, (
                f"{name} could not discover the project from {cwd.name} "
                f"(fallback={bool(prelude)}): {result.stderr}"
            )

        if name == "gate-sec.sh":
            fixture = project / "scan.json"
            cases = [("", 1), ("invalid JSON", 1), ("{}", 1), ('{"results":[]}', 0)]
            for severity in ("WARNING", "ERROR", "HIGH", "CRITICAL"):
                cases.append((json.dumps({"results": [{"extra": {"severity": severity}}]}),
                              0 if severity == "WARNING" else 1))
            for response, expected in cases:
                fixture.write_text(response)
                result = subprocess.run(
                    [bash, "-c", 'source "$1"; '
                     'SCAN_FIXTURE="$2"; '
                     'semgrep() { echo "scan progress" >&2; cat "$SCAN_FIXTURE"; }; '
                     'run_sast_semgrep', "gate-test", target.as_posix(), fixture.as_posix()],
                    cwd=project, capture_output=True, text=True, encoding="utf-8", timeout=10,
                )
                assert result.returncode == expected, (response, result.stdout, result.stderr)

    workflow = (root / ".github/workflows/flag-linter.yml").read_text(encoding="utf-8")
    expiry_check = textwrap.dedent(workflow.split("id: check_expired\n", 1)[1]
                                  .split("run: |\n", 1)[1].split("\n      - name:", 1)[0])
    probe = '''set -euo pipefail
date() { if [[ "$*" == '+%s' ]]; then echo 2000000000; else command date "$@"; fi; }
yq() {
  case "$2" in
    *length*) echo "$FLAG_COUNT" ;;
    *.status) echo "$FLAG_STATUS" ;;
    *.expires) echo "$FLAG_EXPIRES" ;;
  esac
}
''' + expiry_check
    output = project / "outputs"
    for count, status, expires, expected in (
        (0, "active", "@0", ("false", "false")),
        (1, "active", "@2000000001", ("false", "false")),
        (1, "active", "@1999913600", ("true", "false")),
        (1, "active", "@1999308800", ("true", "true")),
        (1, "retired", "@0", ("false", "false")),
    ):
        output.write_text("")
        result = subprocess.run([bash, "-c", probe], cwd=project, capture_output=True,
                                text=True, encoding="utf-8", timeout=10,
                                env={**os.environ, "FLAG_COUNT": str(count),
                                     "FLAG_STATUS": status, "FLAG_EXPIRES": expires,
                                     "GITHUB_OUTPUT": output.as_posix()})
        assert result.returncode == 0, result.stderr
        values = dict(line.split("=") for line in output.read_text().splitlines())
        assert (values["expired"], values["critical"]) == expected, values

    workflow = (root / ".github/workflows/publish-packages.yml").read_text(encoding="utf-8")
    resolve_ref = textwrap.dedent(workflow.split("- name: Resolve publish ref\n", 1)[1]
                                 .split("run: |\n", 1)[1].split("\n      - name:", 1)[0])
    for supplied, release, trigger, expected in (
        ("feature/example", "v1.0.0", "refs/heads/main", "feature/example"),
        ("", "v1.0.0", "refs/heads/main", "v1.0.0"),
        ("", "", "refs/heads/main", "refs/heads/main"),
        ("$(touch owned)", "", "refs/heads/main", None),
        ("main\nref=other", "", "refs/heads/main", None),
    ):
        output.write_text("")
        result = subprocess.run([bash, "-c", "set -euo pipefail\n" + resolve_ref],
                                cwd=project, capture_output=True, text=True,
                                encoding="utf-8", timeout=10,
                                env={**os.environ, "PUBLISH_REF": supplied,
                                     "RELEASE_TAG": release, "TRIGGER_REF": trigger,
                                     "GITHUB_OUTPUT": output.as_posix()})
        assert not (project / "owned").exists(), "Publish ref must never execute shell input"
        if expected is None:
            assert result.returncode != 0
            assert output.read_text() == ""
        else:
            assert result.returncode == 0, result.stderr
            assert output.read_text().strip() == "ref=" + expected

print("PASS: optional epic state, gate discovery, SAST parsing, flag expiry, and safe publish refs")
