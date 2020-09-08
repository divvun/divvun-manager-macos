import Cocoa

class DownloadProgressView: View {
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var progressLabel: NSTextField!

    func updateProgressBar(current: UInt64, total: UInt64) {
        progressBar.minValue = 0
        progressBar.maxValue = Double(total)
        progressBar.doubleValue = Double(current)
    }
}
