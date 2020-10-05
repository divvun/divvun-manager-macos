import Foundation
import WebKit
import RxSwift

struct LanguageResponse: Encodable {
    let languageName: String
    var packages: [String: Descriptor]
    var size: String
    var installedSize: String
    var groupStatus: String
    var statuses: [String: String]
}

protocol WebBridgeViewable: class {
    func toggleProgressIndicator(_ isVisible: Bool)
    func handle(error: Error)
}

class WebBridgeService: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    private let bag = DisposeBag()

    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    private lazy var defaultResponse = { try! jsonEncoder.encode("{}") }()
    
    private weak var webView: WKWebView?
    private weak var view: WebBridgeViewable?

    private var functions: WebBridgeFunctions? = nil

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.view?.toggleProgressIndicator(false)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        log.error(error)
        self.view?.toggleProgressIndicator(false)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        log.error(error)
        self.view?.toggleProgressIndicator(false)
    }
    
    init(webView: WKWebView, view: WebBridgeViewable) {
        self.webView = webView
        self.view = view

        super.init()

        webView.navigationDelegate = self
    }

    func start(url: URL, repo: LoadedRepository) {
        guard let webView = webView else { return }
        functions = WebBridgeFunctions(repo: repo)

        webView.configuration.userContentController.removeAllUserScripts()

        let name = "pahkat"
        webView.configuration.userContentController.removeScriptMessageHandler(forName: name)
        webView.configuration.userContentController.add(self, name: name)

        // force the url to reload in case it's cached/being stubborn
        let unixEpoch = String(Date().timeIntervalSince1970 * 1000)
        let reloadItem = URLQueryItem(name: "ts", value: unixEpoch)
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [reloadItem]

        view?.toggleProgressIndicator(true)

        guard let reloadUrl = urlComponents?.url else {
            log.error("Problem making force-reload url for \(url)")
            webView.load(URLRequest(url: url))
            return
        }

        webView.load(URLRequest(url: reloadUrl))
    }

    private func sendResponse(request: WebBridgeRequest, responseData: Data) {
        let response = String(data: responseData, encoding: .utf8)!
            .replacingOccurrences(of: "\"", with: "\\\"")

        let js = "window.pahkatResponders[\"callback-\(request.id)\"](\"\(response)\")"
        log.debug(response)

        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage)
    {
        if message.name != "pahkat" {
            return
        }
        
        guard let p = message.body as? String, let payload = p.data(using: .utf8) else {
            return
        }
        
        let request: WebBridgeRequest
        do {
            request = try jsonDecoder.decode(WebBridgeRequest.self, from: payload)
        } catch {
            log.error(error)
            return
        }

        guard let functions = functions else {
            log.error("No functions set!")
            return
        }
        
        log.debug("Request: \(request)")

        functions.process(request: request).subscribe(
            onSuccess: { [weak self] data in
                guard let `self` = self else { return }
                self.sendResponse(request: request, responseData: data)
            },
            onError: { [weak self] error in
                guard let `self` = self else { return }
                let responseData: Data

                if let error = error as? ErrorResponse {
                    responseData = try! self.jsonEncoder.encode(error)
                } else {
                    do {
                        responseData = try self.jsonEncoder.encode(ErrorResponse(error: String(describing: error)))
                    } catch {
                        responseData = try! self.jsonEncoder.encode(ErrorResponse(error: "An unhandled error occurred"))
                    }
                }

                self.sendResponse(request: request, responseData: responseData)
            }).disposed(by: bag)
    }

}
