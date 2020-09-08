import Cocoa

protocol Nibbable {}

class View: NSView, Nibbable {}
class ViewController<T: View>: NSViewController {
    let contentView = T.loadFromNib()
    
    override func loadView() {
        view = contentView
    }
    
    required init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Window: NSWindow, Nibbable {
}

func setAssociatedObject<T>(_ object: Any, _ ptr: UnsafeRawPointer, value: T, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN) {
    objc_setAssociatedObject(object, ptr, value, policy)
}

func getAssociatedObject<T>(_ object: Any, _ ptr: UnsafeRawPointer) -> T? {
    return objc_getAssociatedObject(object, ptr) as? T
}

extension NSObject {
    func setAssociatedObject<T>(_ ptr: UnsafeRawPointer, value: T, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN) {
        objc_setAssociatedObject(self, ptr, value, policy)
    }

    func setAssociatedObject<T>(_ key: Selector, value: T, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN) {
        let keyObject = key as AnyObject
        let unmanagedKey = Unmanaged.passUnretained(keyObject)
        let ptr = unmanagedKey.toOpaque()
        objc_setAssociatedObject(self, ptr, value, policy)
    }

    func getAssociatedObject<T>(_ ptr: UnsafeRawPointer) -> T? {
        return objc_getAssociatedObject(self, ptr) as? T
    }

    func getAssociatedObject<T>(_ key: Selector) -> T? {
        let ptr = Unmanaged.passUnretained(key as AnyObject).toOpaque()
        return objc_getAssociatedObject(self, ptr) as? T
    }
    
    func removeAssociatedObject(_ key: Selector, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN) {
        let ptr = Unmanaged.passUnretained(key as AnyObject).toOpaque()
        return objc_setAssociatedObject(self, ptr, nil, policy)
    }
}


class WindowController<T: Window>: NSWindowController {
    static var windowNibPath: String { return T.nibPath }
    
    let contentWindow = T.loadFromNib()
    
    var viewController: NSViewController? {
        didSet {
            if let v = viewController {
                contentWindow.contentView = v.view
                contentWindow.bind(.title, to: v, withKeyPath: "title", options: nil)
            } else {
                contentWindow.contentView = nil
                contentWindow.unbind(.title)
            }
        }
    }
    
    required init() {
        super.init(window: contentWindow)
        let name = T.nibPath
        self.shouldCascadeWindows = false
        contentWindow.setFrameUsingName(name)
        contentWindow.setFrameAutosaveName(name)
        self.windowWillLoad()
        self.windowDidLoad()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NSMenu: Nibbable {}
extension Nibbable where Self: NSUserInterfaceItemIdentification {
    static var nibPath: String {
        return String(describing: self)
    }
    
    static func loadFromNib(path nibPath: String = Self.nibPath) -> Self {
        let bundle = Bundle(for: Self.self)
        
        var views: NSArray? = NSArray()
        
        if let nib = NSNib(nibNamed: nibPath, bundle: bundle) {
            nib.instantiate(withOwner: nil, topLevelObjects: &views)
        }
        
        guard let view = views?.first(where: { $0 is Self }) as? Self else {
            fatalError("Nib could not be loaded for nibPath: \(nibPath); check that the Custom Class for the XIB has been set to the given view: \(self)")
        }
        
        return view
    }
}


