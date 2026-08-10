#!/usr/bin/env python3
"""Status line for Claude Code: project path, git state, model, context usage."""

import json
import subprocess
import sys
from pathlib import Path


def parse_numstat(output):
    """Parse git diff --numstat output and return (added, removed) totals."""
    added = 0
    removed = 0
    for line in output.strip().split("\n"):
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) >= 2 and parts[0] != "-":  # Skip binary files
            try:
                added += int(parts[0])
                removed += int(parts[1])
            except ValueError:
                pass
    return added, removed


def get_git_info(cwd):
    """Get git branch and status information."""
    try:
        # Check if in git repo
        subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--git-dir"],
            capture_output=True,
            check=True,
            timeout=1,
        )
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return ""

    try:
        # Get current branch
        branch = subprocess.run(
            ["git", "-C", cwd, "--no-optional-locks", "branch", "--show-current"],
            capture_output=True,
            text=True,
            timeout=1,
        ).stdout.strip()

        if not branch:
            # Get short commit hash for detached HEAD
            result = subprocess.run(
                [
                    "git",
                    "-C",
                    cwd,
                    "--no-optional-locks",
                    "rev-parse",
                    "--short",
                    "HEAD",
                ],
                capture_output=True,
                text=True,
                timeout=1,
            )
            branch = result.stdout.strip() or "detached"

        # Count unstaged line changes
        result = subprocess.run(
            ["git", "-C", cwd, "--no-optional-locks", "diff", "--numstat"],
            capture_output=True,
            text=True,
            timeout=1,
        )
        unstaged_added, unstaged_removed = parse_numstat(result.stdout)

        # Count staged line changes
        result = subprocess.run(
            ["git", "-C", cwd, "--no-optional-locks", "diff", "--cached", "--numstat"],
            capture_output=True,
            text=True,
            timeout=1,
        )
        staged_added, staged_removed = parse_numstat(result.stdout)

        # Build git status with line counts and colors
        # Unstaged: ~ prefix, yellow +, red -
        # Staged: ✓ prefix, green +, red -
        git_status = ""
        if unstaged_added > 0 or unstaged_removed > 0:
            git_status += (
                f" ~\033[33m+{unstaged_added}\033[0m\033[31m-{unstaged_removed}\033[0m"
            )
        if staged_added > 0 or staged_removed > 0:
            git_status += (
                f" ✓\033[32m+{staged_added}\033[0m\033[31m-{staged_removed}\033[0m"
            )

        # Format git info with branch emoji
        # Red warning for main/master branches
        if branch in ("master", "main"):
            return f"🌿 \033[31m{branch}\033[0m{git_status}"
        else:
            # Cyan for other branches
            return f"🌿 \033[36m{branch}\033[0m{git_status}"

    except (subprocess.TimeoutExpired, Exception):
        return ""


def format_path(cwd, project_dir):
    """Format path relative to project if inside project."""
    cwd_path = Path(cwd)
    project_path = Path(project_dir)

    try:
        if cwd_path.is_relative_to(project_path):
            project_name = project_path.name
            display_path = cwd_path.relative_to(project_path)
            if str(display_path) == ".":
                return f"📁 {project_name}"
            return f"📁 {project_name}/{display_path}"
    except ValueError:
        pass

    return f"📁 {cwd}"


def format_model(model_name):
    """Format model indicator with emoji.

    The name is passed through as-is: collapsing it to the family name hides
    which Opus/Sonnet generation and which context variant is actually in use.
    """
    if not model_name:
        return ""

    return f"🤖 {model_name}"


def format_effort_suffix(effort_data, thinking_data):
    """Format the reasoning level as a suffix appended to the model name.

    Returned with a leading colon and no icon of its own: it belongs to the
    model segment, and a separate glyph only added noise.
    """
    if isinstance(thinking_data, dict) and thinking_data.get("enabled") is False:
        return ":off"

    if not isinstance(effort_data, dict):
        return ""

    level = effort_data.get("level")
    if not level:
        return ""

    return f":{level}"


def format_context(context_data):
    """Format context window with brain icon and progress bar."""
    if not context_data:
        return ""

    try:
        used_pct = context_data.get("used_percentage")
        if used_pct is None:
            return ""
        used_pct = max(0, min(100, int(used_pct)))
    except (ValueError, TypeError):
        return ""

    # Create progress bar (10 segments) - filled = used
    filled = int(used_pct / 10)
    empty = 10 - filled
    progress_bar = "█" * filled + "░" * empty

    # Color code based on usage percentage (higher = worse)
    if used_pct >= 80:
        return f" 🧠 \033[31m{used_pct}% {progress_bar}\033[0m"
    elif used_pct >= 50:
        return f" 🧠 \033[33m{used_pct}% {progress_bar}\033[0m"
    else:
        return f" 🧠 \033[32m{used_pct}% {progress_bar}\033[0m"


def main():
    """Build and output the status line."""

    debug = False
    try:
        raw_input = sys.stdin.read()
        if debug:
            import datetime

            with open("/tmp/statusline_debug.log", "a") as f:
                f.write(f"\n--- {datetime.datetime.now()} ---\n")
                f.write(f"Input: {raw_input}\n")

        input_data = json.loads(raw_input)

        # Extract key information
        cwd = input_data.get("workspace", {}).get("current_dir", "")
        project_dir = input_data.get("workspace", {}).get("project_dir", "")
        context_data = input_data.get("context_window", {})
        effort_data = input_data.get("effort", {})
        thinking_data = input_data.get("thinking", {})
        model_data = input_data.get("model")
        if isinstance(model_data, dict):
            model_name = model_data.get("display_name") or model_data.get("id", "")
        else:
            model_name = model_data

        if not cwd:
            return

        # Format components
        display_path = format_path(cwd, project_dir)
        git_info = get_git_info(cwd)
        model_info = format_model(model_name)
        if model_info:
            model_info += format_effort_suffix(effort_data, thinking_data)
        context_info = format_context(context_data)

        # Build and output status line
        status_line = f"{display_path} {git_info} {model_info} {context_info}".strip()

        if debug:
            with open("/tmp/statusline_debug.log", "a") as f:
                f.write(f"Output: {status_line}\n")

        print(status_line, end="")

    except (json.JSONDecodeError, KeyError, Exception) as e:
        # Stay silent unless explicitly debugging: an unconditional log here grows
        # a file in /tmp forever once anything starts failing.
        if debug:
            with open("/tmp/statusline_debug.log", "a") as f:
                f.write(f"Error: {type(e).__name__}: {e}\n")


if __name__ == "__main__":
    main()
