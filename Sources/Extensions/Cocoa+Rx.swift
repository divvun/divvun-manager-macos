import Cocoa
import RxSwift

class DisposableViewController<V: View>: ViewController<V> {
    internal var bag: DisposeBag! = DisposeBag()
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if bag == nil {
            bag = DisposeBag()
        }
    }
    
    override func viewWillDisappear() {
        bag = nil
        
        super.viewWillDisappear()
    }
}
