#!/usr/bin/env bash
# Adopt the FEFO machinery in BLT. Plan and rules: docs/fefo/ADOPTION.md.
#
#   fefo-adopt.sh            rehearse on a throwaway copy of this repository (changes nothing here)
#   fefo-adopt.sh --apply    do it here; needs a clean BLT and a clean blt-project
#
# The same steps run in both modes, so a passing rehearsal is the real thing minus the writes.
set -euo pipefail

BLT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FEFO_SRC="${FEFO_SRC:-${HOME}/FEFO}"
FEFO_REV="63c94f7acc93e5b90059cc643bcfb113673e476c" # revision the manifest and the notes were validated on

die() { echo "fefo-adopt: $*" >&2; exit 1; }

mode=rehearse
[[ "${1:-}" == "--apply" ]] && mode=apply

[[ -x "${FEFO_SRC}/bin/fefo" && -f "${FEFO_SRC}/tools/fefo.py" ]] || die "no FEFO checkout at ${FEFO_SRC} (set FEFO_SRC)"
rev="$(git -C "${FEFO_SRC}" rev-parse HEAD)"
if [[ "${rev}" != "${FEFO_REV}" ]]; then
    msg="FEFO is at ${rev}, validated on ${FEFO_REV}. Re-run the rehearsal, then set FEFO_REV here."
    [[ "${mode}" == apply && -z "${FEFO_ALLOW_OTHER_REV:-}" ]] && die "${msg}"
    echo "warning: ${msg}" >&2
fi
[[ -z "$(git -C "${FEFO_SRC}" status --porcelain)" ]] || die "FEFO checkout has local changes"

if [[ "${mode}" == apply ]]; then
    T="${BLT}"
    [[ -z "$(git -C "${BLT}" status --porcelain)" ]] || die "BLT has uncommitted changes; commit the preparation first (with the user's authorization)"
    [[ -z "$(git -C "${BLT}/blt-project" status --porcelain)" ]] || die "blt-project is not clean"
    [[ -f "${T}/bin/fefo" ]] && die "FEFO is already adopted here (bin/fefo exists)"
else
    T="$(mktemp -d /tmp/blt-fefo-rehearsal.XXXXXX)"
    trap '[[ -n "${KEEP:-}" ]] || rm -rf "${T}"' EXIT
    # Tracked and untracked files that are not git-ignored: no .env, no secrets/, no blt-project/.
    git -C "${BLT}" ls-files -co --exclude-standard -z | tar -C "${BLT}" --null -T - --ignore-failed-read -cf - | tar -C "${T}" -xf -
    ln -s "${BLT}/blt-project" "${T}/blt-project"
fi
echo "target: ${T} (${mode})"

# 1. Machinery, by explicit list. Never FEFO's README.md, docs/, AGENTS.md, LICENSE or tests/.
install -d "${T}/bin" "${T}/tools" "${T}/.opencode/agents" "${T}/.opencode/commands" "${T}/.agents/skills"
cp -p "${FEFO_SRC}/bin/fefo" "${T}/bin/fefo"
cp -p "${FEFO_SRC}/tools/fefo.py" "${T}/tools/fefo.py"
copy_missing() { # never overwrite what BLT already has
    local src="$1" dst="$2" f
    while IFS= read -r -d '' f; do
        local rel="${f#"${src}"/}"
        [[ -e "${dst}/${rel}" ]] && { echo "kept BLT's ${dst#"${T}"/}/${rel}"; continue; }
        install -d "$(dirname "${dst}/${rel}")"
        cp -p "${f}" "${dst}/${rel}"
    done < <(find "${src}" -type f -print0)
}
copy_missing "${FEFO_SRC}/.opencode/agents" "${T}/.opencode/agents"
copy_missing "${FEFO_SRC}/.opencode/commands" "${T}/.opencode/commands"
copy_missing "${FEFO_SRC}/.agents/skills" "${T}/.agents/skills"

