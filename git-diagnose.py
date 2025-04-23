#!/usr/bin/env python3

import subprocess
import sys
import os

def run(cmd, verbose=True, quiet_fail=False):
    try:
        result = subprocess.check_output(
            cmd, stderr=subprocess.STDOUT, shell=True, universal_newlines=True
        )
        if verbose:
            print(f"$ {cmd}\n{result}")
        return result.strip()
    except subprocess.CalledProcessError as e:
        if not quiet_fail:
            print(f"[!] Error running: {cmd}\n{e.output}")
        return ""

def header(title):
    print(f"\n{'='*10} {title} {'='*10}")

def main():
    if not os.path.isdir(".git"):
        print("❌ Not a Git repository.")
        sys.exit(1)

    header("Repository Info")
    run("git rev-parse --show-toplevel")
    run("git status -sb")

    header("Current Branch & Tracking")
    run("git branch --show-current")
    run("git rev-parse --abbrev-ref --symbolic-full-name @{u}", quiet_fail=True)

    header("Remote Info")
    run("git remote -v")
    run("git remote show origin", quiet_fail=True)

    header("Stash Check")
    run("git stash list")

    header("Submodules")
    run("git submodule status")

    header("Detached HEAD Check")
    head_status = run("git symbolic-ref -q HEAD", verbose=False)
    if not head_status:
        print("⚠️ Detached HEAD state!")

    header("Uncommitted Changes")
    run("git diff")

    header("Staged Changes")
    run("git diff --cached")

    header("Untracked Files")
    run("git ls-files --others --exclude-standard")

    header("Large Untracked Files (Over 5MB)")
    run("find . -type f -size +5M -not -path './.git/*'", quiet_fail=True)

    header("Merge Conflicts (if any)")
    run("git diff --name-only --diff-filter=U")

    header("Recent Commits (Graph View)")
    run("git log --oneline --graph --decorate -n 10")

    header("Commit Differences (Local vs Remote)")
    branch = run("git rev-parse --abbrev-ref HEAD", verbose=False)
    run(f"git log origin/{branch}..HEAD --oneline", quiet_fail=True)
    run(f"git log HEAD..origin/{branch} --oneline", quiet_fail=True)

    header("Git Config")
    run("git config --list")

    header("Hooks Present")
    run("ls .git/hooks | grep -v 'sample' || echo 'No custom hooks found.'", quiet_fail=True)

    print("\n✅ Diagnostics complete. No changes were made to your repository.\n")

if __name__ == "__main__":
    main()