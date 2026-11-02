FROM opensearchproject/opensearch:2.19.7
# The image has no way to drop root, and Railway mounts the volume as root.
USER root
RUN dnf install -y util-linux
# Native memory, not the heap, is what pushed this past 0.5 GB. On a heap this small, the
# serial collector and the C1 compiler alone save about 50 MB (measured: 480 MB to 434 MB).
RUN sed -i -E '/^[0-9-]*:?-XX:(\+UseG1GC|G1|InitiatingHeapOccupancyPercent|\+AlwaysPreTouch)/d' config/jvm.options \
 && printf '%s\n' -XX:+UseSerialGC -XX:TieredStopAtLevel=1 -XX:ReservedCodeCacheSize=48m >> config/jvm.options
COPY --chmod=0755 railway-entrypoint.sh /railway-entrypoint.sh
ENTRYPOINT ["/railway-entrypoint.sh"]
CMD []
