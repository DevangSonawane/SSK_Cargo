import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAZLoTImMEkucAQT8xTkv_M3gdEVIS_HYw")
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let shareChannel = FlutterMethodChannel(
        name: "plugins.flutter.io/share",
        binaryMessenger: controller.binaryMessenger
      )
      shareChannel.setMethodCallHandler { call, result in
        if call.method == "downloadFile" {
          guard
            let args = call.arguments as? [String: Any],
            let data = args["bytes"] as? FlutterStandardTypedData
          else {
            result("")
            return
          }
          let fileName: String
          if let providedFileName = args["fileName"] as? String, !providedFileName.isEmpty {
            fileName = providedFileName
          } else {
            fileName = "invoice.pdf"
          }
          do {
            let documentsUrl = try FileManager.default.url(
              for: .documentDirectory,
              in: .userDomainMask,
              appropriateFor: nil,
              create: true
            )
            let fileUrl = documentsUrl.appendingPathComponent(fileName)
            try data.data.write(to: fileUrl, options: .atomic)
            result(fileUrl.lastPathComponent)
          } catch {
            result("")
          }
          return
        }
        if call.method == "shareFile" {
          guard
            let args = call.arguments as? [String: Any],
            let data = args["bytes"] as? FlutterStandardTypedData
          else {
            result(false)
            return
          }
          let fileName: String
          if let providedFileName = args["fileName"] as? String, !providedFileName.isEmpty {
            fileName = providedFileName
          } else {
            fileName = "invoice.pdf"
          }
          let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
          do {
            try data.data.write(to: tempUrl, options: .atomic)
            let activityController = UIActivityViewController(
              activityItems: [tempUrl],
              applicationActivities: nil
            )
            controller.present(activityController, animated: true) {
              result(true)
            }
          } catch {
            result(false)
          }
          return
        }
        guard call.method == "share" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard
          let args = call.arguments as? [String: Any],
          let text = args["text"] as? String,
          !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
          result(nil)
          return
        }
        let subject = args["subject"] as? String
        var items: [Any] = [text]
        if let subject, !subject.isEmpty {
          items.insert(subject, at: 0)
        }
        let activityController = UIActivityViewController(
          activityItems: items,
          applicationActivities: nil
        )
        controller.present(activityController, animated: true) {
          result(nil)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
