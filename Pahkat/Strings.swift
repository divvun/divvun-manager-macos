// Generated. Do not edit.
import Foundation

fileprivate extension UserDefaults {
    var appleLanguages: [String] {
        return self.array(forKey: "AppleLanguages") as? [String] ??
            [Locale.autoupdatingCurrent.languageCode ?? "en"]
    }
}

extension Locale {
    var derivedIdentifiers: [String] {
        let x = self
        var opts: [String] = []
        
        if let lang = x.languageCode {
            if let script = x.scriptCode, let region = x.regionCode {
                let c = "\(lang)-\(script)-\(region)"
                opts.append(c)
                if let x = localeTree[c] {
                    opts.append(contentsOf: x)
                    return opts
                }
            }
            
            if let script = x.scriptCode {
                let c = "\(lang)-\(script)"
                opts.append(c)
                if let x = localeTree[c] {
                    opts.append(contentsOf: x)
                    return opts
                }
            }
            
            if let region = x.regionCode {
                let c = "\(lang)-\(region)"
                opts.append(c)
                if let x = localeTree[c] {
                    opts.append(contentsOf: x)
                    return opts
                }
            }
            
            opts.append(lang)
            if let x = localeTree[lang] {
                opts.append(contentsOf: x)
            }
        }
        
        return opts
    }
}

class Strings {
    static var bundle: Bundle = Bundle.main
    
    static var languageCode: String = UserDefaults.standard.appleLanguages[0] {
        didSet {
            var bundle: Bundle? = nil
            
            for code in Locale(identifier: languageCode).derivedIdentifiers {
                if let dir = Bundle.main.path(forResource: code, ofType: "lproj"), let b = Bundle(path: dir) {
                    bundle = b
                    break
                }
            }
            
            if let bundle = bundle {
                self.bundle = bundle
            } else {
                print("No bundle found for \(languageCode))")
                self.bundle = Bundle.main
            }
        }
    }

