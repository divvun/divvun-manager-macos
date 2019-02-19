 #!/bin/sh
export DEVELOPMENT_TEAM="2K5J2584NX"
export CODE_SIGN_IDENTITY="Developer ID Application: The University of Tromso (2K5J2584NX)"

VER=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Pahkat/Support/Info.plist`

xcodebuild -scheme Pahkat -configuration Release -workspace Pahkat.xcworkspace archive -archivePath build/pahkat.xcarchive -quiet || exit 1
	
rm -rf Divvun\ Installer.app
mv build/pahkat.xcarchive/Products/Applications/Divvun\ Installer.app .

pkgbuild --component Divvun\ Installer.app \
    --ownership recommended \
    --install-location /Applications \
    --version $VER \
    no.divvun.Pahkat.pkg

productbuild --distribution scripts/dist.xml \
    --version $VER \
    --package-path . \
    divvun-installer-$VER.unsigned.pkg

productsign --sign "Developer ID Installer: The University of Tromso (2K5J2584NX)" divvun-installer-$VER.unsigned.pkg divvun-installer-$VER.pkg
pkgutil --check-signature divvun-installer-$VER.pkg
