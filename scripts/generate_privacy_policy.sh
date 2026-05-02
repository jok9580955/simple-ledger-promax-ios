#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${PRIVACY_BASE_URL:-https://jok9580955.github.io/simple-ledger-promax-ios}"
APP_NAME="Simple Ledger ProMax"
CONTACT_EMAIL="jok9580955@gmail.com"

LOCALES=(
  ar-SA ca cs da de-DE el en-AU en-CA en-GB en-US es-ES es-MX fi fr-CA fr-FR
  he hi hr hu id it ja ko ms nl-NL no pl pt-BR pt-PT ro ru sk sv th tr uk vi
  zh-Hans zh-Hant
)

mkdir -p docs

cat > docs/index.html <<HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${APP_NAME}</title>
  <style>
    body { margin: 0; font: 17px/1.55 -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif; color: #1d1d1f; background: #f5f5f7; }
    main { max-width: 820px; margin: 0 auto; padding: 56px 22px; }
    h1 { font-size: 44px; line-height: 1.08; letter-spacing: 0; margin: 0 0 12px; }
    h2 { font-size: 24px; margin-top: 34px; }
    p, li { color: #424245; }
    a { color: #06c; text-decoration: none; }
    .panel { background: #fff; border: 1px solid #e5e5ea; border-radius: 8px; padding: 24px; }
    .links { display: flex; gap: 14px; flex-wrap: wrap; margin-top: 24px; }
  </style>
</head>
<body>
  <main>
    <h1>${APP_NAME}</h1>
    <p>A simple, local-first daily ledger for expenses, income, transfers, Siri, and Shortcuts.</p>
    <div class="panel">
      <h2>Support</h2>
      <p>Need help or want to report an issue? Email <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>.</p>
      <div class="links">
        <a href="./privacy.html">Privacy Policy</a>
        <a href="./support.html">Support</a>
      </div>
    </div>
  </main>
</body>
</html>
HTML

cat > docs/privacy.html <<HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Privacy Policy - ${APP_NAME}</title>
  <style>
    body { margin: 0; font: 17px/1.6 -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif; color: #1d1d1f; background: #f5f5f7; }
    main { max-width: 820px; margin: 0 auto; padding: 48px 22px; }
    h1 { font-size: 38px; line-height: 1.12; margin: 0 0 8px; }
    h2 { font-size: 22px; margin-top: 30px; }
    p, li { color: #424245; }
    a { color: #06c; text-decoration: none; }
  </style>
</head>
<body>
  <main>
    <h1>Privacy Policy</h1>
    <p>Last updated: May 2, 2026</p>
    <p>${APP_NAME} is designed as a local-first personal bookkeeping app. Your ledger data is stored on your device.</p>
    <h2>Data We Collect</h2>
    <p>We do not operate a server for collecting your expenses, income, accounts, categories, notes, or statistics.</p>
    <h2>Siri and Shortcuts</h2>
    <p>When you use Siri or Shortcuts to record a transaction, iOS processes your voice request and passes the transaction details to the app. The app stores the resulting record locally on your device.</p>
    <h2>Analytics and Tracking</h2>
    <p>The app does not include third-party advertising SDKs and does not track you across apps or websites.</p>
    <h2>Data Deletion</h2>
    <p>You can delete records inside the app. You can also remove all local app data by deleting the app from your device.</p>
    <h2>Contact</h2>
    <p>For privacy questions, contact <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>.</p>
  </main>
</body>
</html>
HTML

cat > docs/support.html <<HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Support - ${APP_NAME}</title>
  <style>
    body { margin: 0; font: 17px/1.6 -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif; color: #1d1d1f; background: #f5f5f7; }
    main { max-width: 820px; margin: 0 auto; padding: 48px 22px; }
    h1 { font-size: 38px; line-height: 1.12; margin: 0 0 8px; }
    h2 { font-size: 22px; margin-top: 30px; }
    p, li { color: #424245; }
    a { color: #06c; text-decoration: none; }
  </style>
</head>
<body>
  <main>
    <h1>Support</h1>
    <p>${APP_NAME} helps you record daily expenses, income, transfers, and Siri voice bookkeeping.</p>
    <h2>Get Help</h2>
    <p>Email <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a> for support, bug reports, or feature requests.</p>
    <h2>Common Tips</h2>
    <ul>
      <li>Use the Add tab to record expenses, income, or transfers.</li>
      <li>Use Siri or Shortcuts to create a transaction by voice.</li>
      <li>Use Statistics to review monthly spending and category rankings.</li>
    </ul>
    <p><a href="./privacy.html">Privacy Policy</a></p>
  </main>
</body>
</html>
HTML

for locale in "${LOCALES[@]}"; do
  metadata_dir="fastlane/metadata/${locale}"
  mkdir -p "${metadata_dir}"
  printf "%s/privacy.html\n" "${BASE_URL}" > "${metadata_dir}/privacy_url.txt"
  printf "%s/support.html\n" "${BASE_URL}" > "${metadata_dir}/support_url.txt"
done

echo "Generated privacy/support URLs for ${#LOCALES[@]} locales at ${BASE_URL}"
