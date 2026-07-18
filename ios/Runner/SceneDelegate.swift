import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private let imageSaveDelegate = ImageSaveDelegate()

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "moniary/file_actions",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "saveImageToGallery" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let bytes = arguments["bytes"] as? FlutterStandardTypedData,
        let image = UIImage(data: bytes.data)
      else {
        result(false)
        return
      }
      self?.imageSaveDelegate.save(image, result: result)
    }
  }
}

private final class ImageSaveDelegate: NSObject {
  private var pendingResults: [FlutterResult] = []

  func save(_ image: UIImage, result: @escaping FlutterResult) {
    pendingResults.append(result)
    UIImageWriteToSavedPhotosAlbum(
      image,
      self,
      #selector(image(_:didFinishSavingWithError:contextInfo:)),
      nil
    )
  }

  @objc private func image(
    _ image: UIImage,
    didFinishSavingWithError error: Error?,
    contextInfo: UnsafeRawPointer
  ) {
    guard !pendingResults.isEmpty else { return }
    let result = pendingResults.removeFirst()
    result(error == nil)
  }
}
