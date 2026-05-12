#!/usr/bin/env python3
"""
Cut a release-candidate branch.

Mechanical part of the release flow described in docs/dev-workflow.md
Stage 3: bump the package version in `dbt_project.yml` and the Quickstart
example in `README.md`, create a `release-candidate/X.Y.Z` branch, commit,
and push. The push triggers `.github/workflows/release.yml` (Tier 3).

The maintainer reviews the Tier 3 results and then drives the merge-back
and tag manually — this script intentionally does NOT auto-merge or auto-tag.

Usage (local):
    ./scripts/release/cut-candidate.py --patch
    ./scripts/release/cut-candidate.py --minor
    ./scripts/release/cut-candidate.py --major
    ./scripts/release/cut-candidate.py --version 2.11.0
    ./scripts/release/cut-candidate.py --minor --no-push   # dry-ish run

Usage (CI): invoked by `.github/workflows/cut-release-candidate.yml`.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
DBT_PROJECT = REPO_ROOT / "dbt_project.yml"
README = REPO_ROOT / "README.md"

# `version: "X.Y.Z"` in dbt_project.yml (line 2 today).
VERSION_RE_DBT = re.compile(r'^(version:\s*")([^"]+)(")', re.MULTILINE)

# `    version: X.Y.Z` inside the Quickstart packages.yml example block.
VERSION_RE_README = re.compile(r'^(\s*version:\s+)(\d+\.\d+\.\d+)\s*$', re.MULTILINE)

SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+$")


def die(msg: str) -> None:
    print(f"cut-candidate: error: {msg}", file=sys.stderr)
    sys.exit(1)


def run(cmd: list[str]) -> None:
    print(f"+ {' '.join(cmd)}", file=sys.stderr)
    subprocess.run(cmd, check=True)


def current_version() -> str:
    text = DBT_PROJECT.read_text()
    m = VERSION_RE_DBT.search(text)
    if not m:
        die(f"could not find `version:` line in {DBT_PROJECT}")
    return m.group(2)


def bump(version: str, kind: str) -> str:
    try:
        major, minor, patch = (int(x) for x in version.split("."))
    except ValueError:
        die(f"current version is not valid semver: {version!r}")
    if kind == "patch":
        return f"{major}.{minor}.{patch + 1}"
    if kind == "minor":
        return f"{major}.{minor + 1}.0"
    if kind == "major":
        return f"{major + 1}.0.0"
    die(f"unknown bump kind: {kind!r}")


def update_file(path: Path, pattern: re.Pattern[str], new_version: str) -> None:
    text = path.read_text()
    new_text, count = pattern.subn(
        lambda m: m.group(1) + new_version + (m.group(3) if m.lastindex == 3 else ""),
        text,
        count=1,
    )
    if count != 1:
        die(f"failed to update version in {path} (matched {count} times)")
    path.write_text(new_text)


def assert_clean_main() -> None:
    branch = subprocess.check_output(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"], text=True
    ).strip()
    if branch != "main":
        die(f"must be on `main`; currently on `{branch}`")

    status = subprocess.check_output(["git", "status", "--porcelain"], text=True).strip()
    if status:
        die(f"working tree not clean:\n{status}")


def assert_branch_does_not_exist(branch: str) -> None:
    # Local
    result = subprocess.run(
        ["git", "rev-parse", "--verify", "--quiet", branch],
        capture_output=True,
    )
    if result.returncode == 0:
        die(f"branch {branch!r} already exists locally")
    # Remote
    result = subprocess.run(
        ["git", "ls-remote", "--exit-code", "origin", f"refs/heads/{branch}"],
        capture_output=True,
    )
    if result.returncode == 0:
        die(f"branch {branch!r} already exists on origin")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--patch", action="store_const", const="patch", dest="bump_kind")
    group.add_argument("--minor", action="store_const", const="minor", dest="bump_kind")
    group.add_argument("--major", action="store_const", const="major", dest="bump_kind")
    group.add_argument(
        "--version",
        metavar="X.Y.Z",
        help="explicit version; skips bump computation",
    )
    parser.add_argument(
        "--no-push",
        action="store_true",
        help="create the branch and commit locally but do not push to origin",
    )
    args = parser.parse_args()

    assert_clean_main()

    current = current_version()
    new = args.version if args.version else bump(current, args.bump_kind)
    if not SEMVER_RE.match(new):
        die(f"target version is not valid semver: {new!r}")
    if new == current:
        die(f"target version {new} is the same as current; nothing to do")

    branch = f"release-candidate/{new}"
    assert_branch_does_not_exist(branch)

    print(f"bumping {current} -> {new}, branch={branch}", file=sys.stderr)

    run(["git", "checkout", "-b", branch])
    update_file(DBT_PROJECT, VERSION_RE_DBT, new)
    update_file(README, VERSION_RE_README, new)
    run(["git", "add", str(DBT_PROJECT.relative_to(REPO_ROOT)), str(README.relative_to(REPO_ROOT))])
    run(["git", "commit", "-m", f"release: bump to {new}"])

    if args.no_push:
        print(f"\nbranch {branch} created locally; not pushed (--no-push given)", file=sys.stderr)
        return

    run(["git", "push", "-u", "origin", branch])
    print(
        f"\npushed {branch}. Tier 3 (release.yml) will fire on the push.\n"
        f"Watch: https://github.com/brooklyn-data/dbt_artifacts/actions/workflows/release.yml",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
