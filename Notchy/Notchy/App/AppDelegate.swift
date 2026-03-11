import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let runningApps = NSWorkspace.shared.runningApplications
        let myBundleId = Bundle.main.bundleIdentifier ?? ""
        if runningApps.filter({ $0.bundleIdentifier == myBundleId }).count > 1 {
            NSApp.terminate(nil)
            return
        }
    }
}
