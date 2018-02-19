// Generated. Do not edit.
import Foundation

class Strings {
    static var languageCode: String? = nil {
        didSet {
            if let dir = Bundle.main.path(forResource: languageCode, ofType: "lproj"), let bundle = Bundle(path: dir) {
                self.bundle = bundle
            } else {
                print("No bundle found for \(String(describing: languageCode ?? nil))")
                self.bundle = Bundle.main
            }
        }
    }

    static var bundle: Bundle = Bundle.main

    fileprivate static func string(for key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    fileprivate static func stringArray(for key: String, length: Int) -> [String] {
        return (0..<length).map {
            bundle.localizedString(forKey: "\(key)_\($0)", value: nil, table: nil)
        }
    }

    /** Páhkat */
    static var appName: String {
        return string(for: "appName")
    }

    /** Automatically Send Crash Reports */
    static var autoCrashReporting: String {
        return string(for: "autoCrashReporting")
    }

    /** Páhkat v{version} is now available. It is highly recommended that you update as soon as possible. Update now? */
    static func appUpdateBody(version: String) -> String {
        let format = string(for: "appUpdateBody")
        return String(format: format, version)
    }

    /** Páhkat Update Available */
    static var appUpdateTitle: String {
        return string(for: "appUpdateTitle")
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

    /** Check For Updates... */
    static var checkForUpdates: String {
        return string(for: "checkForUpdates")
    }

    /** Do you wish to send a crash report to the developers? No personal or private information is sent. (Recommended) */
    static var crashReportBody: String {
        return string(for: "crashReportBody")
    }

    /** Send Crash Report */
    static var crashReportTitle: String {
        return string(for: "crashReportTitle")
    }

    /** Daily */
    static var daily: String {
        return string(for: "daily")
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

    /** Error */
    static var error: String {
        return string(for: "error")
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

    /** Install */
    static var install: String {
        return string(for: "install")
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

    /** Interface Language */
    static var interfaceLanguage: String {
        return string(for: "interfaceLanguage")
    }

    /** Loading... */
    static var loading: String {
        return string(for: "loading")
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

    /** You may now close this window, or return to the main screen. */
    static var processCompletedBody: String {
        return string(for: "processCompletedBody")
    }

    /** Done! */
    static var processCompletedTitle: String {
        return string(for: "processCompletedTitle")
    }

    /** Process {count} Items */
    static func processNPackages(count: String) -> String {
        let format = string(for: "processNPackages")
        return String(format: format, count)
    }

    /** Remind Me Later */
    static var remindMeLater: String {
        return string(for: "remindMeLater")
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

    /** Save */
    static var save: String {
        return string(for: "save")
    }

    /** Settings */
    static var settings: String {
        return string(for: "settings")
    }

    /** Skip These Updates */
    static var skipTheseUpdates: String {
        return string(for: "skipTheseUpdates")
    }

    /** Starting... */
    static var starting: String {
        return string(for: "starting")
    }

    /** Uninstall */
    static var uninstall: String {
        return string(for: "uninstall")
    }

    /** Uninstalling {name} {version}... */
    static func uninstallingPackage(name: String, version: String) -> String {
        let format = string(for: "uninstallingPackage")
        return String(format: format, name, version)
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

    private init() {}
}
