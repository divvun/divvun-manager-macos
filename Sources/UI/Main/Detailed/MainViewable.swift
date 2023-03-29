import Foundation
import RxSwift
import RxCocoa

protocol MainViewable: AnyObject {
    var onPackageEvent: Observable<OutlineEvent> { get }
    var onPrimaryButtonPressed: Driver<Void> { get }
    var onSettingsTapped: Driver<Void> { get }
    func update(title: String)
    func updateProgressIndicator(isEnabled: Bool)
    func updateSettingsButton(isEnabled: Bool)
    func updatePrimaryButton(isEnabled: Bool, label: String)
    func handle(error: Error)
    func setRepositories(data: MainOutlineMap)
    func refreshRepositories()
    func showSettings()
    func repositoriesChanged(repos: [LoadedRepository], records: [URL : RepoRecord])
}
