#!/bin/sh

xcodebuild -scheme Pahkat -configuration Release -workspace Pahkat.xcworkspace SYMROOT="$PWD/build"
VER=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $PWD/build/Release/Pahkat.app/Contents/Info.plist`
pkgbuild --component build/Release/Pahkat.app --scripts scripts --ownership recommended --install-location /Applications --version $VER $PWD/build/pahkat_$VER.pkg
