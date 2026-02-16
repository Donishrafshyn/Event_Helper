import 'package:flutter/material.dart';

class ProviderDashboard extends StatefulWidget {
  final Map<String, dynamic> provider;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> notifications;
  final VoidCallback onHome;
  final VoidCallback onLogout;
  final Function(String id, String status) onUpdateBookingStatus;

  const ProviderDashboard({
    super.key,
    required this.provider,
    required this.services,
    required this.bookings,
    required this.notifications,
    required this.onHome,
    required this.onLogout,
    required this.onUpdateBookingStatus,
  });

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _activeTab = 3; // Starting on Profile (index 3) to match your screenshot

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(), // Gradient header with Stat Cards
          Expanded(
            child: IndexedStack(
              index: _activeTab,
              children: [
                _buildBookingsTab(),
                _buildServicesTab(),
                _buildNotificationsTab(),
                _buildProfileTab(), // Updated to match screenshot
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- Header with Screenshot Stats Cards ---
  Widget _buildHeader() {
    final pendingCount = widget.bookings.where((b) => b['status'] == 'pending').length;
    final confirmedCount = widget.bookings.where((b) => b['status'] == 'confirmed').length;

    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 24),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Provider Dashboard",
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(widget.provider['businessName'] ?? "Business Name",
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                onPressed: widget.onHome,
                icon: const Icon(Icons.home_outlined, color: Colors.white, size: 24),
                style: IconButton.styleFrom(backgroundColor: Colors.white24),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stat Cards matching screenshot
          Row(
            children: [
              _buildStatCard(widget.services.length.toString(), "Services"),
              _buildStatCard(pendingCount.toString(), "Pending"),
              _buildStatCard(confirmedCount.toString(), "Confirmed"),
              _buildStatCard(widget.provider['rating']?.toString() ?? "0.0", "Rating"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // --- Updated Profile Tab (Matches Screenshot) ---
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Business Profile",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                _buildProfileRow("Business Name", widget.provider['businessName']),
                _buildProfileRow("Owner", widget.provider['name']),
                _buildProfileRow("Email", widget.provider['email']),
                _buildProfileRow("Phone", widget.provider['phone']),
                _buildProfileRow("Category", widget.provider['category']),
                _buildProfileRow("Rating", "${widget.provider['rating']} ★ (${widget.provider['reviewCount'] ?? 0})"),
                _buildProfileRow("Status", "✓ Verified • Approved", isLast: true),
              ],
            ),
          ),
          // Red Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Logout",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String? value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value ?? "N/A",
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black)),
        ],
      ),
    );
  }

  // --- Other Tabs (Placeholders for logic) ---
  Widget _buildBookingsTab() => const Center(child: Text("Booking Requests"));
  Widget _buildServicesTab() => const Center(child: Text("Services Management"));
  Widget _buildNotificationsTab() => const Center(child: Text("Alerts"));

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _activeTab,
      onTap: (index) => setState(() => _activeTab = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF9333EA),
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: "Bookings"),
        const BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: "Services"),
        const BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Alerts"),
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: _activeTab == 3
                ? BoxDecoration(color: const Color(0xFF9333EA).withOpacity(0.1), borderRadius: BorderRadius.circular(10))
                : null,
            child: const Icon(Icons.person_outline),
          ),
          label: "Profile",
        ),
      ],
    );
  }
}