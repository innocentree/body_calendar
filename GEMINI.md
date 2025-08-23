# GEMINI.md - Body Calendar

## Project Overview

**`body_calendar`** is a mobile application built with **Flutter** designed for logging and managing workouts. The app's core functionality revolves around a calendar interface that allows users to record and view their exercise history. It includes features for tracking workout details and viewing statistics to monitor progress. The application is developed in Korean.

The project uses a feature-driven directory structure and leverages a combination of popular packages for state management, data persistence, and UI components.

**Key Technologies:**

*   **Framework:** Flutter (Dart)
*   **State Management:** `flutter_bloc`, `provider`, `get_it`
*   **UI Components:** `table_calendar` for the main calendar view, `fl_chart` for statistics, and other packages like `lottie` for animations.
*   **Data Persistence:** `sqflite` for the local database and `shared_preferences` for simple key-value storage.
*   **Core Data:** A predefined list of exercises and their variations is stored in `assets/data/exercises.json`.

## Building and Running

### Prerequisites

*   Flutter SDK installed.
*   A configured emulator or a physical device.

### Running the App

To run the application in debug mode, use the following command:

```bash
flutter run
```

### Running Tests

To execute the unit and widget tests, run:

```bash
flutter test
```

## Project Structure

*   `lib/`: Contains all the Dart source code.
    *   `main.dart`: The main entry point of the application.
    *   `core/`: Shared code for themes, models, constants, and utilities.
    *   `features/`: Contains the primary features of the app, each in its own subdirectory.
        *   `calendar/`: The main screen of the app, displaying the workout calendar.
        *   `workout/`: The feature for logging and managing workout sessions.
        *   `statistics/`: The feature for displaying user's workout statistics.
    *   `shared/`: Contains shared models or widgets across different features.
*   `assets/`: Static assets used by the application.
    *   `data/exercises.json`: A crucial JSON file containing a structured list of exercises, categorized by body part, with details on variations, equipment, and default settings.
    *   `images/`, `icons/`, `animations/`: UI-related graphical assets.
*   `pubspec.yaml`: The project's manifest file, defining dependencies and metadata.
*   `test/`: Contains the tests for the application.

## Development Conventions

*   **Code Style:** The project follows the linting rules defined in `analysis_options.yaml`, which is based on `flutter_lints`.
*   **State Management:** The app primarily uses the **BLoC (Business Logic Component)** pattern for managing state, separating business logic from the UI. `GetIt` is likely used for service location and dependency injection.
*   **Data Handling:** Workout data is persisted locally using an SQLite database. The initial exercise data is loaded from the `exercises.json` asset.
*   **Localization:** The app is configured for localization using `flutter_intl`, with Korean (`ko`) as the primary language.
