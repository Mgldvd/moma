#!/bin/bash
#
# Demonstrate Moma's public terminal UI components in one workflow.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOMA="$SCRIPT_DIR/dist/moma"

if [[ ! -f "$MOMA" ]]; then
  printf 'Moma is not built. Run: %s/build.sh\n' "$SCRIPT_DIR" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$MOMA"

# Sourcing dist/moma defines the canonical `moma` command used below and
# also defines every direct moma-* function (for example moma-title) for
# scripts written against the legacy interface.
#
# moma version reports the installed version; moma update refreshes an
# executable installation.

# Keep every horizontal decoration aligned. Set MOMA_MAX_WIDTH instead when
# decorations should grow with their content up to a common limit.
MOMA_WIDTH="${MOMA_WIDTH:-48}"

moma header "Project setup" --color cyan
moma title "Project setup" "Interactive form example"
moma title-sub "Component showcase" "All public Moma components"
moma box "Complete the form to create a project configuration." --info

moma section "Preflight" --success
moma command-check bash
moma msg-simple "All required commands are available." --success

moma section "Project information" --info
moma label "Basic details" --color cyan

project_name="$(
  moma input \
    --title "Project name" \
    --placeholder "my-project" \
    --read \
    --required \
    --trim
)"

ticket="$(moma prompt "Deployment ticket reference" --color pink --trim)"

select_args=(
  "Development"
  "Staging"
  "Production"
  --title "Environment"
)
if [[ ! -t 0 || ! -t 2 ]]; then
  select_args+=(--choose 1)
fi
environment="$(moma select "${select_args[@]}")"

single_group_args=(
  --title "Deployment command"
  --group "Docker" --option "Up" --option "Down" --option "Stop"
  --group "npm" --option "install" --option "run dev" --option "run deploy"
)
if [[ ! -t 0 || ! -t 2 ]]; then
  single_group_args+=(--choose 1)
fi
deploy_command="$(moma single-select-groups "${single_group_args[@]}")"

multi_select_args=(
  "Docker"
  "CI"
  "Tests"
  --title "Features"
  --selected 1
  --required
)
if [[ ! -t 0 || ! -t 2 ]]; then
  multi_select_args+=(--choose "1,3")
fi
selected_features="$(moma multi-select "${multi_select_args[@]}")"
mapfile -t features <<<"$selected_features"
features_summary=""
for feature in "${features[@]}"; do
  [[ -z "$features_summary" ]] || features_summary+=", "
  features_summary+="$feature"
done

multi_group_args=(
  --title "Deployment regions"
  --group "North America" --option "United States" --option "Canada"
  --option "Mexico"
  --group "South America" --option "Colombia" --option "Argentina"
  --option "Peru"
  --required
)
if [[ ! -t 0 || ! -t 2 ]]; then
  multi_group_args+=(--choose "1,4")
fi
selected_regions="$(moma multi-select-groups "${multi_group_args[@]}")"
mapfile -t regions <<<"$selected_regions"
regions_summary=""
for region in "${regions[@]}"; do
  [[ -z "$regions_summary" ]] || regions_summary+=", "
  regions_summary+="$region"
done

log_level_args=("info" "debug" "warn" --title "Log level")
if [[ ! -t 0 || ! -t 2 ]]; then
  log_level_args+=(--choose 1)
fi
log_level="$(moma single-select "${log_level_args[@]}")"

moma label "Ownership and credentials" --color yellow
owner="$(
  moma input \
    --title "Owner" \
    --placeholder "team@example.com" \
    --read \
    --required \
    --trim
)"

secret="$(
  moma input \
    --title "Secret" \
    --read \
    --secret \
    --required
)"

printf -v secret_mask '%*s' "${#secret}" ''
secret_mask="${secret_mask// /•}"

moma section "Review" --warning
moma resume \
  --title "Project configuration" \
  --color yellow \
  --item "Project" "$project_name" \
  --item "Ticket" "$ticket" \
  --item "Environment" "$environment" \
  --item "Command" "$deploy_command" \
  --item "Features" "$features_summary" \
  --item "Regions" "$regions_summary" \
  --item "Log level" "$log_level" \
  --item "Owner" "$owner" \
  --item "Secret" "$secret_mask"

if moma confirm "Create this project?" --default yes; then
  sleep 0.15 &
  create_pid=$!
  moma spinner "$create_pid" "Creating project" --delay 0.03
  moma msg "Project configuration accepted" --success
  moma list "Push the initial commit" "Invite the team" "Watch the first deploy"
  moma rabbit "Ready to continue" --success
else
  moma msg "Project setup cancelled" --warning
  exit 1
fi
