import SwiftUI; import FirebaseCore; import FirebaseAnalytics; import FirebaseCrashlytics; class AppDelegate: NSObject, UIApplicationDelegate { func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool { FirebaseApp.configure(); Analytics.setAnalyticsCollectionEnabled(true); return true } }
