import Foundation
import WebKit

struct LanguageResponse: Encodable {
    let languageName: String
    var packages: [String: Descriptor]
    var size: String
    var installedSize: String
    var groupStatus: String
    var statuses: [String: String]
}

protocol WebBridgeViewable: class {
    func handle(error: Error)
}

class WebBridgeService: NSObject, WKScriptMessageHandler {
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    private lazy var defaultResponse = { try! jsonEncoder.encode("{}") }()
    
    private weak var webView: WKWebView?
    private weak var view: WebBridgeViewable?

    private var functions: WebBridgeFunctions? = nil
    
    init(webView: WKWebView, view: WebBridgeViewable) {
        self.webView = webView
        self.view = view
    }

    
    func start(url: URL, repo: LoadedRepository) {
        guard let webView = webView else { return }
        functions = WebBridgeFunctions(repo: repo)

        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.add(self, name: "pahkat")
        webView.load(URLRequest(url: url))
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
        
        print("Request: \(request)")
        
        var responseData: Data = defaultResponse
        
        do {
            responseData = try functions.process(request: request)
        } catch let error as ErrorResponse {
            responseData = try! jsonEncoder.encode(error)
        } catch {
            do {
                responseData = try jsonEncoder.encode(ErrorResponse(error: String(describing: error)))
            } catch {
                responseData = try! jsonEncoder.encode(ErrorResponse(error: "An unhandled error occurred"))
            }
        }
        
        let response = String(data: responseData, encoding: .utf8)!
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        let js = "window.pahkatResponders[\"callback-\(request.id)\"](\"\(response)\")"
        print(response)
        
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

}
