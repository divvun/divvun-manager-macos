import Cocoa

@objc protocol LocalizationCompat {
    @objc var stringKey: String { get set }
}

@objc class CompatNSMenu: NSMenu, LocalizationCompat {
    @objc dynamic var stringKey: String = ""
}

@objc class CompatNSMenuItem: NSMenuItem, LocalizationCompat {
    @objc dynamic var stringKey: String = ""
}

