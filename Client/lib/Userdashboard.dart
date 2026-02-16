import 'package:flutter/material.dart';

import 'home.dart';

class UserDashboard extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> notifications;
  final VoidCallback onHome;
  final VoidCallback onLogout;

  const UserDashboard({
    super.key,
    required this.user,
    required this.bookings,
    required this.notifications,
    required this.onHome,
    required this.onLogout,
  });

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _activeTab = 0; // 0: Bookings, 1: Alerts, 2: Profile
  bool _isEditing = false;

  // Controllers for Profile Editing
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _emailController = TextEditingController(text: widget.user['email']);
    _phoneController = TextEditingController(text: widget.user['phone']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: IndexedStack(
              index: _activeTab,
              children: [
                _buildBookingsTab(),
                _buildNotificationsTab(),
                _buildProfileTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- Header Section ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome back", style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(widget.user['name'] ?? "User",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(
            onPressed:(){
              Navigator.push(context, MaterialPageRoute(builder: (context) => EventHelperHome()));
            },
            icon: const Icon(Icons.home_outlined, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white24),
          ),
        ],
      ),
    );
  }

  // --- Tab 1: Bookings ---
  Widget _buildBookingsTab() {
    if (widget.bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("No bookings yet", style: TextStyle(color: Colors.grey)),
            TextButton(onPressed: widget.onHome, child: const Text("Browse Services")),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.bookings.length,
      itemBuilder: (context, index) {
        final booking = widget.bookings[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(booking['eventName'] ?? "Event", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _buildStatusBadge(booking['status'] ?? "pending"),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow("Service", booking['service']?['name'] ?? "N/A"),
              _buildDetailRow("Date", booking['eventDate'] ?? "N/A"),
              _buildDetailRow("Location", booking['eventLocation'] ?? "N/A"),
            ],
          ),
        );
      },
    );
  }

  // --- Tab 2: Notifications ---
  Widget _buildNotificationsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.notifications.length,
      itemBuilder: (context, index) {
        final note = widget.notifications[index];
        bool isUnread = !(note['read'] ?? true);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: isUnread ? const Border(left: BorderSide(color: Color(0xFF9333EA), width: 4)) : null,
          ),
          child: ListTile(
            title: Text(note['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(note['message'] ?? ""),
            trailing: isUnread ? const CircleAvatar(radius: 4, backgroundColor: Color(0xFF9333EA)) : null,
          ),
        );
      },
    );
  }

  // --- Tab 3: Profile with Edit Mode ---
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Profile Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton(
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                      child: Text(_isEditing ? "Cancel" : "Edit", style: const TextStyle(color: Color(0xFF9333EA))),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildEditableRow("Full Name", _nameController, Icons.person_outline),
                _buildEditableRow("Email", _emailController, Icons.mail_outline),
                _buildEditableRow("Phone", _phoneController, Icons.phone_outlined),
                _buildInfoRow("Account Type", widget.user['role'], isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _isEditing ? _buildSaveButton() : _buildLogoutButton(),
        ],
      ),
    );
  }

  // --- Helper Methods ---
  Widget _buildEditableRow(String label, TextEditingController controller, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          _isEditing
              ? TextField(
            controller: controller,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
              prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9333EA)),
            ),
          )
              : Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(controller.text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ElevatedButton(
          onPressed: () {
            // Add API call here to persist data
            setState(() => _isEditing = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile saved!")));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // This removes ALL previous screens and opens the Home page
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const EventHelperHome()),
                (route) => false, // This condition 'false' means delete all previous routes
          );
        },
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text("Logout", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'confirmed') color = Colors.green;
    if (status == 'rejected') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _activeTab,
      onTap: (index) => setState(() => _activeTab = index),
      selectedItemColor: const Color(0xFF9333EA),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Bookings"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Alerts"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
      ],
    );
  }
}