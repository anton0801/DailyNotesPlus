import SwiftUI
import WebKit


final class ViewHandler: NSObject {
    
    weak var controller: ViewController?
    var redirectCounter = 0
    var lastKnownURL: URL?
    let redirectThreshold = 70
    
    init(controller: ViewController) {
        self.controller = controller
        super.init()
    }
}

