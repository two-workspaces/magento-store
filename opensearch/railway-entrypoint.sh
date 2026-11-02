#!/bin/bash
set -euo pipefail
# A subdirectory, since the volume's root holds lost+found.
data=/usr/share/opensearch/data/nodes-data
mkdir -p "$data"
chown -R 1000:1000 /usr/share/opensearch/data
exec setpriv --reuid=1000 --regid=1000 --clear-groups env HOME=/usr/share/opensearch \
  ./opensearch-docker-entrypoint.sh -Ediscovery.type=single-node -Enetwork.host=:: -Epath.data="$data" \
  -Enode.store.allow_mmap=false -Ebootstrap.memory_lock=false
