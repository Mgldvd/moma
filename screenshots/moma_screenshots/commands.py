"""Catalog of moma CLI invocations to screenshot.

Each entry's `script` is real shell source, run verbatim inside a pty after
`source dist/moma` - not a stand-in or a description of what the command
does. Interactive components use their non-interactive flags (`--choose`,
`--answer`) so a run is deterministic, the same way `src/preview/main.sh`
and `example.sh` already demonstrate them; `moma-update` is intentionally
excluded because it performs a real network install and has no such flag.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Command:
    id: str
    title: str
    script: str


COMMANDS: list[Command] = [
    Command(
        id="moma-header",
        title="moma header",
        script='moma header "Moma" --color cyan --margin-top 0 --margin-bottom 0',
    ),
    Command(
        id="moma-title",
        title="moma title",
        script='moma title "Moma" "Terminal UI library"',
    ),
    Command(
        id="moma-title-sub",
        title="moma title-sub",
        script='moma title-sub "Deployment" "Production environment"',
    ),
    Command(
        id="moma-section",
        title="moma section",
        script="""
moma section "Dependencies ready" --success
moma section "Configuration failed" --error
moma section "Review required" --warning
moma section "Next step" --info
""".strip(),
    ),
    Command(
        id="moma-msg",
        title="moma msg",
        script="""
moma msg "Package installed" --success
moma msg "Connection refused" --error
moma msg "Using cached version" --warning
moma msg "Downloading metadata" --info
moma msg "Custom presentation" --icon "◆" --color pink
""".strip(),
    ),
    Command(
        id="moma-msg-simple",
        title="moma msg-simple",
        script="""
moma msg-simple "Package installed"
moma msg-simple "Package installation failed" --error
""".strip(),
    ),
    Command(
        id="moma-list",
        title="moma list",
        script=(
            'moma list "Clone repository" "Install dependencies" '
            '"Start application"'
        ),
    ),
    Command(
        id="moma-box",
        title="moma box",
        script="""
moma box "Your configuration is ready." --success
moma box "Back up your files before continuing." --warning
""".strip(),
    ),
    Command(
        id="moma-block",
        title="moma block",
        script="""
moma block --title "Shells and Terminal Experience" --color blue \\
  --item "Bash" "GNU command shell and scripting environment." \\
  --item "Zsh" "Interactive shell with advanced completion."
moma block --title "Files, Search, and Data Processing" --color pink \\
  --item "ripgrep" "Fast recursive text-search utility." \\
  --item "jq" "Command-line JSON query and transformation processor."
""".strip(),
    ),
    Command(
        id="moma-prompt",
        title="moma prompt",
        script='moma prompt "Continue with the installation?" --color pink',
    ),
    Command(
        id="moma-label",
        title="moma label",
        script='moma label "TEXT HERE"',
    ),
    Command(
        id="moma-input",
        title="moma input",
        script="""
moma input --title "Project name" --placeholder "my-project"
moma input --title "Environment" --value "production" --info
moma input --title "Danger zone" --warning --color yellow
""".strip(),
    ),
    Command(
        id="moma-select",
        title="moma select",
        script=(
            'moma select "Development" "Staging" "Production" '
            '--title "Environment" --choose 2'
        ),
    ),
    Command(
        id="moma-single-select",
        title="moma single-select",
        script=(
            'moma single-select "info" "debug" "warn" '
            '--title "Log level" --choose 1'
        ),
    ),
    Command(
        id="moma-single-select-groups",
        title="moma single-select-groups",
        script="""
moma single-select-groups \\
  --title "Deployment command" \\
  --group "Docker" --option "Up" --option "Down" --option "Stop" \\
  --group "npm" --option "install" --option "run dev" --option "run deploy" \\
  --choose 1
""".strip(),
    ),
    Command(
        id="moma-multi-select",
        title="moma multi-select",
        script=(
            'moma multi-select "Docker" "CI" "Tests" '
            '--title "Features" --choose 1,3'
        ),
    ),
    Command(
        id="moma-multi-select-groups",
        title="moma multi-select-groups",
        script="""
moma multi-select-groups \\
  --title "Deployment regions" \\
  --group "North America" --option "United States" --option "Canada" \\
  --option "Mexico" \\
  --group "South America" --option "Colombia" --option "Argentina" \\
  --option "Peru" \\
  --choose 1,4
""".strip(),
    ),
    Command(
        id="moma-rabbit",
        title="moma rabbit",
        script="""
moma rabbit "Preparing workspace" --info
printf '\\n'
moma rabbit "Task completed" --success
""".strip(),
    ),
    Command(
        id="moma-confirm",
        title="moma confirm",
        script='moma confirm "Continue with deployment?" --default yes --answer yes',
    ),
    Command(
        id="moma-spinner",
        title="moma spinner",
        script="""
sleep 0.2 &
pid=$!
moma spinner "$pid" "Preparing workspace" --delay 0.03
""".strip(),
    ),
    Command(
        id="moma-command-check",
        title="moma command-check",
        script="moma command-check bash curl",
    ),
    Command(
        id="moma-version",
        title="moma version",
        script="moma version",
    ),
]

COMMANDS_BY_ID = {command.id: command for command in COMMANDS}
