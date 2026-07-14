import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/mini_player.dart';

class RootScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RootScreen({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => _onTap(context, index),
            backgroundColor: Colors.black,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
              BottomNavigationBarItem(icon: Icon(Icons.library_music), label: "Library"),
            ],
          ),
        ],
      ),
    );
  }
}
