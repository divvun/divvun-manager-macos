#!/bin/sh
set -ex

export MACOS_DEVELOPMENT_TEAM="2K5J2584NX"
export MACOS_CODE_SIGN_IDENTITY="Developer ID Application: The University of Tromso (2K5J2584NX)"
export MACOS_CODE_SIGN_IDENTITY_INSTALLER="Developer ID Installer: The University of Tromso (2K5J2584NX)"

APP_NAME="Divvun Manager.app"
PKG_NAME="DivvunManager.pkg"

rm -rf tmp || echo "no tmp dir; continuing"
rm -rf build || echo "no build dir; continuing"

echo "::group::Building Divvun Manager"
xcodebuild -scheme "Divvun Manager" -configuration Release archive -clonedSourcePackagesDirPath tmp/src -derivedDataPath tmp/derived -archivePath build/app.xcarchive \
    CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="$MACOS_DEVELOPMENT_TEAM" CODE_SIGN_IDENTITY="$MACOS_CODE_SIGN_IDENTITY" -allowProvisioningUpdates  \
    OTHER_CODE_SIGN_FLAGS=--options=runtime || exit 1

rm -rf "$APP_NAME"
mv "build/app.xcarchive/Products/Applications/$APP_NAME" .

echo "::endgroup::"
echo "::group::Signing and notarizing Divvun Manager"

# Sign & copy daemon into bundle
chmod +x scripts/pahkatd
cp scripts/pahkatd "$APP_NAME/Contents/MacOS/pahkatd"

# Update the version to the one provided by the build system
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_NAME/Contents/Info.plist"

# Need to re-sign app bundle
codesign --options=runtime -f --deep -s "$MACOS_CODE_SIGN_IDENTITY" "$APP_NAME"

echo "Notarizing bundle"
xcrun notarytool submit "$APP_NAME" --apple-id "$INPUT_MACOS_DEVELOPER_ACCOUNT" --password "$INPUT_MACOS_NOTARIZATION_APP_PWD" --wait
stapler validate "$APP_NAME"

echo "::endgroup::"
echo "::group::Building .pkg"

# App installer
pkgbuild --component "$APP_NAME" \
    --ownership recommended \
    --scripts "scripts/scripts" \
    --install-location /Applications \
    no.divvun.Manager.pkg

dir=$PWD

# Fix the broken version in the file
TMPDIR=`mktemp -d /tmp/build.XXXXXX` || exit 1
pushd $TMPDIR
xar -xf $dir/no.divvun.Manager.pkg
python3 <<EOF
from xml.etree import ElementTree
x = ElementTree.fromstring(open("./PackageInfo", "rb").read())
x.attrib['version'] = "$VERSION"
x.find("*[@CFBundleShortVersionString]").attrib["CFBundleShortVersionString"] = "$VERSION"
out = ElementTree.tostring(x).decode('utf-8')
with open("./PackageInfo", "w", encoding="utf-8") as f:
    f.write(out)
EOF
xar -cf $dir/no.divvun.Manager.pkg --compression=none --distribution Bom Payload Scripts PackageInfo
popd

productbuild --distribution scripts/dist.xml \
    --package-path . \
    divvun-manager.unsigned.pkg

echo "::endgroup::"
echo "::group::Signing and notarizing .pkg"

productsign --sign "$MACOS_CODE_SIGN_IDENTITY_INSTALLER" divvun-manager.unsigned.pkg "$PKG_NAME"
pkgutil --check-signature "$PKG_NAME"

echo "Notarizing installer"
xcrun notarytool submit "$PKG_NAME" --apple-id "$INPUT_MACOS_DEVELOPER_ACCOUNT" --password "$INPUT_MACOS_NOTARIZATION_APP_PWD" --wait
stapler validate "$PKG_NAME"
echo "::endgroup::"
