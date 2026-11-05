# Security Hardening — images/custom/Containerfile.security-patched

This document records the security hardening decisions applied to
`images/custom/Containerfile.security-patched` and the criteria used.
This file is the target to replace `images/custom/Containerfile` once
all apps have been validated through UAT.

---

## Bloatware Removal

### vim / vim-common / vim-runtime / vim-tiny

**Removed in:** commit 63833695
**Criteria:** A package is bloatware if it serves no function during
runtime operation of the application.

`vim` was included in the Frappe base image for developer convenience
(shelling into containers for debugging). In a production backend
container, all changes go through the CI/CD pipeline — no engineer
should be editing files inside a running container. Zero production
purpose.

**CVEs eliminated:** 69 HIGH
**Estimated size reduction:** ~30–40 MB

### esbuild binary (node_modules build artifact)

**Removed in:** commit 63833695
**Criteria:** A build-time tool that was not cleaned up after build
completion is bloatware in the production image.

`esbuild` is a JavaScript bundler used by Frappe during `bench build`
to compile frontend assets. Once the build completes, the compiled
assets are in `sites/assets/` and `esbuild` is no longer needed.
The binary remained inside `node_modules` and was copied into the
production image — a build artifact left in the runtime image.

**CVEs eliminated:** 276 CRITICAL/HIGH (outdated Go stdlib inside binary)
**Estimated size reduction:** ~8–12 MB

---

## OS Package Upgrades

Applied via `apt-get install -y --only-upgrade` — upgrades existing
packages only, does not install new software.

| Package | CVEs addressed |
|---------|---------------|
| perl / libperl5.36 / perl-modules-5.36 | CVE-2026-13221, CVE-2026-42496, CVE-2026-8376 + 9 more |
| libexpat1 | CVE-2024-28757, CVE-2026-25210 + 6 more |
| libssl3 / openssl | CVE-2026-84782 + 5 more |
| libpng16-16 | CVE-2026-46675 |
| libbrotli1 | CVE-2026-111497 |
| tar | CVE-2026-59873 + 3 more |

---

## Python Package Upgrades

Applied via pip inside the Frappe virtualenv
(`/home/frappe/frappe-bench/env/bin/pip`).

| Package | Fix version | CVEs addressed |
|---------|------------|---------------|
| Pillow | >=13.0.0 | 5 CRITICAL RCE (CVE-2026-112393 + 4 more) |
| PyJWT | >=2.14.0 | CVE-2026-102268 + 9 more |
| certifi | >=2026.10.18 | GHSA-6q48-6c7w-9gw2 |
| weasyprint | >=70.0 | CVE-2026-106443, CVE-2026-55073 |
| pypdf | >=6.19.0 | CVE-2026-102993 + 8 more |
| Werkzeug | >=3.1.9 | CVE-2026-102598 |
| oauthlib | >=4.0.0 | CVE-2026-49264, CVE-2026-49265 |
| wheel | >=0.46.2 | CVE-2026-24049 |
| GitPython | >=3.2.1 | 5 HIGH CVEs |
| msgpack | >=1.2.1 | 2 HIGH CVEs |
| urllib3 | >=2.8.0 | 2 HIGH CVEs |
| filelock | >=4.2.1 | 1 HIGH CVE |
| setuptools | >=78.1.1 | 1 HIGH CVE |

---

## Node.js Package Upgrades

Applied via npm inside the Frappe app directory.

| Package | Fix version | CVEs addressed |
|---------|------------|---------------|
| brace-expansion | 2.1.5 | 10 HIGH |
| postcss | 8.5.18 | 10 HIGH |
| nanoid | 3.3.12 | 3 HIGH |
| minimatch | 10.2.1 | 3 HIGH |
| svgo | 3.3.5 | 3 HIGH |
| browserslist | 4.28.7 | 2 HIGH |
| ws | 8.21.0 | 2 HIGH |
| socket.io-parser | 4.2.6 | 2 HIGH |
| shell-quote | 1.9.0 | 1 CRITICAL |
| form-data | 4.0.6 | 1 CRITICAL |
| loader-utils | 2.0.3 | 1 CRITICAL |

---

## Known Unfixable CVEs (no upstream fix available)

These packages have open CVEs with no Debian or upstream patch released.
They are tracked and will be patched as soon as fixes are available.

| Package | Severity | CVE |
|---------|----------|-----|
| libglib2.0-0 | CRITICAL | CVE-2026-58016 |
| libsqlite3-0 | CRITICAL | CVE-2025-7458 |
| libxml2 | CRITICAL | CVE-2026-6653 |
| zlib1g | CRITICAL | CVE-2023-45853 |
| mariadb-client | HIGH | Multiple |
| util-linux | HIGH | Multiple |
| curl / libcurl | HIGH | Multiple |

---

## CVE Summary — Before vs After

| Severity | Containerfile (current) | Containerfile.security-patched |
|----------|------------------------|-------------------------------|
| CRITICAL | 18 | ~4 (unfixable OS packages) |
| HIGH | 572 | ~135 (unfixable OS packages) |
| MEDIUM | 674 | ~280 |

---

## Rollout Plan

`Containerfile.security-patched` replaces `Containerfile` once:
1. All apps pass UAT smoke test on the patched image
2. Security engineer sign-off received
3. Team lead approval for production cutover
