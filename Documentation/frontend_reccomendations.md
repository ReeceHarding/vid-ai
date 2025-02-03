Below is a set of comprehensive frontend guidelines tailored to the features and design principles outlined in the PRD for the AI Video Editor mobile app. These guidelines cover design, interaction, layout, and performance best practices to ensure a seamless, intuitive, and responsive user experience on iOS.

Frontend Guidelines for AI Video Editor for Educational Content

	Note: The following guidelines are designed for a native iOS application (iOS 14 and above) developed in Swift using either UIKit or SwiftUI. They adhere to the minimalistic, high-contrast (black-and-white) aesthetic specified in the PRD and cover key screens and interactions.

1. Design Principles & Visual Identity
	•	Minimalistic Aesthetic:
	•	Color Palette: Use a monochrome scheme with primary colors of black and white. Use grayscale variants for disabled states, backgrounds, and subtle accents.
	•	Typography: Adopt Apple’s San Francisco fonts with consistent use of font sizes and weights. Emphasize legibility for headers, labels, and captions.
	•	Iconography: Use simple, flat icons that align with the overall design language. Icons should be intuitive and support both light and dark modes if applicable.
	•	Spacing & Layout: Favor generous white space and clear visual separation between sections to maintain focus on content and functionality.
	•	Consistency:
	•	Ensure that typography, icons, colors, and component styles remain consistent across all screens.
	•	Apply a consistent visual language for interactions (e.g., buttons, toggles, progress indicators).

2. Screen-Specific UI & Layout Guidelines

2.1 Home / Library Screen
	•	Layout:
	•	Use a grid or list view to display lecture videos with thumbnail previews.
	•	Each item should include essential metadata (e.g., Title, Course Name, Lecture Date) and a small status indicator if processing is pending or completed.
	•	Search & Filtering:
	•	Include a prominently placed search bar at the top with auto-suggestions. Use a dynamic list that updates as the user types.
	•	Offer filtering options (by course, date, or topic) using dropdown menus or segmented controls.
	•	Interactions:
	•	Tapping on a lecture should navigate to a detailed view with additional metadata, processing status, and available actions (“Edit” for teachers and “Play” for students).
	•	Use subtle animations to indicate selection and transition between views.

2.2 Upload & Management Screen (Teacher Mode)
	•	Multi-Step Upload Flow:
	1.	Video Selection:
	•	Provide a clear “Select Video” button.
	•	Validate file formats (MP4, MOV) and size constraints (500 MB–1 GB) immediately upon selection.
	2.	Metadata Entry:
	•	Use form fields with placeholder text for mandatory fields (Title, Course Name, Lecture Date, Instructor Name).
	•	Incorporate a date picker for the Lecture Date and auto-suggestions for optional fields (Description, Tags, Keywords, Summary) based on previous entries.
	3.	Confirmation & Upload:
	•	Display a final confirmation screen summarizing the video details.
	•	Include a real-time progress indicator (spinner/progress bar) that updates at key milestones (e.g., 25%, 50%, 75%, 100%).
	•	Indicate offline status with a “pending” badge if connectivity is lost, and automatically resume once online.
	•	Feedback & Error Handling:
	•	Show clear error messages if validation fails or if the upload encounters connectivity issues.
	•	Offer options to retry or cancel the upload.

2.3 Video Processing & Playback Screen
	•	Processing View:
	•	Display a detailed progress screen with status labels such as “Transcribing,” “Analyzing Content,” “Stitching Video,” and “Enhancing Overlays.”
	•	Use real-time progress indicators (e.g., progress bars, spinners) that update frequently.
	•	Allow users to cancel or pause processing with clearly labeled buttons.
	•	Playback Interface:
	•	Video Player:
	•	Utilize native AVFoundation components to deliver smooth playback.
	•	Provide standard controls (play/pause, rewind, fast-forward) that respond within 100ms.
	•	Interactive Timeline:
	•	Overlay chapter markers and annotations on the timeline.
	•	Ensure that tapping a marker or a transcript line (in the synchronized transcript sidebar) jumps to the correct timestamp.
	•	Synchronized Transcript Sidebar:
	•	Implement a toggleable sidebar that auto-scrolls in sync with the video.
	•	Highlight the current transcript line and allow tapping to navigate directly to that segment.
	•	SmartEdit Command Integration:
	•	Display dedicated command buttons (e.g., “Remove awkward pause,” “Enhance lighting,” etc.) with clear icons.
	•	Support both text and voice input:
	•	Voice Input: Integrate with the iOS Speech framework for command capture.
	•	Text Input: Provide a text field that feeds into the NLP processing pipeline.
	•	Show immediate visual feedback (spinners, confirmation messages) and an “undo” button for recent changes.

