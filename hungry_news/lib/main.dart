import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/preference_news_page.dart';
import 'pages/past_news_page.dart';
import 'pages/major_news_page.dart';
import 'pages/saved_news_page.dart';
import 'pages/search_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'isDarkMode', isDarkMode); // save user appearance choice
  }

  final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.orange[50],
    primaryColor: Colors.red[800],
    cardColor: Colors.white,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Colors.red[800]!,
      onPrimary: Colors.white,
      secondary: Colors.orange[700]!,
      onSecondary: Colors.white,
      surface: Colors.orange[
          50]!,
      onSurface:
          Colors.black87,
      error: Colors.red,
      onError: Colors.white,
      tertiary: Colors.orange[100]!,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black, fontSize: 18),
      bodyMedium:
          TextStyle(color: Colors.black, fontSize: 16),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.red[800],
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dividerColor: Colors.grey[300],
  );

  final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey[900],
    primaryColor: Colors.red[800],
    cardColor: Colors.grey[800]!,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.red[800]!,
      onPrimary: Colors.white,
      secondary: Colors.orange[700]!,
      onSecondary: Colors.white,
      surface: Colors.grey[800]!,
      onSurface: Colors.white,
      error: Colors.red,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
      bodyMedium: TextStyle(color: Colors.white, fontSize: 16),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.red[800],
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dividerColor: Colors.grey[700],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hungry News',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).removePadding(removeTop: true),
          child: child!,
        );
      },
      home: MyHomePage(
        onThemeChanged: toggleTheme,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const MyHomePage({super.key, required this.onThemeChanged});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 2; //  Major News page by default

  List<Widget> _pages(BuildContext context) => [
        const PreferenceNewsPage(),
        // PastNewsPage(testDate: DateTime(2024, 11, 10)),
        const PastNewsPage(),
        const MajorNewsPage(),
        const SavedNewsPage(),
        const SearchNewsPage(),
        SettingsPage(
          onThemeChanged: widget.onThemeChanged, //  callback to SettingsPage
        ),
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
        preferredSize: Size.zero,
        child: Container(),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages(context),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Preference'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Past News'),
          BottomNavigationBarItem(
              icon: Icon(Icons.public), label: 'Major News'),
          BottomNavigationBarItem(icon: Icon(Icons.save), label: 'Saved News'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
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
