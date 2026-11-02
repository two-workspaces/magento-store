# Compiled here, not on Railway: DI compilation and static assets take many minutes and
# gigabytes. A deploy pulls the finished image, and first boot only installs the database.
FROM php:8.4.27-apache

# upgrade: github magento/magento2
ARG MAGENTO_VERSION=2.4.9

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/download/2.9.22/install-php-extensions /usr/local/bin/
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends git unzip mariadb-client-core; \
	install-php-extensions bcmath ftp gd intl opcache pdo_mysql soap sockets xsl zip @composer; \
	rm -rf /var/lib/apt/lists/*

RUN printf '%s\n' \
	'memory_limit = 756M' 'upload_max_filesize = 64M' 'post_max_size = 64M' 'max_execution_time = 300' \
	'expose_php = Off' 'realpath_cache_size = 10M' 'realpath_cache_ttl = 7200' \
	'opcache.memory_consumption = 192' 'opcache.interned_strings_buffer = 20' \
	'opcache.max_accelerated_files = 60000' 'opcache.validate_timestamps = 0' \
	> /usr/local/etc/php/conf.d/railway.ini

WORKDIR /var/www/magento
COPY build-config.php /tmp/build-config.php
RUN set -eux; \
	git clone --depth 1 --branch "$MAGENTO_VERSION" https://github.com/magento/magento2.git .; \
	rm -rf .git dev/tests; \
	COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --no-interaction --no-progress --optimize-autoloader; \
	php -d memory_limit=-1 bin/magento module:enable --all; \
	php /tmp/build-config.php add; \
	php -d memory_limit=-1 bin/magento setup:di:compile; \
	php -d memory_limit=-1 bin/magento setup:static-content:deploy -f en_US --jobs 4 \
		--theme Magento/backend --theme Magento/blank --theme Magento/luma; \
	php /tmp/build-config.php strip; \
	rm -rf var/cache var/page_cache var/view_preprocessed var/log /root/.composer /tmp/build-config.php; \
	mkdir -p var; \
	chown -R www-data:www-data app/etc generated pub/media pub/static var

# Apache on Railway's $PORT with pub/ as the site root. Errors go to stdout: Railway
# paints all of stderr red, including Apache's startup notices.
ENV PORT=8080
RUN set -eux; \
	a2enmod rewrite headers expires deflate remoteip; \
	printf 'Listen [::]:${PORT}\nListen 0.0.0.0:${PORT}\n' > /etc/apache2/ports.conf; \
	ln -sfT /dev/stdout /var/log/apache2/error.log; \
	sed -i 's/^ServerTokens OS/ServerTokens Prod/; s/^ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf
COPY railway.conf /etc/apache2/sites-available/000-default.conf
COPY railway-health.php /var/www/magento/pub/railway-health.php

COPY --chmod=0755 railway-entrypoint.sh /railway-entrypoint.sh
ENTRYPOINT ["/railway-entrypoint.sh"]
# The PHP image stops Apache with SIGWINCH; Railway sends SIGTERM.
STOPSIGNAL SIGTERM
