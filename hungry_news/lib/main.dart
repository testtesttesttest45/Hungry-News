import 'package:flutter/material.dart';
import 'pages/preference_news_page.dart';
import 'pages/past_news_page.dart';
import 'pages/major_news_page.dart';
import 'pages/saved_news_page.dart';
import 'pages/search_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hungry News',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        // Remove the top padding caused by the system status bar
        return MediaQuery(
          data: MediaQuery.of(context).removePadding(removeTop: true),
          child: child!,
        );
      },
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 2; // display Major News page by default

  static const List<Widget> _pages = [
    PreferenceNewsPage(),
    PastNewsPage(),
    // MajorNewsPage(), major news page has a parameter to set the current day for debug. pass currentDay: 2
    MajorNewsPage(),
    SavedNewsPage(),
    SearchPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        // title: Text(widget.title),
        preferredSize: Size.zero,
        child: Container(),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Preferences'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Past News'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Major News'),
          BottomNavigationBarItem(icon: Icon(Icons.save), label: 'Saved News'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  
}
