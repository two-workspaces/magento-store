<?php
// Railway's health check. Magento's own pub/health_check.php can't pass on a default
// install: 2.4.9's installer writes cache config with backend_options and no backend,
// and that script answers 500 "Cache configuration is invalid" for it, while the store
// itself works. Apache only starts once the install has finished, so this checks the
// one thing left: the database Magento is configured to use answers.
try {
    $db = (require __DIR__ . '/../app/etc/env.php')['db']['connection']['default'];
    new PDO("mysql:host={$db['host']};dbname={$db['dbname']}", $db['username'], $db['password'], [
        PDO::ATTR_TIMEOUT => 5,
    ]);
} catch (Throwable $e) {
    http_response_code(503);
}
