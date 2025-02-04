# Services

This directory contains service classes that handle business logic and external integrations. Each service is designed to be modular and follows the Single Responsibility Principle.

## Service Overview

### AuthenticationService
- Handles user authentication using Firebase Auth
- Manages user sessions and role-based access
- Provides methods for login, signup, and logout

### FirestoreService
- Manages all Firestore database operations
- Provides CRUD operations for all models
- Handles data validation and error handling

### StorageService
- Manages Firebase Storage operations
- Handles video file uploads and downloads
- Implements resumable upload functionality

### VideoProcessingService
- Handles video processing using AVFoundation
- Manages video segmentation and editing
- Implements overlay generation and insertion

### TranscriptionService
- Integrates with Google Cloud Speech-to-Text
- Manages audio extraction and transcription
- Handles transcript segmentation

### AnalyticsService
- Manages Firebase Analytics integration
- Tracks user events and app usage
- Provides crash reporting via Crashlytics

## Usage Guidelines

1. Services should be accessed through dependency injection
2. All async operations should use Swift's async/await
3. Error handling should be consistent across services
4. Services should log important events for debugging
5. Each service should have corresponding unit tests 