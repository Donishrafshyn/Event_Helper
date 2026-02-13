import 'package:flutter/material.dart';

import 'login.dart';

class EventHelperHome extends StatefulWidget {
  const EventHelperHome({super.key});

  @override
  State<EventHelperHome> createState() => _EventHelperHomeState();
}

class _EventHelperHomeState extends State<EventHelperHome> {
  // Corrected color palette to avoid 'emerald' and 'fuchsia' errors
  final List<Map<String, dynamic>> categories = [
    {'name': 'Decorators', 'icon': Icons.auto_awesome, 'color': Colors.pink, 'desc': 'Transform your venue'},
    {'name': 'Photographers', 'icon': Icons.camera_alt, 'color': Colors.blue, 'desc': 'Capture precious moments'},
    {'name': 'DJs', 'icon': Icons.music_note, 'color': Colors.purple, 'desc': 'Keep the party going'},
    {'name': 'Caterers', 'icon': Icons.restaurant, 'color': Colors.orange, 'desc': 'Delicious cuisines'},
    {'name': 'Sound Systems', 'icon': Icons.speaker, 'color': Colors.indigo, 'desc': 'Crystal clear audio'},
    {'name': 'Videographers', 'icon': Icons.videocam, 'color': Colors.teal, 'desc': 'Professional videos'},
    {'name': 'Makeup Artists', 'icon': Icons.palette, 'color': Colors.pinkAccent, 'desc': 'Look your best'},
    {'name': 'Venues', 'icon': Icons.location_on, 'color': Colors.tealAccent, 'desc': 'Perfect locations'},
    {'name': 'Anchoring', 'icon': Icons.mic_external_on, 'color': Colors.deepPurple, 'desc': 'Professional hosts'},
    {'name': 'Dance Events', 'icon': Icons.celebration, 'color': Colors.pinkAccent, 'desc': 'Dance performances'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeBanner(),
                  const SizedBox(height: 24),
                  const Text("Browse Categories",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const SizedBox(height: 12),
                  _buildViewAllBar(),
                  const SizedBox(height: 16),
                  _buildCategoryGrid(),
                  const SizedBox(height: 32),
                  const Text("Why Choose Us?",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.auto_awesome, "Verified Providers", "All service providers are verified and reviewed by our community", Colors.purple),
                  _buildFeatureItem(Icons.camera_alt, "Easy Booking", "Book services in just a few clicks and track your requests in real-time", Colors.blue),
                  _buildFeatureItem(Icons.music_note, "Best Prices", "Compare prices and services from multiple providers to find the best deal", Colors.pink),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header matching the gradient and search bar in screenshots
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("EventHelper", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text("Your Event Partner", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(onLogin: (String email, String password, UserRole role) {  }, onSwitchToSignup: () {  },)));
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person_outline, color: Colors.white),
                ),
              )
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(15)),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.white70, size: 20),
                SizedBox(width: 10),
                Text("Search services...", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Welcome banner with white 'Sign In' button
  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Welcome to EventHelper! 🎉", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Find the best event service providers for your special occasions", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(onLogin: (String email, String password, UserRole role) {  }, onSwitchToSignup: () {  },)));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF9333EA),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Bar for "View All Services"
  Widget _buildViewAllBar() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("View All Services", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text("Browse our complete catalog", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const Icon(Icons.search, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  // Centered icon grid matching screenshots
  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.15
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cat['color'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                child: Icon(cat['icon'], color: cat['color'], size: 28),
              ),
              const SizedBox(height: 10),
              Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(cat['desc'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  // Feature cards at the bottom
  Widget _buildFeatureItem(IconData icon, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}