# AIVideoEditor Project Structure

```
AIVideoEditor/
├── Package.swift
├── Sources/
│   └── AIVideoEditor/
│       ├── Views/
│       │   └── ContentView.swift
│       ├── Models/
│       ├── Managers/
│       └── Resources/
├── Tests/
│   ├── AIVideoEditorTests/
│   │   └── ProjectSetupTests.swift
│   ├── AIVideoEditorUITests/
│   │   └── AppUITests.swift
│   └── TestHelpers/
│       ├── TestUtilities.swift
│       └── TestConfig.swift
├── Scripts/
│   ├── build.sh
│   └── test.sh
├── Documentation/
│   ├── filetree.md
│   ├── project_requirements.md
│   └── app_flow.md
├── Supporting Files/
│   ├── Info.plist
│   └── LaunchScreen.storyboard
├── README.md
└── LICENSE
```

## Directory Structure Overview

### Sources
- `Views/`: SwiftUI views and UI components
- `Models/`: Data models and business logic
- `Managers/`: Service layer and API integrations
- `Resources/`: Assets and configuration files

### Tests
- `AIVideoEditorTests/`: Unit tests
- `AIVideoEditorUITests/`: UI tests
- `TestHelpers/`: Shared test utilities and configuration

### Scripts
- `build.sh`: Project build script
- `test.sh`: Test execution script

### Documentation
- `filetree.md`: Project structure documentation
- `project_requirements.md`: Project requirements and specifications
- `app_flow.md`: Application flow diagrams and documentation

### Supporting Files
- `Info.plist`: Application configuration
- `LaunchScreen.storyboard`: Launch screen interface