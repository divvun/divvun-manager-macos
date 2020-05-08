#!/bin/sh
set -ex
security default-keychain -s build.keychain
security unlock-keychain -p travis build.keychain
security set-keychain-settings -t 3600 -u build.keychain

export DEVELOPMENT_TEAM="2K5J2584NX"
export CODE_SIGN_IDENTITY="Developer ID Application: The University of Tromso (2K5J2584NX)"
export CODE_SIGN_IDENTITY_INSTALLER="Developer ID Installer: The University of Tromso (2K5J2584NX)"

# xcodebuild -scheme MacDivvun -configuration Release -workspace MacDivvun.xcworkspace archive -archivePath build/macdivvun.xcarchive \
#     DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" -quiet \
#     OTHER_CODE_SIGN_FLAGS=--options=runtime || exit 1

# xcodebuild -scheme Pahkat -configuration Release -workspace "Pahkat.xcodeproj/project.xcworkspace" archive -archivePath build/pahkat.xcarchive -quiet \
#     DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" -quiet -allowProvisioningUpdates  \
#     OTHER_CODE_SIGN_FLAGS=--options=runtime || exit 1

#xcodebuild -resolvePackageDependencies
APP_NAME="Divvun Installer.app"
PKG_NAME="DivvunInstaller.pkg"

xcodebuild -scheme Pahkat -configuration Release -workspace "Pahkat.xcodeproj/project.xcworkspace" archive -archivePath build/pahkat.xcarchive -quiet \
    CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="$MACOS_DEVELOPMENT_TEAM" CODE_SIGN_IDENTITY="$MACOS_CODE_SIGN_IDENTITY"  -quiet -allowProvisioningUpdates  \
    OTHER_CODE_SIGN_FLAGS=--options=runtime || exit 1

rm -rf "$APP_NAME"
mv "build/pahkat.xcarchive/Products/Applications/$APP_NAME" .

# Sign & copy daemon into bundle
chmod +x scripts/pahkatd
cp scripts/pahkatd "$APP_NAME/Contents/MacOS/pahkatd"
# Need to resign app bundle
codesign --options=runtime -f --deep -s "$MACOS_CODE_SIGN_IDENTITY" "$APP_NAME"

echo "Notarizing bundle"
xcnotary notarize "$APP_NAME" --override-path-type app -d "$MACOS_DEVELOPER_ACCOUNT" -k "$MACOS_DEVELOPER_PASSWORD_CHAIN_ITEM"
stapler validate "$APP_NAME"

# Daemon Installer

# pkgbuild --component "scripts/LaunchDaemons" \
#     --ownership recommended \
#     --install-location /Library \
#     --scripts "scripts/scripts" \
#     --version $VERSION \
#     no.divvun.pahkatd.pkg

VERSION=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_NAME/Contents/Info.plist"`

# App installer
pkgbuild --component "$APP_NAME" \
    --ownership recommended \
    --scripts "scripts/scripts" \
    --install-location /Applications \
    --version $VERSION \
    no.divvun.Pahkat.pkg

productbuild --distribution scripts/dist.xml \
    --version $VERSION \
    --package-path . \
    divvun-installer.unsigned.pkg


productsign --sign "$MACOS_CODE_SIGN_IDENTITY_INSTALLER" divvun-installer.unsigned.pkg "$PKG_NAME"
pkgutil --check-signature "$PKG_NAME"

echo "Notarizing installer"
xcnotary notarize "$PKG_NAME" --override-path-type pkg -d "$MACOS_DEVELOPER_ACCOUNT" -k "$MACOS_DEVELOPER_PASSWORD_CHAIN_ITEM"
stapler validate "$PKG_NAME"
