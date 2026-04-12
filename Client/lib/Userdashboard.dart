import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';

class UserDashboard extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onHome;
  final Future<void> Function() onLogout;

  const UserDashboard({
    super.key,
    required this.user,
    required this.onHome,
    required this.onLogout,
  });

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _activeTab = 0;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isLoggingOut = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _phoneController = TextEditingController(text: widget.user['phone']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user['uid'])
          .update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggingOut) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Logging out...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome back", style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_nameController.text,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(
            onPressed: () {
              // Fix: Navigate to Home without logging out
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EventHelperHome()),
              );
            },
            icon: const Icon(Icons.home_outlined, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: widget.user['uid'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error loading bookings: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text("No bookings yet", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EventHelperHome())), child: const Text("Explore Services")),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var booking = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
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
                  _buildDetailRow("Type", booking['eventType'] ?? "N/A"),
                  _buildDetailRow("Date", booking['eventDate'] ?? "N/A"),
                  _buildDetailRow("Location", booking['eventLocation'] ?? "N/A"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    return const Center(child: Text("Notifications coming soon", style: TextStyle(color: Colors.grey)));
  }

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
                _buildEditableRow("Full Name", _nameController, Icons.person_outline),
                _buildInfoRow("Email", widget.user['email']),
                _buildEditableRow("Phone", _phoneController, Icons.phone_outlined),
                _buildInfoRow("Account Type", widget.user['role'], isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _isEditing 
            ? (_isSaving ? const CircularProgressIndicator() : _buildSaveButton()) 
            : _buildLogoutButton(),
        ],
      ),
    );
  }

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
                  decoration: InputDecoration(
                    isDense: true,
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
      child: ElevatedButton(
        onPressed: _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9333EA),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          setState(() => _isLoggingOut = true);
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const EventHelperHome()),
              (route) => false,
            );
          }
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
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
