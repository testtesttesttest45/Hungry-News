import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const SettingsPage({super.key, required this.onThemeChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _isDarkMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // safe access theme context
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                child: Container(
                  height: 160,
                  color: Colors.red[800],
                  padding: const EdgeInsets.only(
                    top: 40.0,
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Appearance',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        DropdownButton<String>(
                          value: _isDarkMode ? "Dark" : "Burger",
                          items: const [
                            DropdownMenuItem(
                                value: "Burger", child: Text("Burger")),
                            DropdownMenuItem(
                                value: "Dark", child: Text("Dark")),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _isDarkMode = value == "Dark";
                              widget.onThemeChanged(_isDarkMode);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Inspired by Hungry Jacks Burgers',
                      style:
                          Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 500),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 12.0),
                      ),
                      child: const Text(
                        'Reset App',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 160.0;
  @override
  double get minExtent => 160.0;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