    internal static func string(for key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    internal static func stringArray(for key: String, length: Int) -> [String] {
        return (0..<length).map {
            bundle.localizedString(forKey: "\(key)_\($0)", value: nil, table: nil)
        }
    }

    /** About Package Manager */
    static var aboutApp: String {
        return string(for: "aboutApp")
    }

    /** Alpha */
    static var alpha: String {
        return string(for: "alpha")
    }

    /** Help */
    static var appHelp: String {
        return string(for: "appHelp")
    }

    /** Package Manager */
    static var appName: String {
        return string(for: "appName")
    }

    /** Package Manager v{version} is now available. It is highly recommended that you update as soon as possible. Update now? */
    static func appUpdateBody(version: String) -> String {
        let format = string(for: "appUpdateBody")
        return String(format: format, version)
    }

    /** Package Manager Update Available */
    static var appUpdateTitle: String {
        return string(for: "appUpdateTitle")
    }

    /** Beta */
    static var beta: String {
        return string(for: "beta")
    }

    /** Bring All to Front */
    static var bringAllToFront: String {
        return string(for: "bringAllToFront")
    }

    /** Cancel */
    static var cancel: String {
        return string(for: "cancel")
    }

    /** Are you sure you want to cancel all downloads? */
    static var cancelDownloadsBody: String {
        return string(for: "cancelDownloadsBody")
    }

    /** Cancel Downloads */
    static var cancelDownloadsTitle: String {
        return string(for: "cancelDownloadsTitle")
    }

    /** Canceling... */
    static var cancelling: String {
        return string(for: "cancelling")
    }

    /** Category */
    static var category: String {
        return string(for: "category")
    }

    /** Channel */
    static var channel: String {
        return string(for: "channel")
    }

    /** Check For Updates... */
    static var checkForUpdates: String {
        return string(for: "checkForUpdates")
    }

    /** Completed */
    static var completed: String {
        return string(for: "completed")
    }

    /** Copy */
    static var copy: String {
        return string(for: "copy")
    }

    /** Do you wish to send a crash report to the developers? No personal or private information is sent. (Recommended) */
    static var crashReportBody: String {
        return string(for: "crashReportBody")
    }

    /** Cut */
    static var cut: String {
        return string(for: "cut")
    }

    /** Daily */
    static var daily: String {
        return string(for: "daily")
    }

    /** Delete */
    static var delete: String {
        return string(for: "delete")
    }

    /** Error 😞 */
    static var downloadError: String {
        return string(for: "downloadError")
    }

    /** Downloaded */
    static var downloaded: String {
        return string(for: "downloaded")
    }

    /** Downloading... */
    static var downloading: String {
        return string(for: "downloading")
    }

    /** Edit */
    static var edit: String {
        return string(for: "edit")
    }

    /** Error */
    static var error: String {
        return string(for: "error")
    }

    /** An error occurring during installation. */
    static var errorDuringInstallation: String {
        return string(for: "errorDuringInstallation")
    }

    /** Error: Invalid Version */
    static var errorInvalidVersion: String {
        return string(for: "errorInvalidVersion")
    }

    /** Error: No Installer */
    static var errorNoInstaller: String {
        return string(for: "errorNoInstaller")
    }

    /** Error: Unknown Item */
    static var errorUnknownPackage: String {
        return string(for: "errorUnknownPackage")
    }

    /** Every 4 Weeks */
    static var everyFourWeeks: String {
        return string(for: "everyFourWeeks")
    }

    /** Every 2 Weeks */
    static var everyTwoWeeks: String {
        return string(for: "everyTwoWeeks")
    }

    /** Exit */
    static var exit: String {
        return string(for: "exit")
    }

    /** Finish */
    static var finish: String {
        return string(for: "finish")
    }

    /** Help */
    static var help: String {
        return string(for: "help")
    }

    /** Hide Package Manager */
    static var hideApp: String {
        return string(for: "hideApp")
    }

    /** Hide Others */
    static var hideOthers: String {
        return string(for: "hideOthers")
    }

    /** Install */
    static var install: String {
        return string(for: "install")
    }

    /** Install {count} Items */
    static func installNPackages(count: String) -> String {
        let format = string(for: "installNPackages")
        return String(format: format, count)
    }

    /** Install (System) */
    static var installSystem: String {
        return string(for: "installSystem")
    }

    /** Install/Uninstall {count} Items */
    static func installUninstallNPackages(count: String) -> String {
        let format = string(for: "installUninstallNPackages")
        return String(format: format, count)
    }

    /** Install (User) */
    static var installUser: String {
        return string(for: "installUser")
    }

    /** Installed */
    static var installed: String {
        return string(for: "installed")
    }

    /** Installing {name} {version}... */
    static func installingPackage(name: String, version: String) -> String {
        let format = string(for: "installingPackage")
        return String(format: format, name, version)
    }

    /** Installing/Uninstalling */
    static var installingUninstalling: String {
        return string(for: "installingUninstalling")
    }

    /** Interface Language */
    static var interfaceLanguage: String {
        return string(for: "interfaceLanguage")
    }

    /** Please ensure that the URL begins with "https" and try again. */
    static var invalidUrlBody: String {
        return string(for: "invalidUrlBody")
    }

    /** The provided URL is invalid. */
    static var invalidUrlTitle: String {
        return string(for: "invalidUrlTitle")
    }

    /** Language */
    static var language: String {
        return string(for: "language")
    }

    /** Loading... */
    static var loading: String {
        return string(for: "loading")
    }

    /** Minimize */
    static var minimize: String {
        return string(for: "minimize")
    }

    /** {count} items remaining. */
    static func nItemsRemaining(count: String) -> String {
        let format = string(for: "nItemsRemaining")
        return String(format: format, count)
    }

    /** {count} Updates Available */
    static func nUpdatesAvailable(count: String) -> String {
        let format = string(for: "nUpdatesAvailable")
        return String(format: format, count)
    }

    /** Never */
    static var never: String {
        return string(for: "never")
    }

    /** Next update check at: {date} */
    static func nextUpdateDue(date: String) -> String {
        let format = string(for: "nextUpdateDue")
        return String(format: format, date)
    }

    /** Nightly */
    static var nightly: String {
        return string(for: "nightly")
    }

    /** No Items Selected */
    static var noPackagesSelected: String {
        return string(for: "noPackagesSelected")
    }

    /** No new updates were found. */
    static var noUpdatesBody: String {
        return string(for: "noUpdatesBody")
    }

    /** No Updates */
    static var noUpdatesTitle: String {
        return string(for: "noUpdatesTitle")
    }

    /** -- */
    static var notApplicable: String {
        return string(for: "notApplicable")
    }

    /** Not Installed */
    static var notInstalled: String {
        return string(for: "notInstalled")
    }

    /** OK */
    static var ok: String {
        return string(for: "ok")
    }

    /** Open Package Manager */
    static var openPackageManager: String {
        return string(for: "openPackageManager")
    }

    /** Paste */
    static var paste: String {
        return string(for: "paste")
    }

    /** Paste and Match Style */
    static var pasteAndMatchStyle: String {
        return string(for: "pasteAndMatchStyle")
    }

    /** Preferences… */
    static var preferences: String {
        return string(for: "preferences")
    }

    /** You may now close this window, or return to the main screen. */
    static var processCompletedBody: String {
        return string(for: "processCompletedBody")
    }

    /** Done! */
    static var processCompletedTitle: String {
        return string(for: "processCompletedTitle")
    }

    /** Queued */
    static var queued: String {
        return string(for: "queued")
    }

    /** Quit Package Manager */
    static var quitApp: String {
        return string(for: "quitApp")
    }

    /** Redo */
    static var redo: String {
        return string(for: "redo")
    }

    /** Remind Me Later */
    static var remindMeLater: String {
        return string(for: "remindMeLater")
    }

    /** Are you sure you wish to remove this repository? */
    static var removeRepoBody: String {
        return string(for: "removeRepoBody")
    }

    /** This will remove the selected repository. */
    static var removeRepoTitle: String {
        return string(for: "removeRepoTitle")
    }

    /** Repositories */
    static var repositories: String {
        return string(for: "repositories")
    }

    /** Repository */
    static var repository: String {
        return string(for: "repository")
    }

    /** Repository Error */
    static var repositoryError: String {
        return string(for: "repositoryError")
    }

    /** There was an error while opening the repository:

{message} */
    static func repositoryErrorBody(message: String) -> String {
        let format = string(for: "repositoryErrorBody")
        return String(format: format, message)
    }

    /** Restart Later */
    static var restartLater: String {
        return string(for: "restartLater")
    }

    /** Restart Now */
    static var restartNow: String {
        return string(for: "restartNow")
    }

    /** It is highly recommended that you restart your computer in order for some changes to take effect. */
    static var restartRequiredBody: String {
        return string(for: "restartRequiredBody")
    }

    /** Time to reboot! */
    static var restartRequiredTitle: String {
        return string(for: "restartRequiredTitle")
    }

    /** Restart the app for language changes to take effect. */
    static var restartTheAppForLanguageChanges: String {
        return string(for: "restartTheAppForLanguageChanges")
    }

    /** Save */
    static var save: String {
        return string(for: "save")
    }

    /** Select All */
    static var selectAll: String {
        return string(for: "selectAll")
    }

    /** Services */
    static var services: String {
        return string(for: "services")
    }

    /** Settings */
    static var settings: String {
        return string(for: "settings")
    }

    /** Show All */
    static var showAll: String {
        return string(for: "showAll")
    }

    /** Skip These Updates */
    static var skipTheseUpdates: String {
        return string(for: "skipTheseUpdates")
    }

    /** Sort by… */
    static var sortBy: String {
        return string(for: "sortBy")
    }

    /** Stable */
    static var stable: String {
        return string(for: "stable")
    }

    /** Starting... */
    static var starting: String {
        return string(for: "starting")
    }

    /** Default Language */
    static var systemLocale: String {
        return string(for: "systemLocale")
    }

    /** There are {count} updates available! */
    static func thereAreNUpdatesAvailable(count: String) -> String {
        let format = string(for: "thereAreNUpdatesAvailable")
        return String(format: format, count)
    }

    /** Undo */
    static var undo: String {
        return string(for: "undo")
    }

    /** Uninstall */
    static var uninstall: String {
        return string(for: "uninstall")
    }

    /** Uninstall {count} Items */
    static func uninstallNPackages(count: String) -> String {
        let format = string(for: "uninstallNPackages")
        return String(format: format, count)
    }

    /** Uninstalling {name} {version}... */
    static func uninstallingPackage(name: String, version: String) -> String {
        let format = string(for: "uninstallingPackage")
        return String(format: format, name, version)
    }

    /** Update */
    static var update: String {
        return string(for: "update")
    }

    /** Update Available */
    static var updateAvailable: String {
        return string(for: "updateAvailable")
    }

    /** Update Channel */
    static var updateChannel: String {
        return string(for: "updateChannel")
    }

    /** Update Frequency */
    static var updateFrequency: String {
        return string(for: "updateFrequency")
    }

    /** Update (System) */
    static var updateSystem: String {
        return string(for: "updateSystem")
    }

    /** Update (User) */
    static var updateUser: String {
        return string(for: "updateUser")
    }

    /** URL */
    static var url: String {
        return string(for: "url")
    }

    /** {description} (User) */
    static func userDescription(description: String) -> String {
        let format = string(for: "userDescription")
        return String(format: format, description)
    }

    /** Version Skipped */
    static var versionSkipped: String {
        return string(for: "versionSkipped")
    }

    /** Waiting for process to finish... */
    static var waitingForCompletion: String {
        return string(for: "waitingForCompletion")
    }

    /** Weekly */
    static var weekly: String {
        return string(for: "weekly")
    }

    /** Window */
    static var window: String {
        return string(for: "window")
    }

    /** Would you like to download them now? */
    static var wouldYouLikeToDownloadThemNow: String {
        return string(for: "wouldYouLikeToDownloadThemNow")
    }

    /** Zoom */
    static var zoom: String {
        return string(for: "zoom")
    }

    private init() {}
}

fileprivate let localeTree = [
    "en-001": ["en-001","en"],
    "en": ["en"],
    "nb": ["nb"],
    "nn-Runr": ["nn-Runr","nn"],
    "nn": ["nn"],
    "se": ["se"]
]
