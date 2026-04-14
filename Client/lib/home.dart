import 'package:event/signup.dart' hide UserRole;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'Admindashboard.dart';
import 'Userdashboard.dart'; 
import 'Providerdashboard.dart';
import 'servicelist.dart';
import 'Servicedetail.dart';
import 'bookingform.dart'; // Import BookingForm

class EventHelperHome extends StatefulWidget {
  const EventHelperHome({super.key});

  @override
  State<EventHelperHome> createState() => _EventHelperHomeState();
}

class _EventHelperHomeState extends State<EventHelperHome> {
  bool _isChecking = false;

  final List<Map<String, dynamic>> categories = [
    {'id': 'decorator', 'name': 'Decorators', 'icon': Icons.auto_awesome, 'color': Colors.pink, 'desc': 'Transform your venue'},
    {'id': 'photographer', 'name': 'Photographers', 'icon': Icons.camera_alt, 'color': Colors.blue, 'desc': 'Capture precious moments'},
    {'id': 'dj', 'name': 'DJs', 'icon': Icons.music_note, 'color': Colors.purple, 'desc': 'Keep the party going'},
    {'id': 'caterer', 'name': 'Caterers', 'icon': Icons.restaurant, 'color': Colors.orange, 'desc': 'Delicious cuisines'},
    {'id': 'sound-system', 'name': 'Sound Systems', 'icon': Icons.speaker, 'color': Colors.indigo, 'desc': 'Crystal clear audio'},
    {'id': 'videographer', 'name': 'Videographers', 'icon': Icons.videocam, 'color': Colors.teal, 'desc': 'Professional videos'},
    {'id': 'makeup', 'name': 'Makeup Artists', 'icon': Icons.palette, 'color': Colors.pinkAccent, 'desc': 'Look your best'},
    {'id': 'venue', 'name': 'Venues', 'icon': Icons.location_on, 'color': Colors.tealAccent, 'desc': 'Perfect locations'},
    {'id': 'anchoring', 'name': 'Anchoring', 'icon': Icons.mic_external_on, 'color': Colors.deepPurple, 'desc': 'Professional hosts'},
    {'id': 'dance-event', 'name': 'Dance Events', 'icon': Icons.celebration, 'color': Colors.pinkAccent, 'desc': 'Dance performances'},
  ];

  void _navigateToServiceList(String categoryId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceList(
          category: categoryId,
          onBack: () => Navigator.pop(context),
          onSelectService: (Map<String, dynamic> provider) async {
            User? user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              _showServiceDetail(provider, false, 'user');
              return;
            }
            DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            String role = userDoc.exists ? (userDoc.get('role') ?? 'user') : 'user';
            _showServiceDetail(provider, true, role);
          },
        ),
      ),
    );
  }

  void _showServiceDetail(Map<String, dynamic> provider, bool isAuth, String role) {
    bool canBook = role.toLowerCase() == 'user';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetail(
          service: provider,
          provider: provider,
          isAuthenticated: isAuth && canBook,
          onBack: () => Navigator.pop(context),
          onBookNow: (String serviceId) {
            // Fix: Navigate to BookingForm
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingForm(
                  service: provider,
                  onBack: () => Navigator.pop(context),
                  onSubmit: (BookingFormData data) async {
                    await _handleBookingSubmission(data, provider);
                  },
                ),
              ),
            );
          },
          onLogin: () {
            if (canBook) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You are logged in as a $role.")));
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleBookingSubmission(BookingFormData data, Map<String, dynamic> provider) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Create booking in Firestore
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'providerId': provider['uid'] ?? provider['id'],
        'serviceName': provider['businessName'] ?? provider['name'],
        'eventName': data.eventName,
        'eventType': data.eventType,
        'eventDate': data.eventDate,
        'eventLocation': data.eventLocation,
        'guestCount': data.guestCount,
        'message': data.message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Request Sent!"), backgroundColor: Colors.green));
        // Return to home or dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Booking Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _navigateToDashboard() async {
    setState(() => _isChecking = true);
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    } else {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && mounted) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          String role = userData['role'] ?? 'user';
          _redirectByRole(role, userData);
        } else {
          if (mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
    if (mounted) setState(() => _isChecking = false);
  }

  void _redirectByRole(String role, Map<String, dynamic> userData) {
    Widget nextScreen;
    Future<void> handleLogout() async {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const EventHelperHome()), (route) => false);
    }
    switch (role.toLowerCase()) {
      case 'admin':
        nextScreen = AdminDashboard(admin: userData, onHome: () => Navigator.of(context).popUntil((r)=>r.isFirst), onLogout: handleLogout);
        break;
      case 'provider':
        nextScreen = ProviderDashboard(provider: userData, onHome: () => Navigator.of(context).popUntil((r)=>r.isFirst), onLogout: handleLogout);
        break;
      default:
        nextScreen = UserDashboard(user: userData, onHome: () => Navigator.of(context).popUntil((r)=>r.isFirst), onLogout: handleLogout);
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
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
                      const Text("Browse Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                      const SizedBox(height: 12),
                      _buildViewAllBar(),
                      const SizedBox(height: 16),
                      _buildCategoryGrid(),
                      const SizedBox(height: 32),
                      const Text("Why Choose Us?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
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
          if (_isChecking) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 25),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)])),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white),
                  SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("EventHelper", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Text("Your Event Partner", style: TextStyle(color: Colors.white70, fontSize: 12))]),
                ],
              ),
              GestureDetector(
                onTap: _navigateToDashboard,
                child: CircleAvatar(backgroundColor: Colors.white24, child: Icon(FirebaseAuth.instance.currentUser != null ? Icons.dashboard : Icons.person_outline, color: Colors.white)),
              )
            ],
          ),
          const SizedBox(height: 25),
          GestureDetector(
            onTap: () => _navigateToServiceList('all'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(15)),
              child: const Row(children: [Icon(Icons.search, color: Colors.white70, size: 20), SizedBox(width: 10), Text("Search services...", style: TextStyle(color: Colors.white70))]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]), borderRadius: BorderRadius.circular(24)),
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
                  onPressed: _navigateToDashboard,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF9333EA), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(isLoggedIn ? "My Dashboard" : "Sign In", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (!isLoggedIn) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignupPage(onSignup: (data){}, onBackToHome: () => Navigator.pop(context), onSwitchToLogin: () => Navigator.pop(context)))),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllBar() {
    return GestureDetector(
      onTap: () => _navigateToServiceList('all'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]), borderRadius: BorderRadius.circular(20)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("View All Services", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), Text("Browse our complete catalog", style: TextStyle(color: Colors.white70, fontSize: 12))]),
            Icon(Icons.search, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.15),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return GestureDetector(
          onTap: () => _navigateToServiceList(cat['id']),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cat['color'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: Icon(cat['icon'], color: cat['color'], size: 28)),
                const SizedBox(height: 10),
                Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(cat['desc'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 4), Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.3))])),
        ],
      ),
    );
  }
}
