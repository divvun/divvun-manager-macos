#!/bin/sh
defaults delete no.divvun.Pahkat
rm -r ~/Library/Preferences/Pahkat
rm -r ~/Library/Caches/Pahkat
rm ~/Library/Preferences/no.divvun.Pahkat.plist
rm ~/Library/LaunchAgents/no.divvun.Pahkat.*
sudo killall no.divvun.PahkatAdminService
sudo rm /Library/PrivilegedHelperTools/no.divvun.PahkatAdminService
sudo rm /Library/LaunchDaemons/no.divvun.PahkatAdminService.plist
sudo rm -r /Applications/Divvun\ Installer.app
sudo pkgutil --forget no.divvun.Pahkat
