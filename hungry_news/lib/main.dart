import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'pages/curated_news_page.dart';
import 'pages/past_news_page.dart';
import 'pages/major_news_page.dart';
import 'pages/saved_news_page.dart';
import 'pages/search_page.dart';
import 'pages/settings_page.dart';

import 'utils/utility.dart';

void main() {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Singapore'));
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
      surface: Colors.orange[100]!,
      onSurface: Colors.black87,
      error: Colors.red,
      onError: Colors.white,
      tertiary: Colors.orange[100]!,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black, fontSize: 18),
      bodyMedium: TextStyle(color: Colors.black, fontSize: 16),
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
      navigatorObservers: [CustomNavigatorObserver()],
    );
  }
}

class CustomNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);

    if (previousRoute == null) {
      // Back gesture used on the first page of a stack
      navigator?.pushReplacement(
          MaterialPageRoute(builder: (context) => const MajorNewsPage()));
    }
  }
}

class MyHomePage extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const MyHomePage({super.key, required this.onThemeChanged});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 2; // Major News page by default
  final GlobalKey<MajorNewsPageState> _majorNewsPageKey = GlobalKey();
  final GlobalKey<SavedNewsPageState> _savedNewsPageKey = GlobalKey();
  final GlobalKey<PastNewsPageState> _pastNewsPageKey = GlobalKey();
  final GlobalKey<CuratedNewsPageState> _curatedNewsPageKey = GlobalKey();

  GlobalKey<SearchNewsPageState> _searchNewsPageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _majorNewsPageKey.currentState?.unreadNewsCount
          .addListener(_updateUnreadNewsCount);
    });
  }

  @override
  void dispose() {
    _majorNewsPageKey.currentState?.unreadNewsCount
        .removeListener(_updateUnreadNewsCount);
    super.dispose();
  }

  void _updateUnreadNewsCount() {
    if (_majorNewsPageKey.currentState != null) {
      setState(() {});
    }
  }

  List<Widget> _pages(BuildContext context) => [
        CuratedNewsPage(key: _curatedNewsPageKey),
        PastNewsPage(key: _pastNewsPageKey),
        MajorNewsPage(key: _majorNewsPageKey),
        SavedNewsPage(key: _savedNewsPageKey),
        SearchNewsPage(key: _searchNewsPageKey),
        SettingsPage(
          onThemeChanged: widget.onThemeChanged,
          onResetApp: _resetAppCallback,
        ),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _resetAppCallback() {
    if (_majorNewsPageKey.currentState != null) {
      _majorNewsPageKey.currentState!.refreshPage();
    }

    if (_savedNewsPageKey.currentState != null) {
      _savedNewsPageKey.currentState!.resetSavedNews();
    }

    if (_pastNewsPageKey.currentState != null) {
      _pastNewsPageKey.currentState!.refreshPage();
    }

    if (_curatedNewsPageKey.currentState != null) {
      _curatedNewsPageKey.currentState!.refreshPage();
    }

    _searchNewsPageKey = GlobalKey<SearchNewsPageState>();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, void _) async {
        if (!didPop) {
          if (_selectedIndex != 2) {
            setState(() {
              _selectedIndex = 2; // redirect to Major News page
            });
          } else {
            // minimize the app when already on Major News
            try {
              const platform = MethodChannel('com.example.app/minimize');
              await platform.invokeMethod('moveTaskToBack');
            } catch (e) {
              debugPrint('Error minimizing the app: $e');
            }
          }
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.zero,
          child: Container(),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages(context),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.local_library),
              label: 'Curated News',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Past News',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.public, size: 24),
                  ValueListenableBuilder<int>(
                    valueListenable: NewsStateManager.unreadMajorNewsCount,
                    builder: (context, unreadCount, _) {
                      return unreadCount > 0
                          ? Positioned(
                              top: -4,
                              right: -20,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Center(
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox
                              .shrink(); // empty
                    },
                  ),
                ],
              ),
              label: 'Major News',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.save),
              label: 'Saved News',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}
