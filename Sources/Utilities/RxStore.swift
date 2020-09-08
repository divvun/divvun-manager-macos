import Foundation
import RxSwift
import RxFeedback

class RxStore<State, Event> {
    typealias Reducer = (State, Event) -> State
    
    private let dispatcher: PublishSubject<Event>
    let state: Observable<State>
    let bag = DisposeBag()
    
    func dispatch(event: Event) {
        dispatcher.onNext(event)
    }
    
    init(initialState: State, reducers: [Reducer]) {
        let dispatcher = PublishSubject<Event>()
        
        let state = Observable.system(
            initialState: initialState,
            reduce: { (i: State, e: Event) -> State in
                reducers.reduce(i, { (state: State, next: Reducer) in next(state, e) })
            },
            scheduler: MainScheduler.instance,
            feedback: { _ in dispatcher })
            .replay(1)
        
        state.connect().disposed(by: bag)
        
        self.state = state
        self.dispatcher = dispatcher
    }
    
    convenience init(initialState: State, reducers: Reducer...) {
        self.init(initialState: initialState, reducers: reducers)
    }
}
