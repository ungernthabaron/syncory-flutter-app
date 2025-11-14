Synq
Современная социальная платформа для поиска партнеров и единомышленников по общим интересам и категориям.

Read this in English: English Version

🚀 О Проекте
Synq — это кросс-платформенное приложение (Flutter Web), созданное на Flutter и Firebase. Его цель — объединять людей. Ищете ли вы напарника для видеоигр, хотите обсудить анализ данных или найти компанию для мероприятия, Synq помогает вам найти "своих" на основе конкретных категорий.

Этот проект демонстрирует быструю разработку с использованием Firebase, чистый UI на Material 3 и интерактивные ("живые") интерфейсы.

🔥 Ключевые Функции
Динамическая Лента: Создавайте и просматривайте посты (Обсуждения или Мероприятия).

Мэтчинг по Категориям: Фильтруйте ленту по категориям (напр., flutter, data, gamedev).

Система Заявок: Подавайте заявки на участие в постах и получайте одобрение от автора.

Приватные Комментарии: Авторы постов могут ограничить видимость комментариев (только для одобренных участников).

Интерактивные Профили: Профили пользователей с интересами, закладками и активностью (их посты).

Админ-панель: "Секретные" страницы для админа (бан пользователей, удаление постов, управление категориями).

Современная Аутентификация: Безопасный вход через Email/Пароль и Google Sign-In (Web).

🛠 Технический Стек
Фреймворк: Flutter (Web)

Бэкенд: Firebase (Authentication, Cloud Firestore)

UI/Анимации: Material 3, google_fonts, flutter_animate

Управление состоянием: StatefulWidget / StreamBuilder

🏁 Запуск у себя (Getting Started)
Чтобы запустить этот проект локально, вам понадобится:

Клонировать репозиторий:

Bash

git clone https://github.com/ungernthabaron/synq-flutter-app.git
Создать свой проект Firebase (это бесплатно).

Настроить Firebase (Web):

Следуйте инструкциям Firebase, чтобы получить firebase_options.dart (через flutterfire configure).

Настроить Google Sign-In (Web):

Создайте OAuth 2.0 Client ID в Google Cloud Console.

В "Authorized JavaScript origins" добавьте http://localhost (для теста) и ваш "живой" URL (напр., https://your-project.web.app).

В "Authorized redirect URIs" добавьте ваш "живой" URL (напр., https://your-project.web.app).

Добавьте <meta name="google-signin-client_id" ...> в web/index.html.

Настроить Firestore:

Создайте необходимые Индексы. Приложение само даст вам ссылки в консоли отладки (Debug Console) при первой попытке фильтрации.

Запустить приложение:

Bash

flutter pub get
flutter run -d chrome
📄 Лицензия
Этот проект распространяется по лицензии GNU General Public License v3.0. Подробности в файле LICENSE.

Synq (EN)
A modern social platform for finding partners and collaborators based on shared interests and categories.

🚀 About The Project
Synq is a cross-platform (Flutter Web) application built with Flutter and Firebase, designed to connect people. Whether you're looking for someone to play video games with, discuss data analysis, or join a real-world event, Synq helps you find your "squad" based on specific categories.

This project demonstrates rapid development using Firebase, a clean Material 3 UI, and interactive, "live" interfaces.

🔥 Key Features
Dynamic Feed: Create and browse posts (Discussions or Events).

Category Matching: Filter the feed by specific categories (e.g., flutter, data, gamedev).

Application System: Apply to join events/posts and get approved by the author.

Private Comments: Post authors can restrict comment visibility to approved participants only.

Interactive Profiles: User profiles with interests, bookmarks, and activity (their posts).

Admin Panel: Admin-only pages to manage users (ban), delete posts, and curate categories.

Modern Auth: Secure sign-in with Email/Password and Google Sign-In (Web).

🛠 Tech Stack
Framework: Flutter (Web)

Backend: Firebase (Authentication, Cloud Firestore)

UI/Animation: Material 3, google_fonts, flutter_animate

State Management: StatefulWidget / StreamBuilder

🏁 Getting Started
To run this project locally, you will need to:

Clone the repo:

Bash

git clone https://github.com/ungernthabaron/synq-flutter-app.git
Create your own Firebase project (it's free).

Setup Firebase (Web):

Follow the Firebase instructions to get your firebase_options.dart (use flutterfire configure).

Setup Google Sign-In (Web):

Create an OAuth 2.0 Client ID in the Google Cloud Console.

In "Authorized JavaScript origins," add http://localhost (for testing) and your live URL (e.g., https://your-project.web.app).

In "Authorized redirect URIs," add your live URL (e.g., https://your-project.web.app).

Add the <meta name="google-signin-client_id" ...> tag to web/index.html.

Setup Firestore:

Create the required Indexes. The app will provide the auto-generation links in the Debug Console when you first try to filter.

Run the app:

Bash

flutter pub get
flutter run -d chrome
📄 License
This project is licensed under the GNU General Public License v3.0. See the LICENSE file for details.
