#!/bin/bash
set -euo pipefail
# Magento only needs search. The bundled plugins (security, ML, k-NN, alerting and the
# rest) take OpenSearch from about 0.4 GB to about 0.75 GB, past the Free plan's limit.
# Removed here, since Railway's flattening brings back what an image layer deleted.
rm -rf /usr/share/opensearch/plugins/*
# A subdirectory, since the volume's root holds lost+found.
data=/usr/share/opensearch/data/nodes-data
mkdir -p "$data"
chown -R 1000:1000 /usr/share/opensearch/data
exec setpriv --reuid=1000 --regid=1000 --clear-groups env HOME=/usr/share/opensearch \
  ./opensearch-docker-entrypoint.sh -Ediscovery.type=single-node -Enetwork.host=:: -Epath.data="$data" \
  -Enode.store.allow_mmap=false -Ebootstrap.memory_lock=false
