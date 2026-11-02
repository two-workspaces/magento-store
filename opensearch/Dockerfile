FROM opensearchproject/opensearch:2.19.7
# The image has no way to drop root, and Railway mounts the volume as root.
USER root
RUN dnf install -y util-linux
# Magento only needs search. The bundled plugins (security, ML, k-NN, alerting and the
# rest) take OpenSearch from about 0.4 GB to about 0.75 GB, past the Free plan's limit.
RUN for p in $(bin/opensearch-plugin list); do bin/opensearch-plugin remove "$p"; done
COPY --chmod=0755 railway-entrypoint.sh /railway-entrypoint.sh
ENTRYPOINT ["/railway-entrypoint.sh"]
CMD []
