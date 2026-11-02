FROM opensearchproject/opensearch:2.19.7
# The image has no way to drop root, and Railway mounts the volume as root.
USER root
RUN dnf install -y util-linux
COPY --chmod=0755 railway-entrypoint.sh /railway-entrypoint.sh
ENTRYPOINT ["/railway-entrypoint.sh"]
CMD []
