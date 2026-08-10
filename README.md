# SpendSense

SpendSense is an intelligent, private expense tracking and personal finance application built with Flutter. It focuses on local-only data storage to ensure your financial data remains secure and entirely on your device.

## Key Features

- **Transaction Tracking**: Log your income and expenses with details like merchant, category, subcategory, payment mode, and date.
- **Budgeting**: Set and track monthly limits for different spending categories.
- **Automatic Insights**: View automatically generated insights such as your top spending categories, budget usage, and month-over-month comparisons.
- **Subscription Detection**: Automatically detects recurring subscriptions based on historical transaction data.
- **Interactive Dashboards & Charts**: View intuitive breakdowns of your finances using dynamic charts.
- **Merchant Overrides**: Customize category mappings for specific merchants to automatically classify future transactions.
- **CSV Export**: Export your complete transaction history to CSV format for external analysis.
- **Privacy First**: All data is stored locally on your device. No cloud syncing, no external servers.

## Tech Stack

SpendSense is built using the following core technologies and packages:

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: `provider`
- **Routing**: `go_router`
- **Local Storage**: `shared_preferences`
- **Data Visualization**: `fl_chart`
- **Responsiveness**: `sizer`
- **UI & Theming**: `google_fonts`, `flutter_svg`, `cupertino_icons`

## Project Structure

The project follows a feature-based folder structure within `lib/`:

- `/core`: App-wide utilities, constants, and global exports.
- `/services`: Core business logic including the `DatabaseService` (handling local storage via SharedPreferences) and `AppState`.
- `/theme`: Application theming and typography configurations.
- `/routes`: GoRouter setup and screen navigation.
- `/widgets`: Reusable, generic UI components used across multiple screens.
- `/presentation`: The main feature screens (Home, Dashboard, History, Profile, Onboarding). Each screen has its own widgets folder for local components.

## Getting Started

1. **Clone the repository** (or download the project folder).
2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the Application**:
   ```bash
   flutter run
   ```

## Note on Developer Mode
If you are on Windows, ensure that Developer Mode is enabled in your system settings to support symlinks which some plugins may require during build.
