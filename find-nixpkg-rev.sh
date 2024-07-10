#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq

JOBSETEVAL=$(curl -L -H 'Accept: application/json' https://hydra.nixos.org/job/nixpkgs/trunk/unstable/latest-finished | jq .jobsetevals[0])
REVISION=$(curl -L -H 'Accept: application/json' https://hydra.nixos.org/eval/$JOBSETEVAL | jq .jobsetevalinputs.nixpkgs.revision)
echo $REVISION