#!/usr/bin/env bash
# Build the public-only Universo Geek demo artifact for Cloudflare Pages.
# Keep this allowlist in sync with the GitHub Pages demo workflow.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DIST_DIR="${DIST_DIR:-dist}"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/assets"

# Copy only pages intended for the public demo. Never publish repository root.
for page in \
  index.html \
  login.html \
  services.html \
  membership.html \
  dashboard.html \
  privacy.html \
  cookies.html \
  terms.html \
  payment-result.html
do
  test -f "$page" || { echo "Required public page is missing: $page" >&2; exit 1; }
  cp "$page" "$DIST_DIR/"
done

# Frontend assets only. Do not copy docs, migrations, tests, or admin files.
cp -R assets/css assets/js "$DIST_DIR/assets/"
touch "$DIST_DIR/.nojekyll"

test -f "$DIST_DIR/index.html"
test -f "$DIST_DIR/assets/js/config.js"

# This demo must only use the isolated Supabase test project and public keys.
grep -Fq 'https://tvjglznjntegujfczljp.supabase.co' "$DIST_DIR/assets/js/config.js" || {
  echo "Demo config does not point to the approved test Supabase project." >&2
  exit 1
}
if grep -RIEq 'service_role[[:space:]]*[:=]|sb_secret_|SUPABASE_SERVICE_ROLE_KEY[[:space:]]*=' "$DIST_DIR"; then
  echo "Potential server-side secret detected in the public artifact." >&2
  exit 1
fi

echo "Public demo artifact prepared in $DIST_DIR"
