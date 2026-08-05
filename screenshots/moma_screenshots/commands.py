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
    # Optional one-example-per-frame variant of `script`, each run and
    # captured as its own separate screenshot (rather than one combined
    # capture) for the docs site's output carousel. `script` above still
    # renders unconditionally and is what feeds the single, combined image
    # README.md and docs/moma-docs.md embed - frames are purely additive.
    frames: tuple[str, ...] = ()


COMMANDS: list[Command] = [
    Command(
        id="moma-header",
        title="moma header",
        # Mirrors apiEntries.ts's `examples` for moma-header exactly - see
        # the module docstring above.
        script="""
moma header "Moma"
moma header "Deploy 2026" --color cyan --margin-bottom 1
moma header "Build ready" --margin-top 0 --margin-bottom 0 --margin-left 2 --no-color
""".strip(),
    ),
    Command(
        id="moma-title",
        title="moma title",
        script="""
moma title "Moma" "Terminal UI library"
moma title "Deploy" "Production" --primary cyan
moma title "Backup" "Nightly job" --accent yellow --min-width 48
""".strip(),
    ),
    Command(
        id="moma-title-sub",
        title="moma title-sub",
        script="""
moma title-sub "Dependencies" "Installing packages"
moma title-sub "Deploy" "Production" --color cyan
moma title-sub "Tests" --message "Running suite" --min-width 42
""".strip(),
    ),
    Command(
        id="moma-sub-title",
        title="moma sub-title",
        script="""
moma sub-title "Moma" "Terminal UI library"
moma sub-title "Moma" "Terminal UI library" --no-icon --border open
moma sub-title "Moma" "Terminal UI library" --border line
""".strip(),
    ),
    Command(
        id="moma-section",
        title="moma section",
        script="""
moma section "Dependencies ready" --success
moma section "Configuration failed" --error
moma section "Next step" --info --icon "→"
""".strip(),
    ),
    Command(
        id="moma-msg",
        title="moma msg",
        script="""
moma msg "Package installed" --success
moma msg "Connection refused" --error
moma msg "Downloading metadata" --color cyan --icon "→"
""".strip(),
    ),
    Command(
        id="moma-msg-simple",
        title="moma msg-simple",
        script="""
moma msg-simple "Package installed"
moma msg-simple "Package installation failed" --error
""".strip(),
        # Mirrors apiEntries.ts's `examples` for moma-msg-simple exactly -
        # one frame per documented example, in the same order.
        frames=(
            'moma msg-simple "Package installed"',
            'moma msg-simple "Package installation failed" --error',
            'moma msg-simple "Queued" --color yellow --marker "•"',
        ),
    ),
    Command(
        id="moma-list",
        title="moma list",
        script="""
moma list "Clone repository" "Install dependencies" "Start application"
moma list "Database ready" "Cache ready" --success
moma list "Review logs" "Retry deployment" --marker "→" --color yellow
""".strip(),
    ),
    Command(
        id="moma-box",
        title="moma box",
        script="""
moma box "Configuration is ready." --success
moma box "Review the deployment settings." --warning --width 48
moma box "A long notice wraps inside its border." --info --max-width 32
""".strip(),
    ),
    Command(
        id="moma-resume",
        title="moma resume",
        script="""
moma resume --title "Shells" --color blue \\
  --item "Bash" "GNU command shell." \\
  --item "Zsh" "Interactive shell with completion."
moma resume --title "Summary" \\
  --text "All checks passed." \\
  --text "No manual follow-up required."
moma resume --title "Review" --warning \\
  --item "Environment" "production" \\
  --text "Confirm the target before deploying."
""".strip(),
    ),
    Command(
        id="moma-divider",
        title="moma divider",
        script="""
moma divider
moma divider --success --border line
moma divider --icon "★" --border line
""".strip(),
    ),
    Command(
        id="moma-label",
        title="moma label",
        script="""
moma label "PROJECT NAME"
moma label "DEPLOYMENT" --success
moma label "NOTES" --width 52 --color cyan --icon "→"
""".strip(),
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
        id="moma-prompt",
        title="moma prompt",
        script="""
moma prompt "Continue with the installation?" <<< "Yes, continue"
moma prompt "Deploy now?" --default "yes" <<< ""
moma prompt "API token" --secret --required <<< "s3cr3t-token"
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
moma rabbit "Deployment complete" --success
moma rabbit "Build needs attention" --warning --icon "!"
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
        # Mirrors apiEntries.ts's first two examples for moma-command-check
        # verbatim; the third (`if ! moma command-check git; then exit 1;
        # fi`) illustrates script-exit-code usage rather than a visually
        # distinct frame, and a real `exit 1` here would truncate this
        # capture if git were ever missing from the capturing environment.
        script="""
moma command-check bash curl git
moma command-check docker --quiet
""".strip(),
    ),
    Command(
        id="moma-version",
        title="moma version",
        script="moma version",
    ),
]

COMMANDS_BY_ID = {command.id: command for command in COMMANDS}
