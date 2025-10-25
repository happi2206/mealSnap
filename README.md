# MealSnap

MealSnap is a SwiftUI iOS 17 application for capturing meals, calculating personalised nutrition targets, and visualising progress across devices. The project uses Firebase Authentication, Firestore, and Storage, Swift Charts, SwiftData-style shared models, and a companion widget for quick glances.

## Features
- **Personalised onboarding** – Multi-step flow that captures demographics, activity level, and goals, computes BMI/BMR/TDEE using Mifflin-St Jeor, and stores an `AppPlan` locally and in Firestore.
- **Adaptive Today tab** – Animated calorie ring, macro snapshot, recent meals carousel, refreshable surface, and onboarding-aware greetings.
- **Add Meal workflow** – Live camera or photo-library input with mock detection list, steppers for adjusting grams, haptic feedback, and persistence to Firestore. Photos upload to Firebase Storage with download URLs stored alongside the meal.
- **Diary & insights** – Sectioned meal log, meal detail editing, delete support, and a weekly calorie bar chart powered by Swift Charts.
- **Settings** – Daily goal slider (syncs with the stored plan), unit preferences, toggles, and a “Recalculate Plan” action that reopens onboarding.
- **Dark premium styling** – Custom gradients, glassmorphism cards, accent purple palette, reusable components (`PrimaryButton`, `Card`, `MacroPill`, etc.).
- **Home Screen Widget** – Small/medium and accessory variants showing today’s caloric progress, macro bars, and last meal. Widget data is bridged via an app group and updates when meals or plans change.
- **Firebase-backed authentication** – Email/password login and signup, profile creation, Firestore-backed user profile, and plan management.
- **Unit tests** – XCTest suites covering calculator logic, onboarding validation, meal macro aggregation, and widget payload encoding.

## Project Structure
- `mealSnap/` – Application source (models, services, shared components, SwiftUI views, view models).
- `mealSnapWidget/` – Widget extension sharing model payloads via app group defaults.
- `mealSnapTests/` – XCTest targets (calculator, onboarding, widget payload, meal totals).
- `Shared/WidgetPayload.swift` – Codable payload used by both app and widget, mirrored in the widget target for independence.

## Requirements
- Xcode 15.0 or newer (iOS 17 SDK required for widgets and Swift Charts).
- macOS 13 Ventura or later recommended.
- Swift 5.9 features (`Observation`, new `Testing` allowed but we use XCTest).
- Firebase iOS SDK (installed via Swift Package Manager in `mealSnap.xcodeproj`).
- A valid Firebase project with Email/Password auth enabled and a matching `GoogleService-Info.plist`.
- iOS device running iOS 17+ for real-device testing (camera access, Health, and widget previews look best on hardware).

## Setup
1. **Clone** the repository.
2. **Open** `mealSnap.xcodeproj` (workspace is not required because SPM packages are integrated directly).
3. **Install Firebase config**:
   - Sign in to [Firebase Console](https://console.firebase.google.com/), create an iOS app with the bundle identifier used in the project.
   - Download `GoogleService-Info.plist` and replace the placeholder in `mealSnap/`.
   - Ensure the Firebase SDKs (Auth, Core, Firestore, Storage) are resolved by SPM (Xcode downloads them automatically).
4. **Configure App Group**:
   - The widget and app share data via `group.com.advancediOS.mealsnap`. Update both the app and widget entitlements if you use a different team or bundle id.
5. **Run** `Cmd+B` to build. Resolve any signing warnings by selecting your Apple Developer team in project settings.

## Running the App
### Simulator
1. Choose scheme **mealSnap**.
2. Select an iOS 17+ simulator (e.g. iPhone 15 Pro).
3. `Cmd+R` builds and runs. The onboarding flow appears on first launch.

### Real Device
1. Connect an iPhone running iOS 17+.
2. In Xcode, select your device from the run destination.
3. Under *Signing & Capabilities*, ensure the bundle identifier is unique and your Apple ID team is selected for both app and widget targets.
4. Trust the developer certificate on device if prompted.
5. Run (`Cmd+R`). Camera integration and widgets work best on a real device; you can add the widget directly from the Home Screen once the app has run once.

### Firebase Auth & Storage
1. Launch the app and use the Login screen to create an account. Credentials are stored via Firebase Auth.
2. Meal captures upload images to Firebase Storage (under `meals/<uid>/<uuid>.jpg`) and persist download URLs in Firestore.
3. Firestore collections:
   - `users/<uid>` – plan details and onboarding state.
   - `users/<uid>/meals/<meal-id>` – each meal entry with macro aggregates and `photoURL`.

## Home Screen Widget
- Ensure the app runs once to populate the shared app group defaults.
- On device or simulator Home Screen:
  - Long press, tap `+`, search “MealSnap”, and add the small or medium widget.
- Widget updates:
  - Saving meals or updating plans triggers `WidgetBridge.update`, which reloads timelines.
  - Widget uses a dark gradient design that fills the container on iOS 17+.

## Machine Learning
- Contains placeholder Core ML models (`FoodClassifier_CPU.mlmodel`, `food_classifier.mlmodel`) for future on-device detection. The UI currently uses mock detections but is structured to receive real predictions.

## Unit Tests
- Located in `mealSnapTests/`.
- Suites: `CalculatorTests`, `OnboardingViewModelTests`, `MealEntryTotalsTests`, `WidgetPayloadTests`.
- Run via `Cmd+U` in Xcode or CLI:
  ```bash
  xcodebuild test -scheme mealSnap -destination 'platform=iOS Simulator,name=iPhone 15'
  ```

## Troubleshooting
- **Firebase configuration errors**: Check that the bundle ID matches the Firebase app and that `GoogleService-Info.plist` is included in the main target.
- **Authentication issues**: Ensure email/password auth is enabled in Firebase console.
- **Widget not updating**: Confirm the app group ID matches entitlements and that a meal has been logged to populate the payload.
- **Photo uploads failing**: Verify Firebase Storage rules allow authenticated users to write to `meals/<uid>/`.
- **Real-device build failures**: Select a unique bundle identifier, enable automatic signing, and trust the certificate on device.

## Roadmap Ideas
- Integrate real Core ML detection pipeline for food recognition.
- HealthKit read/write (currently deferred).
- Background refresh for widget via App Intents or background tasks.
- Multi-user sharing and additional analytic charts.

Enjoy snapping meals with MealSnap! Contributions and suggestions are welcome.
