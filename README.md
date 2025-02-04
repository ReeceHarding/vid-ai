# AI Video Editor

An iOS application for educational content creators to edit and enhance video lectures using AI-powered tools.

## Features

- Upload and process educational videos
- Automatic transcription and segmentation
- Smart editing commands for quick modifications
- Role-based access (teachers and students)
- Real-time analytics and crash reporting

## Requirements

- iOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- macOS 13.0+ (for development)

## Dependencies

### Firebase
- FirebaseAnalytics: Analytics and user tracking
- FirebaseAuth: User authentication
- FirebaseFirestore: Database storage
- FirebaseFirestoreSwift: Swift integration for Firestore
- FirebaseStorage: Video file storage
- FirebaseCrashlytics: Crash reporting

### Networking
- Alamofire: HTTP networking

### Development
- SwiftLint: Code style enforcement

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ai-video-editor.git
cd ai-video-editor
```

2. Install dependencies using Swift Package Manager:
```bash
swift package resolve
```

3. Create a Firebase project and download `GoogleService-Info.plist`
4. Add `GoogleService-Info.plist` to the project
5. Open `AIVideoEditor.xcodeproj` in Xcode
6. Build and run the project

## Project Structure

```
AIVideoEditor/
├── Sources/
│   ├── AIVideoEditorApp/
│   │   └── App entry point
│   └── AIVideoEditorLib/
│       ├── Models/
│       ├── Views/
│       ├── Services/
│       ├── Core/
│       └── Resources/
├── Tests/
│   └── AIVideoEditorTests/
└── Package.swift
```

## Development

- Follow SwiftLint rules for code style
- Write unit tests for new features
- Update documentation when making changes
- Use semantic versioning for releases

## Testing

Run the test suite:
```bash
swift test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
