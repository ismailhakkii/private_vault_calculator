# 🔒 Private Vault

A secure Flutter application that disguises itself as a calculator while protecting your private content behind a PIN.

## 📱 Features

- 🧮 **Calculator Disguise**: App appears as a normal calculator
- 🗝️ **Secure Access**: PIN protection for your private content
- 🌓 **Dark/Light Mode**: Customizable app appearance
- 🔄 **User-Friendly Onboarding**: Easy setup experience
- 🛡️ **Secret Area**: Securely store sensitive information

## 🏗️ Architecture

This project implements **Clean Architecture** principles for maintainable, testable code:

```
lib/
├── app/                  # App-level configurations
├── core/                 # Core utilities and constants
├── data/                 # Data sources, repositories implementations
├── domain/               # Business logic, entities, repository interfaces
└── presentation/         # UI components and state management
    ├── pages/            # App screens
    │   ├── calculator/   # Calculator disguise screen
    │   ├── onboarding/   # First-time user experience
    │   └── secret_area/  # Protected content area
    ├── widgets/          # Reusable UI components
    └── providers/        # State management
```

## 🛠️ Technologies & Packages

- **State Management**: [Riverpod](https://riverpod.dev/) for reactive and testable state management
- **Local Storage**: SharedPreferences for persisting user settings
- **Routing**: Custom route generation
- **UI Theming**: Custom light and dark themes

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (2.0.0 or higher)
- Dart SDK (2.12.0 or higher)

### Installation

1. Clone the repository
   ```
   git clone https://github.com/ismailhakkii/private_vault.git
   ```

2. Navigate to project directory
   ```
   cd private_vault
   ```

3. Install dependencies
   ```
   flutter pub get
   ```

4. Run the app
   ```
   flutter run
   ```

## 📋 Usage

1. Complete the onboarding process on first launch
2. Use the calculator interface for basic calculations
3. Enter your secret PIN to access the protected vault area
4. Toggle between light and dark modes in settings

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

- **İsmail Hakkı Kemikli** - [ismailhakkii](https://github.com/ismailhakkii)

---

⭐️ If you found this project helpful, please give it a star on GitHub! ⭐️
