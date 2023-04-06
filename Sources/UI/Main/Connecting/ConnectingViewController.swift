class ConnectingViewController: ViewController<ConnectingView> {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Divvun Manager"
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            self?.contentView.updateView(state: .tooLong)
            Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { [weak self] _ in
                self?.contentView.updateView(state: .wayTooLong)
            }
        }
    }
}
