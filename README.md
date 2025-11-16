# Synqory

<div align="center">

**A modern social platform for finding partners and collaborators based on shared interests**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg?style=for-the-badge)](https://www.gnu.org/licenses/gpl-3.0)

[🐛 Report Bug](https://github.com/ungernthabaron/Synqory-flutter-app/issues) • [💡 Request Feature](https://github.com/ungernthabaron/Synqory-flutter-app/issues)

[Русская версия](#русская-версия) | English

</div>

---

## 🚀 About

**Synqory** is a cross-platform Flutter Web app built with Firebase that connects people through shared interests. Looking for a gaming partner? Want to discuss data analysis? Planning an event? Synqory helps you find your squad through smart category matching.

### ✨ Key Features

- 🎯 **Dynamic Feed** — Create and browse posts (Discussions or Events)
- 🏷️ **Category Matching** — Filter by interests: `flutter`, `data`, `gamedev`, `art`, `music`, etc.
- 🤝 **Application System** — Apply to join posts and get approved by authors
- 💬 **Private Comments** — Restrict comments to approved participants only
- 👤 **Interactive Profiles** — User profiles with interests, bookmarks, and activity
- 🛡️ **Admin Panel** — Manage users, delete posts, curate categories

---

## 🛠 Tech Stack

```
Frontend:  Flutter (Web) + Material 3
Backend:   Firebase (Auth, Firestore)
UI/UX:     google_fonts, flutter_animate
Auth:      Email/Password, Google Sign-In
```

---

## 🏁 Quick Start

### Prerequisites

- Flutter SDK (3.0+)
- Firebase account
- Google Cloud Console account (for Google Sign-In)

### Installation

```bash
# Clone the repo
git clone https://github.com/ungernthabaron/Synqory-flutter-app.git
cd Synqory-flutter-app

# Install dependencies
flutter pub get

# Setup Firebase
npm install -g firebase-tools
dart pub global activate flutterfire_cli
flutterfire configure

# Run the app
flutter run -d chrome
```

### Firebase Setup

1. Create a project in [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication (Email/Password and Google)
3. Enable Firestore Database
4. Create required indexes (the app will provide links in Debug Console)

### Google Sign-In Setup

1. Create OAuth 2.0 Client ID in [Google Cloud Console](https://console.cloud.google.com)
2. Add authorized origins:
   - `http://localhost` (development)
   - `https://your-project.web.app` (production)
3. Add to `web/index.html`:
   ```html
   <meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
   ```

---

## 🚀 Deploy

```bash
# Build for web
flutter build web

# Deploy to Firebase Hosting
firebase init hosting
firebase deploy
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0**. See [LICENSE](LICENSE) for details.

---

## 📧 Contact

**Project Author** — [@ungernthabaron](https://github.com/ungernthabaron)

**Project Link** — [https://github.com/ungernthabaron/Synqory-flutter-app](https://github.com/ungernthabaron/Synqory-flutter-app)

---

<div align="center">

**Made with ❤️ using Flutter**

⭐ Star this repo if you like it!

</div>

---

# Русская версия

<div align="center">

**Современная социальная платформа для поиска партнеров и единомышленников по общим интересам**

</div>

## 🚀 О проекте

**Synqory** — это кросс-платформенное приложение на Flutter и Firebase для объединения людей с общими интересами. Ищете напарника для игр? Хотите обсудить анализ данных? Планируете мероприятие? Synqory поможет найти "своих" через умный подбор по категориям.

### ✨ Основные функции

- 🎯 **Динамическая лента** — Создавайте и просматривайте посты (Обсуждения или Мероприятия)
- 🏷️ **Мэтчинг по категориям** — Фильтруйте по интересам: `flutter`, `data`, `gamedev`, `art`, `music` и др.
- 🤝 **Система заявок** — Подавайте заявки на участие, получайте одобрение от авторов
- 💬 **Приватные комментарии** — Ограничьте комментарии только для одобренных участников
- 👤 **Интерактивные профили** — Профили с интересами, закладками и активностью
- 🛡️ **Админ-панель** — Управление пользователями, постами и категориями

---

## 🛠 Технологии

```
Frontend:  Flutter (Web) + Material 3
Backend:   Firebase (Auth, Firestore)
UI/UX:     google_fonts, flutter_animate
Auth:      Email/Пароль, Google Sign-In
```

---

## 🏁 Быстрый старт

### Требования

- Flutter SDK (3.0+)
- Аккаунт Firebase
- Аккаунт Google Cloud Console (для Google Sign-In)

### Установка

```bash
# Клонируйте репозиторий
git clone https://github.com/ungernthabaron/Synqory-flutter-app.git
cd Synqory-flutter-app

# Установите зависимости
flutter pub get

# Настройте Firebase
npm install -g firebase-tools
dart pub global activate flutterfire_cli
flutterfire configure

# Запустите приложение
flutter run -d chrome
```

### Настройка Firebase

1. Создайте проект в [Firebase Console](https://console.firebase.google.com)
2. Включите Authentication (Email/Password и Google)
3. Включите Firestore Database
4. Создайте необходимые индексы (приложение подскажет ссылки в Debug Console)

### Настройка Google Sign-In

1. Создайте OAuth 2.0 Client ID в [Google Cloud Console](https://console.cloud.google.com)
2. Добавьте разрешенные источники:
   - `http://localhost` (разработка)
   - `https://your-project.web.app` (продакшн)
3. Добавьте в `web/index.html`:
   ```html
   <meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
   ```

---

## 🚀 Деплой

```bash
# Соберите web-версию
flutter build web

# Задеплойте на Firebase Hosting
firebase init hosting
firebase deploy
```

---

## 🤝 Вклад в проект

Мы приветствуем вклад в развитие! Создавайте Pull Request.

1. Форкните проект
2. Создайте ветку (`git checkout -b feature/AmazingFeature`)
3. Закоммитьте изменения (`git commit -m 'Add some AmazingFeature'`)
4. Запушьте ветку (`git push origin feature/AmazingFeature`)
5. Откройте Pull Request

---

## 📄 Лицензия

Проект распространяется под лицензией **GNU General Public License v3.0**. Подробности в [LICENSE](LICENSE).

---

## 📧 Контакты

**Автор проекта** — [@ungernthabaron](https://github.com/ungernthabaron)

**Ссылка на проект** — [https://github.com/ungernthabaron/Synqory-flutter-app](https://github.com/ungernthabaron/Synqory-flutter-app)

---

<div align="center">

**Сделано с ❤️ на Flutter**

⭐ Поставьте звезду, если проект понравился!

</div>
