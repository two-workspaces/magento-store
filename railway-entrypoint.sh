#!/bin/bash
# Railway entrypoint for Magento: the store is installed before the port opens, with a
# generated admin password and a private admin path.
set -euo pipefail

# Railway flattens the image layers, which brings back the mpm_event links the PHP
# image deleted, and Apache then refuses to start. mod_php needs prefork only.
rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.*

# Prefork runs one process per request. Budget 128 MB a worker after 256 MB for Apache
# and OPcache, sized from the plan's memory limit.
mem=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo max)
[ "$mem" = max ] && mem=$((8 << 30))
workers=$(( (mem / 1048576 - 256) / 128 ))
workers=$(( workers < 2 ? 2 : workers > 32 ? 32 : workers ))
printf '<IfModule mpm_prefork_module>\n\tMaxRequestWorkers %s\n</IfModule>\n' "$workers" \
  > /etc/apache2/conf-enabled/zz-workers.conf

cd /var/www/magento
magento() { setpriv --reuid=www-data --regid=www-data --init-groups env HOME=/tmp php -d memory_limit=-1 bin/magento "$@"; }

# Uploaded images and env.php (which holds the encryption key) live on the volume.
mkdir -p /data/media /data/etc
cp -an pub/media/. /data/media/
rm -rf pub/media
ln -s /data/media pub/media
ln -sfn /data/etc/env.php app/etc/env.php
chown -R www-data:www-data /data

db() { MYSQL_PWD="$DB_PASSWORD" mariadb --skip-ssl -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" "$@"; }
for i in $(seq 90); do
  db -e 'select 1' >/dev/null 2>&1 && break
  [ "$i" = 90 ] && { echo "railway: database not reachable after 3 minutes"; exit 1; }
  sleep 2
done
for i in $(seq 90); do
  curl -fsS "http://$OPENSEARCH_HOST:9200" >/dev/null 2>&1 && break
  [ "$i" = 90 ] && { echo "railway: OpenSearch not reachable after 3 minutes"; exit 1; }
  sleep 2
done

base_url="${MAGENTO_BASE_URL%/}/"
if [ ! -e /data/.installed ]; then
  echo "railway: first boot, installing Magento"
  rm -f /data/etc/env.php
  # The installer empties generated/code, which was compiled into the image.
  cp -a generated/code /tmp/generated-code
  magento setup:install --cleanup-database \
    --base-url="$base_url" --base-url-secure="$base_url" --use-secure=1 --use-secure-admin=1 --use-rewrites=1 \
    --backend-frontname="$MAGENTO_ADMIN_PATH" \
    --db-host="$DB_HOST" --db-name="$DB_NAME" --db-user="$DB_USER" --db-password="$DB_PASSWORD" \
    --search-engine=opensearch --opensearch-host="$OPENSEARCH_HOST" --opensearch-port=9200 \
    --session-save=db --document-root-is-pub=1 \
    --admin-user=admin --admin-password="$MAGENTO_ADMIN_PASSWORD" --admin-email="$MAGENTO_ADMIN_EMAIL" \
    --admin-firstname=Store --admin-lastname=Admin \
    --language=en_US --currency=USD --timezone=UTC
  rm -rf generated/code
  mv /tmp/generated-code generated/code
  magento deploy:mode:set production --skip-compilation
  magento indexer:set-mode schedule
  touch /data/.installed
elif ! magento setup:db:status >/dev/null; then
  # A new image with a newer Magento version.
  magento setup:upgrade --keep-generated
fi

# So a custom domain only needs the variable changed.
db -e "update core_config_data set value='$base_url' where path in ('web/unsecure/base_url','web/secure/base_url')"

# Each cron group is normally its own process of about 180 MB, started together every
# minute. Under 2 GB that gets them killed mid-job, leaving indexers stuck, so run them in
# turn there. Stored on every boot so that moving to a bigger plan undoes it.
sep=1; [ "$mem" -lt $((2 << 30)) ] && sep=0
for g in default index consumers analytics; do
  db -e "insert into core_config_data (scope,scope_id,path,value) values ('default',0,'system/cron/$g/use_separate_process','$sep') on duplicate key update value='$sep'"
done
magento cache:clean config >/dev/null

# Indexers, email and scheduled tasks all run from Magento's cron.
( while sleep 60; do magento cron:run >/dev/null 2>&1 || true; done ) &

exec apache2-foreground
