#!/bin/sh
set -ex

export MACOS_DEVELOPMENT_TEAM="2K5J2584NX"
export MACOS_CODE_SIGN_IDENTITY="Developer ID Application: The University of Tromso (2K5J2584NX)"
export MACOS_CODE_SIGN_IDENTITY_INSTALLER="Developer ID Installer: The University of Tromso (2K5J2584NX)"

APP_NAME="Divvun Manager.app"
PKG_NAME="DivvunManager.pkg"

echo "::add-mask::$MACOS_NOTARIZATION_APP_PWD"

xcodebuild -scheme "Divvun Manager" -configuration Release archive -archivePath build/app.xcarchive -quiet \
    CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="$MACOS_DEVELOPMENT_TEAM" CODE_SIGN_IDENTITY="$MACOS_CODE_SIGN_IDENTITY" -quiet -allowProvisioningUpdates  \
    OTHER_CODE_SIGN_FLAGS=--options=runtime || exit 1

rm -rf "$APP_NAME"
mv "build/app.xcarchive/Products/Applications/$APP_NAME" .

# Sign & copy daemon into bundle
chmod +x scripts/pahkatd
cp scripts/pahkatd "$APP_NAME/Contents/MacOS/pahkatd"
# Need to re-sign app bundle
codesign --options=runtime -f --deep -s "$MACOS_CODE_SIGN_IDENTITY" "$APP_NAME"

echo "Notarizing bundle"
xcnotary notarize "$APP_NAME" --override-path-type app -d "$MACOS_DEVELOPER_ACCOUNT" -p "$MACOS_NOTARIZATION_APP_PWD"
stapler validate "$APP_NAME"

VERSION=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_NAME/Contents/Info.plist"`

# App installer
pkgbuild --component "$APP_NAME" \
    --ownership recommended \
    --scripts "scripts/scripts" \
    --install-location /Applications \
    --version $VERSION \
    no.divvun.Manager.pkg

productbuild --distribution scripts/dist.xml \
    --version $VERSION \
    --package-path . \
    divvun-manager.unsigned.pkg

productsign --sign "$MACOS_CODE_SIGN_IDENTITY_INSTALLER" divvun-manager.unsigned.pkg "$PKG_NAME"
pkgutil --check-signature "$PKG_NAME"

echo "Notarizing installer"
xcnotary notarize "$PKG_NAME" --override-path-type app -d "$MACOS_DEVELOPER_ACCOUNT" -p "$MACOS_NOTARIZATION_APP_PWD"
stapler validate "$PKG_NAME"
