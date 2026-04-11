import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> admin;
  final VoidCallback onHome;
  final Future<void> Function() onLogout;

  const AdminDashboard({
    super.key,
    required this.admin,
    required this.onHome,
    required this.onLogout,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _activeTab = 0; 
  bool _isLoggingOut = false;

  Future<void> _updateProviderStatus(String uid, bool? approved) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isApproved': approved,
        // If null, it means we reset them to pending or user
        'role': (approved == true) ? 'provider' : 'user',
      });
      if (mounted) {
        String msg = approved == true ? "Approved" : (approved == false ? "Rejected" : "Reset");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Provider $msg!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _deleteUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Deleted")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete Error: $e")));
    }
  }

  void _showProviderDetails(Map<String, dynamic> provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.business, color: Color(0xFF9333EA)),
            SizedBox(width: 10),
            Text("Provider Details", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailLabel("Business Name"),
              Text(provider['businessName'] ?? "N/A", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _detailLabel("Service Category"),
              Text(provider['category'] ?? "N/A", style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 15),
              _detailLabel("Description"),
              Text(provider['description'] ?? "No description provided.", style: const TextStyle(fontSize: 14)),
              const Divider(),
              _detailLabel("Owner"),
              Text(provider['name'] ?? "N/A"),
              _detailLabel("Email"),
              Text(provider['email'] ?? "N/A"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _updateProviderStatus(provider['id'], true); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Approve", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 2),
    child: Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
  );

  @override
  Widget build(BuildContext context) {
    if (_isLoggingOut) {
      return const Scaffold(body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Signing out...")],
      )));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (snapshot.error.toString().contains('permission-denied')) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text("No users found")));
        }

        final allUsers = snapshot.data!.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
        
        // Correct Filter Logic
        final pending = allUsers.where((u) => u.containsKey('businessName') && u['isApproved'] == null).toList();
        final approved = allUsers.where((u) => u['isApproved'] == true).toList();
        final rejected = allUsers.where((u) => u['isApproved'] == false).toList();
        final regularUsers = allUsers.where((u) => u['role'] == 'user' && !u.containsKey('businessName')).toList();

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(
            children: [
              _buildHeader(allUsers.length, pending.length, approved.length),
              Expanded(
                child: IndexedStack(
                  index: _activeTab,
                  children: [
                    _buildProvidersTab(pending, approved, rejected),
                    _buildUsersTab(regularUsers),
                    _buildStatsTab(allUsers.length, approved.length, rejected.length),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildHeader(int total, int pending, int approved) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 24),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)])),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Admin Panel", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text("System Control", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(onPressed: widget.onHome, icon: const Icon(Icons.home_outlined, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.white24)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard(total.toString(), "Total"),
              _buildStatCard(pending.toString(), "Pending"),
              _buildStatCard(approved.toString(), "Approved"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String val, String label) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
      child: Column(children: [Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))]),
    ),
  );

  Widget _buildProvidersTab(List<Map<String, dynamic>> pending, List<Map<String, dynamic>> approved, List<Map<String, dynamic>> rejected) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[const Text("Pending Approvals", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 12), ...pending.map((p) => _buildProviderCard(p, "pending")), const SizedBox(height: 24)],
        if (approved.isNotEmpty) ...[const Text("Approved Providers", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 12), ...approved.map((p) => _buildProviderCard(p, "approved")), const SizedBox(height: 24)],
        if (rejected.isNotEmpty) ...[const Text("Rejected Providers", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)), const SizedBox(height: 12), ...rejected.map((p) => _buildProviderCard(p, "rejected"))],
      ],
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider, String type) {
    Color cardColor = type == "pending" ? const Color(0xFFFFFBEB) : (type == "rejected" ? const Color(0xFFFEF2F2) : Colors.white);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: type == "pending" ? const Color(0xFFFEF3C7) : Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(provider['businessName'] ?? "Business", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(type.toUpperCase(), style: TextStyle(color: type == "approved" ? Colors.green : (type == "rejected" ? Colors.red : Colors.orange), fontSize: 9, fontWeight: FontWeight.bold))
          ]),
          Text(provider['category'] ?? "N/A", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _showProviderDetails(provider), child: const Text("View Details"))),
            const SizedBox(width: 8),
            if (type != "approved") IconButton(onPressed: () => _updateProviderStatus(provider['id'], true), icon: const Icon(Icons.check_circle, color: Colors.green)),
            if (type != "rejected") IconButton(onPressed: () => _updateProviderStatus(provider['id'], false), icon: const Icon(Icons.cancel, color: Colors.red)),
            if (type == "rejected") IconButton(onPressed: () => _deleteUser(provider['id']), icon: const Icon(Icons.delete_forever, color: Colors.redAccent)),
          ])
        ],
      ),
    );
  }

  Widget _buildUsersTab(List<Map<String, dynamic>> users) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: users.length,
    itemBuilder: (context, index) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(users[index]['name'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)), Text(users[index]['email'] ?? "No Email", style: const TextStyle(fontSize: 12, color: Colors.grey))]),
    ),
  );

  Widget _buildStatsTab(int total, int approved, int rejected) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          _buildStatRow("Total Registrations", total.toString()),
          _buildStatRow("Active Providers", approved.toString(), color: Colors.green),
          _buildStatRow("Rejected Applications", rejected.toString(), color: Colors.red),
        ]),
      ),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: () async { 
          setState(() => _isLoggingOut = true); 
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const EventHelperHome()), (route) => false);
        },
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      )),
    ]),
  );

  Widget _buildStatRow(String label, String val, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color))]),
  );

  Widget _buildBottomNav() => BottomNavigationBar(
    currentIndex: _activeTab,
    onTap: (index) => setState(() => _activeTab = index),
    selectedItemColor: const Color(0xFF9333EA),
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: "Providers"),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Users"),
      BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
    ],
  );
}
