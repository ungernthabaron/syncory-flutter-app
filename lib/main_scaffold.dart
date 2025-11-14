import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'feed_page.dart';
import 'user_profile_page.dart';
import 'admin_users_page.dart';
import 'profile_page.dart';
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0; // Начинаем с "Фида" (индекс 0)

  // --- ПРОВЕРКА АДМИНА ---
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isAdmin = false;
  
  // --- СПИСОК СТРАНИЦ ---
  final List<Widget> _pages = <Widget>[
    FeedPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _setFeedAsDefault();
  }

  void _setFeedAsDefault() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() { _selectedIndex = 0; });
      }
    });
  }

  Future<void> _checkUserRole() async {
    if (_currentUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();
      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        if (mounted) {
          setState(() { _isAdmin = true; });
        }
      }
    } catch (e) {
      print("Error $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- 🔥 AppBar'а ЗДЕСЬ БОЛЬШЕ НЕТ ---
      
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        // --- 🔥 Мы немного "приглушим" нижнее меню ---
        // --- чтобы оно не спорило с левой колонкой на ПК ---
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        elevation: 0,
        // ---
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}