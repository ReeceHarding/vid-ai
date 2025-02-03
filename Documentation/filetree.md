AIVideoEditor/                             # Root folder for the project
├── AIVideoEditor.xcodeproj/               # Xcode project file folder
│   ├── project.pbxproj                    # Project build configuration and settings
│   └── project.xcworkspace                # Workspace file for managing multiple projects
├── AIVideoEditor/                         # Main application source folder
│   ├── AppDelegate.swift                  # Application delegate for app lifecycle events
│   ├── SceneDelegate.swift                # Scene delegate for managing multiple UI windows (iOS 13+)
│   ├── Config.swift                       # Configuration file for environment variables & API keys
│   ├── Models/                            # Data models corresponding to Firestore documents
│   │   ├── User.swift                     # Model representing a User with properties (userID, role, email, etc.)
│   │   ├── Video.swift                    # Model representing a Video with metadata and storage path
│   │   ├── Transcript.swift               # Model representing a Transcript with segments (startTime, endTime, text, etc.)
│   │   └── Annotation.swift               # Model for annotations, chapter markers, and SmartEdit logs
│   ├── Managers/                          # Manager classes that encapsulate service logic and API interactions
│   │   ├── AuthManager.swift              # Handles Firebase Authentication (login, signup, sign‑out)
│   │   ├── FirestoreManager.swift         # Encapsulates all Firestore CRUD operations for Users, Videos, Transcripts, etc.
│   │   ├── StorageManager.swift           # Manages Firebase Storage operations (uploads, downloads, resumable uploads)
│   │   ├── AnalyticsLogger.swift          # Wraps Firebase Analytics calls and logs custom events
│   │   ├── VideoProcessor.swift           # Processes video files using AVFoundation (loading, segmentation, stitching)
│   │   ├── AudioProcessor.swift           # Normalizes audio tracks using AVAudioMix and applies cross‑fades
│   │   ├── TranscriptionManager.swift     # Integrates with Google Cloud Speech‑to‑Text API for video transcription
│   │   ├── SmartEditProcessor.swift       # Central module to process SmartEdit commands (edit, undo, command queuing)
│   │   ├── NLPManager.swift               # Uses Apple’s Natural Language framework (and GPT fallback) for command parsing
│   │   ├── VoiceCommandManager.swift      # Integrates iOS Speech framework to capture and convert voice input to text
│   │   └── SynonymDictionary.swift        # Data structure mapping synonyms to canonical SmartEdit commands
│   ├── Views/                             # All SwiftUI (or UIKit) view files for the user interface
│   │   ├── ContentView.swift              # Main container view managing navigation between screens
│   │   ├── HomeView.swift                 # Displays the lecture list (grid or list) with search and filtering
│   │   ├── LectureCellView.swift          # Reusable component for individual lecture cells (thumbnail, metadata, status)
│   │   ├── LectureDetailView.swift        # Detailed view for a single lecture with full metadata and actions
│   │   ├── UploadView.swift               # Multi‑step view for video selection, metadata entry, and upload confirmation
│   │   ├── PlaybackView.swift             # Video playback screen with integrated AVFoundation player and interactive timeline
│   │   ├── SmartEditView.swift            # Interface for issuing SmartEdit commands (buttons, text field, feedback)
│   │   ├── ProfileView.swift              # Displays user profile details and account management options
│   │   ├── SettingsView.swift             # Allows toggling of notifications, feature flags, and app settings
│   │   ├── HelpView.swift                 # Contains FAQ, support contact form, and in‑app help documentation
│   │   └── DebugConsoleView.swift         # Developer-only view for real‑time logs, command history, and system metrics
│   ├── Resources/                         # Assets and other resource files
│   │   ├── Assets.xcassets/               # Xcode asset catalog for icons, images, and colors
│   │   ├── Images/                        # Additional image files used by the app (e.g., placeholder images)
│   │   ├── Fonts/                         # Custom fonts used in the UI
│   │   └── Localizable.strings            # Localization strings for multi‑language support
│   ├── Supporting Files/                  # Essential supporting files for app configuration
│   │   ├── Info.plist                     # App configuration and permission declarations (camera, microphone, etc.)
│   │   └── LaunchScreen.storyboard        # Launch screen storyboard for app startup
│   └── Utilities/                         # Helper functions, extensions, and custom logging utilities
│       ├── Extensions.swift               # Common Swift extensions for standard types and UI elements
│       ├── Logger.swift                   # Custom logger functions to supplement system logging
│       └── HelperFunctions.swift          # Utility functions for tasks like date formatting, string manipulation, etc.
├── Tests/                                 # Automated test files for the project
│   ├── AIVideoEditorTests/                # Unit and integration tests for core modules
│   │   ├── VideoProcessorTests.swift      # Tests for video segmentation, stitching, and transition effects
│   │   ├── AudioProcessorTests.swift      # Tests for audio normalization and cross‑fade effects
│   │   ├── SmartEditProcessorTests.swift  # Tests covering SmartEdit command processing and undo functionality
│   │   ├── TranscriptionManagerTests.swift# Tests for transcription API integration and JSON parsing
│   │   ├── FirestoreManagerTests.swift    # Tests for Firestore CRUD operations and data synchronization
│   │   └── UtilitiesTests.swift           # Tests for helper functions, logging, and extensions
│   └── AIVideoEditorUITests/               # UI tests to simulate user interactions and validate navigation flows
│       └── AIVideoEditorUITests.swift     # Comprehensive UI test suite for end‑to‑end user flows
├── Documentation/                         # Project documentation files and guides
│   ├── README.md                          # Overview of the project, setup instructions, and usage guidelines
│   ├── mermaid.md                         # Detailed guidelines and examples for creating and maintaining Mermaid diagrams
│   ├── tech_stack.md                      # Documentation of all technologies, frameworks, and dependencies used in the project
│   ├── project_architecture.md            # High‑level diagrams and explanations of the project’s overall architecture
│   ├── api_documentation.md               # Detailed API documentation for all external and internal endpoints
│   └── glossary.md                        # Glossary of terms and acronyms used throughout the project
├── Scripts/                               # Automation scripts for building, testing, deployment, and maintenance
│   ├── build.sh                           # Shell script for building the project from the command line
│   ├── test.sh                            # Script to run all unit, integration, and UI tests automatically
│   ├── deploy.sh                          # Script to deploy the app to test and production environments
│   ├── backup.sh                          # Script for triggering automated backups for Firestore and Firebase Storage
│   └── ci_cd.yml                          # CI/CD configuration file (e.g., GitHub Actions workflow) for automated builds and tests
├── .gitignore                             # File specifying which files and folders should be ignored by Git
└── LICENSE                                # Project license file (if applicable)