# 2. The BLT rules move into the file FEFO never overwrites; sync regenerates AGENTS.md.
python3 - "${T}" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
rules, local = root / "AGENTS.md", root / "AGENTS.local.md"
marker = "<!-- blt-rules-moved -->"
text = local.read_text()
if marker not in text:
    body = rules.read_text().split("\n", 1)[1]  # drop the "# BLT — agent rules" title
    body = "\n".join(("#" + line if line.startswith("## ") else line) for line in body.split("\n"))
    local.write_text(text.rstrip() + f"\n\n{marker}\n## BLT rules (moved from AGENTS.md)\n{body.rstrip()}\n")
PY

# 3. Sync from the hand-written manifest (never `init`).
BEFORE="$(mktemp /tmp/fefo-before.XXXXXX)"
python3 - "${T}" <<'PY' > "${BEFORE}"
import json, sys
from pathlib import Path

root = Path(sys.argv[1])
out = {"opencode": sorted(json.loads((root / "opencode.json").read_text())["mcp"]["servers"]),
       "claude": sorted(json.loads((root / ".mcp.json").read_text())["mcpServers"]),
       "repos": {p.name: p.read_text() for p in (root / "docs/vault/repos").glob("*.md")},
       "vault": {n: (root / "docs/vault" / n).read_text() for n in ("README.md", "decisions.md")},
       "local": (root / "AGENTS.local.md").read_text()}
print(json.dumps(out))
PY
(cd "${T}" && ./bin/fefo sync)

# 4. Checks. Any failure stops here.
python3 - "${T}" "${BEFORE}" "${mode}" <<'PY'
import json, subprocess, sys
from pathlib import Path

root = Path(sys.argv[1])
before = json.loads(Path(sys.argv[2]).read_text())
mode = sys.argv[3]
fails = []

def check(ok, msg):
    print(("OK    " if ok else "FAIL  ") + msg)
    if not ok:
        fails.append(msg)

after_oc = sorted(json.loads((root / "opencode.json").read_text())["mcp"]["servers"])
after_cl = sorted(json.loads((root / ".mcp.json").read_text())["mcpServers"])
want = ["blt-specs", "codegraph-api", "codegraph-web", "minio-blt", "postgres-blt"]
check(after_oc == want, f"opencode.json MCP names are the five BLT names: {after_oc}")
check(after_cl == want, f".mcp.json MCP names are the five BLT names: {after_cl}")
check(before["opencode"] == want, "the MCP names before the sync were already those five")

check((root / "AGENTS.local.md").read_text() == before["local"], "sync left AGENTS.local.md untouched")
check("Committing without authorization" in before["local"], "AGENTS.local.md holds the BLT rules")
check(all((root / "docs/vault/repos" / n).read_text() == t for n, t in before["repos"].items()),
      "sync left docs/vault/repos/*.md byte-identical (generated block already matches)")
check(all((root / "docs/vault" / n).read_text() == t for n, t in before["vault"].items()),
      "sync left docs/vault/README.md and decisions.md untouched")
check("Generated by FEFO" in (root / "AGENTS.md").read_text(), "AGENTS.md is the generated routing contract")
for agent in ("blt-domain", "blt-genai", "fefo", "backend", "frontend"):
    check((root / ".claude/agents" / f"{agent}.md").is_file(), f".claude/agents/{agent}.md generated")
if mode == "rehearse":
    check(not (root / ".env").exists() and not (root / "secrets").exists(),
          "the rehearsal copy holds no .env and no secrets/")

doctor = subprocess.run(["./bin/fefo", "doctor"], cwd=root, text=True, capture_output=True)
print(doctor.stdout.rstrip())
errors = [l for l in doctor.stdout.splitlines() if l.startswith("ERROR")]
warns = [l for l in doctor.stdout.splitlines() if l.startswith("WARN")]
check(doctor.returncode == 0 and not errors, "fefo doctor reports no error")
expected = {"WARN  not a Git repository: api", "WARN  not a Git repository: web"}
unexpected = [w for w in warns if w not in expected and "CodeGraph index missing" not in w]
check(not unexpected, f"only the expected doctor warnings remain: {unexpected or 'none'}")
sys.exit(1 if fails else 0)
PY
rm -f "${BEFORE}"

if [[ "${mode}" == apply ]]; then
    echo "Applied. Next: ./bin/fefo index, restart OpenCode, then the checklist in docs/fefo/ADOPTION.md."
else
    echo "Rehearsal passed. Nothing was changed in ${BLT}."
fi
