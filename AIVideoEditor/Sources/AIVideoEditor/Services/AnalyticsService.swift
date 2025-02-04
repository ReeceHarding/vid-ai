import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics

enum AnalyticsEvent {
    case videoUploadStarted(videoId: String)
    case videoUploadCompleted(videoId: String)
    case videoUploadFailed(videoId: String, error: String)
    case videoProcessingStarted(videoId: String)
    case videoProcessingCompleted(videoId: String)
    case videoProcessingFailed(videoId: String, error: String)
    case transcriptionStarted(videoId: String)
    case transcriptionCompleted(videoId: String)
    case transcriptionFailed(videoId: String, error: String)
    case smartEditCommandExecuted(command: String, videoId: String)
    case smartEditCommandFailed(command: String, videoId: String, error: String)
    case videoPlaybackStarted(videoId: String)
    case videoPlaybackCompleted(videoId: String)
    case videoPlaybackSeeked(videoId: String, position: TimeInterval)
    case userSignedIn(userId: String, role: String)
    case userSignedOut(userId: String)
    
    var name: String {
        switch self {
        case .videoUploadStarted: return "video_upload_started"
        case .videoUploadCompleted: return "video_upload_completed"
        case .videoUploadFailed: return "video_upload_failed"
        case .videoProcessingStarted: return "video_processing_started"
        case .videoProcessingCompleted: return "video_processing_completed"
        case .videoProcessingFailed: return "video_processing_failed"
        case .transcriptionStarted: return "transcription_started"
        case .transcriptionCompleted: return "transcription_completed"
        case .transcriptionFailed: return "transcription_failed"
        case .smartEditCommandExecuted: return "smart_edit_command_executed"
        case .smartEditCommandFailed: return "smart_edit_command_failed"
        case .videoPlaybackStarted: return "video_playback_started"
        case .videoPlaybackCompleted: return "video_playback_completed"
        case .videoPlaybackSeeked: return "video_playback_seeked"
        case .userSignedIn: return "user_signed_in"
        case .userSignedOut: return "user_signed_out"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .videoUploadStarted(let videoId):
            return ["video_id": videoId]
        case .videoUploadCompleted(let videoId):
            return ["video_id": videoId]
        case .videoUploadFailed(let videoId, let error):
            return ["video_id": videoId, "error": error]
        case .videoProcessingStarted(let videoId):
            return ["video_id": videoId]
        case .videoProcessingCompleted(let videoId):
            return ["video_id": videoId]
        case .videoProcessingFailed(let videoId, let error):
            return ["video_id": videoId, "error": error]
        case .transcriptionStarted(let videoId):
            return ["video_id": videoId]
        case .transcriptionCompleted(let videoId):
            return ["video_id": videoId]
        case .transcriptionFailed(let videoId, let error):
            return ["video_id": videoId, "error": error]
        case .smartEditCommandExecuted(let command, let videoId):
            return ["command": command, "video_id": videoId]
        case .smartEditCommandFailed(let command, let videoId, let error):
            return ["command": command, "video_id": videoId, "error": error]
        case .videoPlaybackStarted(let videoId):
            return ["video_id": videoId]
        case .videoPlaybackCompleted(let videoId):
            return ["video_id": videoId]
        case .videoPlaybackSeeked(let videoId, let position):
            return ["video_id": videoId, "position": position]
        case .userSignedIn(let userId, let role):
            return ["user_id": userId, "role": role]
        case .userSignedOut(let userId):
            return ["user_id": userId]
        }
    }
}

class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    func logEvent(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
    
    func setUserProperties(userId: String, role: String) {
        Analytics.setUserID(userId)
        Analytics.setUserProperty(role, forName: "user_role")
        
        Crashlytics.crashlytics().setUserID(userId)
        Crashlytics.crashlytics().setCustomValue(role, forKey: "user_role")
    }
    
    func clearUserProperties() {
        Analytics.setUserID(nil)
        Analytics.setUserProperty(nil, forName: "user_role")
        
        Crashlytics.crashlytics().setUserID("")
        Crashlytics.crashlytics().setCustomValue("", forKey: "user_role")
    }
    
    func logError(_ error: Error, additionalInfo: [String: Any]? = nil) {
        var info = additionalInfo ?? [:]
        info["error_description"] = error.localizedDescription
        
        Crashlytics.crashlytics().record(error: error, userInfo: info)
    }
    
    func setCustomKey(_ key: String, value: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
} 