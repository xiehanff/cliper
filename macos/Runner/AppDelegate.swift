import Cocoa
import FlutterMacOS
import ServiceManagement

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "launch_at_startup",
      binaryMessenger: controller.engine.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "launchAtStartupIsEnabled":
        result(LoginItemUtil.isEnabled())
      case "launchAtStartupSetEnabled":
        if let args = call.arguments as? [String: Any],
          let enabled = args["setEnabledValue"] as? Bool
        {
          do {
            if enabled {
              try LoginItemUtil.enable()
            } else {
              try LoginItemUtil.disable()
            }
            result(true)
          } catch {
            result(FlutterError(code: "SETUP_ERROR", message: error.localizedDescription, details: nil))
          }
        } else {
          result(
            FlutterError(
              code: "INVALID_ARGS", message: "Missing setEnabledValue", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    super.applicationDidFinishLaunching(notification)
  }
}

enum LoginItemUtil {
  static func isEnabled() -> Bool {
    if #available(macOS 13.0, *) {
      return SMAppService.mainApp.status == .enabled
    }
    return false
  }

  static func enable() throws {
    if #available(macOS 13.0, *) {
      try SMAppService.mainApp.register()
    }
  }

  static func disable() throws {
    if #available(macOS 13.0, *) {
      try SMAppService.mainApp.unregister()
    }
  }
}
