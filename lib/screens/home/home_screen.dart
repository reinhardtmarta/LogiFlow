import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../feed/general_feed_screen.dart';
import '../search/search_screen.dart';
import '../seller/seller_dashboard.dart';
import '../consumer/marketplace_screen.dart';
import '../ai/ai_assistant_screen.dart';     // ← Nova

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    
    _screens = [
      GeneralFeedScreen(user: widget.user),           // Home Feed
      const SearchScreen(),                           // Search
      widget.user.isSeller 
          ? SellerDashboard(user: widget.user) 
          : MarketplaceScreen(user: widget.user),     // My Dashboard
      AiAssistantScreen(user: widget.user),           // ← Nova: Ask Gemma
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'My Space',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology),
            label: 'Gemma AI',
          ),
        ],
      ),
    );
  }
}
