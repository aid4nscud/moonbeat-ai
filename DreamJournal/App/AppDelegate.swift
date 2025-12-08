import UIKit
import FBSDKCoreKit

/// AppDelegate for handling Facebook SDK initialization and deep links
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Facebook SDK
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        // Enable automatic event logging
        Settings.shared.isAutoLogAppEventsEnabled = true

        // Enable advertiser ID collection (requires ATT permission)
        Settings.shared.isAdvertiserIDCollectionEnabled = true

        #if DEBUG
        // Enable debug logging in debug builds
        Settings.shared.enableLoggingBehavior(.appEvents)
        #endif

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle Facebook deep links
        return ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[.sourceApplication] as? String,
            annotation: options[.annotation]
        )
    }
}
