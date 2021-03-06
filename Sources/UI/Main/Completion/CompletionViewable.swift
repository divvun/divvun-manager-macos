import Foundation
import RxSwift

protocol CompletionViewable: class {
    var onRestartButtonTapped: Observable<Void> { get }
    var onFinishButtonTapped: Observable<Void> { get }
    
    func rebootSystem()
}