2.4 Settings & Profile Screen
	•	User Settings:
	•	Offer account management options such as profile details, password changes, and notification preferences.
	•	Include toggles for advanced features (e.g., SmartEdit commands, adaptive playback recommendations).
	•	Help & Support:
	•	Integrate a help section with FAQs, contact forms, and in-app chat support.
	•	Use modal dialogs or dedicated screens to display support content.

3. Navigation & Overall Layout
	•	Bottom Navigation Bar:
	•	Include tabs for Library, Upload, Profile, and Settings.
	•	Ensure that each tab is clearly labeled with both an icon and text.
	•	Provide immediate visual feedback on tab selection (e.g., color change, underline).
	•	Responsive Layout:
	•	Respect safe areas and use Auto Layout (UIKit) or SwiftUI’s layout system to ensure responsiveness across different iPhone models.
	•	Maintain consistent margins and padding across all screens.
	•	Transitions & Animations:
	•	Use subtle animations for screen transitions, button presses, and interactive elements.
	•	Ensure that animations are smooth and do not impact performance or user perception.

4. User Interactions & Feedback
	•	Real-Time Feedback:
	•	Display spinners and progress bars during long-running operations (uploads, processing, transcription).
	•	Use toast notifications or banner alerts for success messages (e.g., “Upload complete”) and error messages (e.g., “Network error – upload will retry automatically”).
	•	Interactive Elements:
	•	Ensure all buttons, toggles, and input fields are clearly distinguishable.
	•	Provide touch feedback (e.g., subtle highlighting or scaling effects) on interactive elements.
	•	Incorporate accessibility labels for VoiceOver support.
	•	Error Handling:
	•	For critical actions (upload failures, processing errors), present actionable error messages that include guidance (e.g., “Check your internet connection and retry”).
	•	Allow users to easily retry operations without needing to restart the entire workflow.

5. Performance & Accessibility
	•	Performance:
	•	Aim for low-latency interactions (target under 100ms for UI responses).
	•	Optimize image and video rendering to ensure smooth playback and editing.
	•	Use asynchronous tasks and background processing where appropriate to avoid blocking the UI.
	•	Accessibility:
	•	Support dynamic type by allowing font sizes to adjust based on user settings.
	•	Ensure high contrast ratios in the black-and-white theme for readability.
	•	Provide VoiceOver labels and hints for all interactive elements.
	•	Use standard iOS accessibility APIs to ensure compatibility with assistive technologies.

6. Development & Testing Recommendations
	•	Component Reusability:
	•	Develop modular UI components (e.g., progress indicators, error banners, input forms) that can be reused across multiple screens.
	•	Unit & Integration Testing:
	•	Write unit tests for core UI components (e.g., form validation, progress update mechanisms).
	•	Implement integration tests to verify complete user flows from video selection to final playback.
	•	User Acceptance Testing (UAT):
	•	Conduct beta testing sessions with both teachers and students to gather feedback on UI/UX and performance.
	•	Iterate on the design based on UAT feedback, focusing on ease of use and error recovery.
	•	Code Reviews & Style Guidelines:
	•	Follow Swift best practices and coding style guidelines to ensure maintainability.
	•	Use Interface Builder (UIKit) or SwiftUI previews to rapidly iterate on designs.

7. Conclusion

These frontend guidelines ensure that every aspect of the AI Video Editor mobile app—from video uploads and processing feedback to interactive playback and SmartEdit command functionality—is designed with clarity, consistency, and performance in mind. By adhering to these principles, the development team can create a user-friendly, robust application that meets the high standards set out in the PRD while delivering an exceptional experience for both educators and students.

By following these guidelines, your frontend implementation will be well-aligned with the product’s overall vision, ensuring that every user interaction is intuitive, responsive, and aesthetically pleasing.