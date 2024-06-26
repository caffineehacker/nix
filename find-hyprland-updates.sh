#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq

# This will get the latest release of hyprland
HYPRLAND_TAG=$(curl https://api.github.com/repos/hyprwm/Hyprland/releases/latest | jq -r .tag_name)
sed -i "s/^\(\s*\).*\( ### REPLACE_HYPRLAND_TAG$\)/\1ref = \"refs\/tags\/$HYPRLAND_TAG\";\2/g" flake.nix
sed -i "s/^\(\s*\).*\( ### REPLACE_HYPRLAND_PLUGINS_TAG$\)/\1ref = \"refs\/tags\/$HYPRLAND_TAG\";\2/g" flake.nix

TAG_SHA=$(curl https://api.github.com/repos/hyprwm/Hyprland/tags | jq -r ".[] | select(.name | contains(\"$HYPRLAND_TAG\")).commit.sha")

SPLIT_MONITOR_SHA=$(curl https://raw.githubusercontent.com/Duckonaut/split-monitor-workspaces/main/hyprpm.toml | grep $TAG_SHA | sed 's/#.*//g' | jq -r .[1])
if [ -z "$SPLIT_MONITOR_SHA" ]; then
    # We'll just take the most recent build and hope it works...
    SPLIT_MONITOR_SHA=$(curl "https://api.github.com/repos/Duckonaut/split-monitor-workspaces/commits?per_page=50" | jq -r ".[0].sha")
    echo "Could not find matching split-monitor-workspaces commit, using the most recent commit, $SPLIT_MONITOR_SHA, instead."
fi
sed -i "s/^\(\s*\).*\( ### REPLACE_SPLIT_MONITOR_REV$\)/\1rev = \"$SPLIT_MONITOR_SHA\";\2/g" flake.nix

