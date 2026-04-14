#!/usr/bin/env bash
# Creates the XWiki Vault secret (secret/xwiki) from scratch.
# Generates: PG password, cookie validation/encryption keys.
# Requires: OIDC_SECRET env var (from terraform output -raw xwiki_client_secret)
#
# Usage:
#   kubectl port-forward -n vault vault-0 8200:8200 &
#   OIDC_SECRET=<value> bash scripts/vault-xwiki.sh            # dev (default)
#   ENV=prod OIDC_SECRET=<value> bash scripts/vault-xwiki.sh   # prod
set -euo pipefail

ENV="${ENV:-dev}"

# dev → xwiki.dev.hdc.ebrains.eu / iam.dev.hdc.ebrains.eu
# prod → xwiki.hdc.ebrains.eu    / iam.hdc.ebrains.eu
if [[ "$ENV" == "prod" ]]; then
  DOMAIN_BASE="hdc.ebrains.eu"
else
  DOMAIN_BASE="${ENV}.hdc.ebrains.eu"
fi
XWIKI_HOST="xwiki.${DOMAIN_BASE}"
IAM_HOST="iam.${DOMAIN_BASE}"

export VAULT_ADDR=http://127.0.0.1:8200

PG_PASS=$(openssl rand -hex 16)
VALIDATION_KEY=$(openssl rand -hex 16)
ENCRYPTION_KEY=$(openssl rand -hex 16)

if [[ -z "${OIDC_SECRET:-}" ]]; then
  echo "ERROR: Set OIDC_SECRET first (from terraform output -raw xwiki_client_secret)" >&2
  exit 1
fi

vault kv put secret/xwiki \
  postgresql-password="$PG_PASS" \
  xwiki-cfg="xwiki.encoding=UTF-8
xwiki.store.migration=1

xwiki.home=https://${XWIKI_HOST}
xwiki.url.protocol=https
xwiki.webapppath=
xwiki.inactiveuser.allowedpages=

xwiki.authentication.authclass=org.xwiki.contrib.oidc.auth.OIDCAuthServiceImpl
xwiki.authentication.validationKey=$VALIDATION_KEY
xwiki.authentication.encryptionKey=$ENCRYPTION_KEY
xwiki.authentication.cookiedomains=
xwiki.authentication.logoutpage=(/|/[^/]+/|/wiki/[^/]+/)logout/*

xwiki.defaultskin=flamingo
xwiki.defaultbaseskin=flamingo
xwiki.section.edit=1
xwiki.section.depth=2
xwiki.backlinks=1
xwiki.tags=1
xwiki.stats.default=0
xwiki.editcomment=1
xwiki.editcomment.mandatory=0
xwiki.plugin.image.cache.capacity=30

xwiki.plugins=\\
  com.xpn.xwiki.monitor.api.MonitorPlugin,\\
  com.xpn.xwiki.plugin.skinx.JsSkinExtensionPlugin,\\
  com.xpn.xwiki.plugin.skinx.JsSkinFileExtensionPlugin,\\
  com.xpn.xwiki.plugin.skinx.JsResourceSkinExtensionPlugin,\\
  com.xpn.xwiki.plugin.skinx.CssSkinExtensionPlugin,\\
  com.xpn.xwiki.plugin.skinx.CssSkinFileExtensionPlugin,\\
  com.xpn.xwiki.plugin.skinx.CssResourceSkinExtensionPlugin,\\
  com.xpn.xwiki.plugin.skinx.LinkExtensionPlugin,\\
  com.xpn.xwiki.plugin.feed.FeedPlugin,\\
  com.xpn.xwiki.plugin.mail.MailPlugin,\\
  com.xpn.xwiki.plugin.packaging.PackagePlugin,\\
  com.xpn.xwiki.plugin.svg.SVGPlugin,\\
  com.xpn.xwiki.plugin.fileupload.FileUploadPlugin,\\
  com.xpn.xwiki.plugin.image.ImagePlugin,\\
  com.xpn.xwiki.plugin.diff.DiffPlugin,\\
  com.xpn.xwiki.plugin.rightsmanager.RightsManagerPlugin,\\
  com.xpn.xwiki.plugin.jodatime.JodaTimePlugin,\\
  com.xpn.xwiki.plugin.scheduler.SchedulerPlugin,\\
  com.xpn.xwiki.plugin.mailsender.MailSenderPlugin,\\
  com.xpn.xwiki.plugin.tag.TagPlugin,\\
  com.xpn.xwiki.plugin.zipexplorer.ZipExplorerPlugin" \
  xwiki-properties="environment.permanentDirectory=/usr/local/xwiki/data

oidc.xwikiprovider=https://${XWIKI_HOST}/oidc
oidc.endpoint.authorization=https://${IAM_HOST}/realms/hdc/protocol/openid-connect/auth
oidc.endpoint.token=https://${IAM_HOST}/realms/hdc/protocol/openid-connect/token
oidc.endpoint.userinfo=https://${IAM_HOST}/realms/hdc/protocol/openid-connect/userinfo
oidc.scope=openid,profile,email,groups
oidc.endpoint.userinfo.method=GET
oidc.user.nameFormater=\${oidc.user.preferredUsername._clean._lowerCase}
oidc.user.subjectFormater=\${oidc.user.subject}
oidc.userinfoclaims=group
oidc.clientid=xwiki
oidc.secret=$OIDC_SECRET
oidc.endpoint.token.auth_method=client_secret_basic
oidc.skipped=false
oidc.groups.claim=group"

echo "Done (env=$ENV)."
echo "  PG password: $PG_PASS"
echo "  Validation key: $VALIDATION_KEY"
echo "  Encryption key: $ENCRYPTION_KEY"
