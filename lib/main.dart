import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'main_scaffold.dart'; 
import 'login_page.dart';
import 'create_profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null); 
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Syncory',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          
          // --- 🔥 ВОТ ИСПРАВЛЕНИЕ "МОРГАНИЯ" ---
          // 1. Показываем индикатор загрузки, пока Firebase "думает"
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // ---

          // 2. Если пользователь ЕСТЬ (он залогинен)
          if (authSnapshot.hasData) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(authSnapshot.data!.uid)
                  .snapshots(),
              builder: (context, profileSnapshot) {
                // (Пока ждем профиль, тоже показываем загрузку)
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // Если профиль есть
                if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
                  final data = profileSnapshot.data!.data() as Map<String, dynamic>;
                  if (data['isDisabled'] == true) {
                    FirebaseAuth.instance.signOut(); // Выкидываем забаненного
                    return LoginPage(
                      banMessage: 'Ваш аккаунт был отключен администратором.',
                    );
                  }
                  // Все ок, пускаем в приложение
                  return MainScaffold();
                } 
                // Если профиля нет (новый юзер, зашел через Google)
                else {
                  return CreateProfilePage();
                }
              },
            );
          } 
          // 3. Если пользователя НЕТ (он не залогинен)
          else {
            return LoginPage();
          }
        },
      ),
    );
  }
}