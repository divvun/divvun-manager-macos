import Foundation
import RxSwift

protocol CompletionViewable: AnyObject {
    var onRestartButtonTapped: Observable<Void> { get }
    var onFinishButtonTapped: Observable<Void> { get }
    
    func rebootSystem()
}
