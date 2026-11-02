# Deploy and Host Magento on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/magento-store?referralCode=sLjDXb&utm_medium=integration&utm_source=button&utm_campaign=magento-store)

[Magento Open Source](https://github.com/magento/magento2) is the e-commerce platform for stores that have outgrown simpler carts: multiple storefronts, complex catalogs, and full control of the code. This template runs Magento 2.4.9 with the slow parts already done, so a deploy takes minutes rather than an afternoon.

## About Hosting Magento

Three services: **Magento** (Apache and PHP 8.4), **MariaDB**, and **OpenSearch**, which Magento requires for its catalog search.

- **Compiled in advance.** Magento's code generation and static assets take many minutes and several GB of memory. They are built into the image, so your deploy only has to install the database.
- **No open installer.** The store is installed before the public port opens, with a generated admin password and a private admin path.
- **Cron included.** Indexers, order emails and scheduled tasks need Magento's cron, which is the step many hand-built installs miss. It runs inside the Magento service.
- **Your images survive redeploys.** Uploaded media and the encryption key are on a volume.
- **Upgrades run themselves.** When a new image has a newer Magento, the database upgrade runs on boot.

## Common Use Cases

- An online store with a large or complex catalog
- Several storefronts, languages or currencies from one admin
- A staging copy of a store, or a sandbox for developing Magento extensions

## Dependencies for Magento Hosting

- Nothing external to start. For real orders, you'll want an SMTP provider for email and a payment provider account.

### Deployment Dependencies

- [Magento Open Source on GitHub](https://github.com/magento/magento2)
- [Adobe Commerce documentation](https://experienceleague.adobe.com/en/docs/commerce)

### Implementation Details

**First steps**

1. In the Magento service's Variables, open `MAGENTO_ADMIN_URL` and sign in as `admin` with `MAGENTO_ADMIN_PASSWORD`.
2. Under Stores > Configuration, set your store name, currency and email addresses.
3. Add products under Catalog. A new store has an empty catalog; the home page stays bare until you add content.

**Memory.** Allow at least 4 GB in total for a real store. It starts on smaller plans, but it will be slow, and first boot can take several minutes.

**What's not included.** This is built from Magento's public source. Adobe distributes some packages separately behind marketplace keys, so these are absent: admin two-factor sign-in, reCAPTCHA, Page Builder and multi-source inventory. The admin is protected by a generated password, a private path and Magento's login lockout. To add them, get [access keys](https://commercemarketplace.adobe.com/customer/accessKeys/) and build your own image from this template's repository.

**Language.** Static assets are built for `en_US` in the Luma, Blank and admin themes. Another language or a custom theme means adding it to the Dockerfile and building your own image.

**Custom domain.** Add it to the Magento service and update `MAGENTO_BASE_URL`.

**Licence.** Magento Open Source is OSL-3.0. Magento is a trademark of Adobe; this template is not affiliated with Adobe.

## Why Deploy Magento on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Magento on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
