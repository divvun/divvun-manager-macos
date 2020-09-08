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
    func handle(error: Error)
}

class WebBridgeService: NSObject, WKScriptMessageHandler {
    private let bag = DisposeBag()

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

        let name = "pahkat"
        webView.configuration.userContentController.removeScriptMessageHandler(forName: name)
        webView.configuration.userContentController.add(self, name: name)

        // force the url to reload in case it's cached/being stubborn
        let unixEpoch = String(Date().timeIntervalSince1970 * 1000)
        let reloadItem = URLQueryItem(name: "ts", value: unixEpoch)
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [reloadItem]
        guard let reloadUrl = urlComponents?.url else {
            print("Problem making force-reload url for \(url)")
            webView.load(URLRequest(url: url))
            return
        }

        webView.load(URLRequest(url: reloadUrl))
    }

    private func sendResponse(request: WebBridgeRequest, responseData: Data) {
        let response = String(data: responseData, encoding: .utf8)!
            .replacingOccurrences(of: "\"", with: "\\\"")

        let js = "window.pahkatResponders[\"callback-\(request.id)\"](\"\(response)\")"
        print(response)

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
        
        print("Request: \(request)")


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
        
//        do {
//            responseData = try functions.process(request: request)
//        } catch let error as ErrorResponse {
//            responseData = try! jsonEncoder.encode(error)
//        } catch {
//            do {
//                responseData = try jsonEncoder.encode(ErrorResponse(error: String(describing: error)))
//            } catch {
//                responseData = try! jsonEncoder.encode(ErrorResponse(error: "An unhandled error occurred"))
//            }
//        }
    }

}
