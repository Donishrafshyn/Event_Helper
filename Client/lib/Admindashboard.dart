import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> admin;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> providers;
  final VoidCallback onHome;
  final VoidCallback onLogout;
  final Function(String id) onApproveProvider;
  final Function(String id) onRejectProvider;

  const AdminDashboard({
    super.key,
    required this.admin,
    required this.users,
    required this.providers,
    required this.onHome,
    required this.onLogout,
    required this.onApproveProvider,
    required this.onRejectProvider,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _activeTab = 0; // 0: Providers, 1: Users, 2: Stats

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(), // Fixed Header with Stats
          Expanded(
            child: IndexedStack(
              index: _activeTab,
              children: [
                _buildProvidersTab(),
                _buildUsersTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- Header with System Stats ---
  Widget _buildHeader() {
    final pendingCount = widget.providers.where((p) => !(p['approved'] ?? false)).length;
    final approvedCount = widget.providers.where((p) => p['approved'] ?? true).length;
    final totalUsers = widget.users.where((u) => u['role'] == 'user').length;

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Admin Panel", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text("System Control", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: widget.onHome,
                icon: const Icon(Icons.home_outlined, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.white24),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard(totalUsers.toString(), "Users"),
              _buildStatCard(widget.providers.length.toString(), "Providers"),
              _buildStatCard(pendingCount.toString(), "Pending"),
              _buildStatCard(approvedCount.toString(), "Approved"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String val, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // --- Tab 1: Providers Management with Approval Logic ---
  Widget _buildProvidersTab() {
    final pending = widget.providers.where((p) => !(p['approved'] ?? false)).toList();
    final approved = widget.providers.where((p) => p['approved'] ?? false).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          Text("Pending Approvals (${pending.length})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 12),
          ...pending.map((p) => _buildPendingCard(p)),
          const SizedBox(height: 24),
        ],
        const Text("Approved Providers",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        const SizedBox(height: 12),
        if (approved.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No approved providers yet")))
        else
          ...approved.map((p) => _buildApprovedCard(p)),
      ],
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Yellow background for pending
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEF3C7), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(provider['businessName'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildStatusBadge("Pending", Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoLine("Category", provider['category']),
          _buildInfoLine("Owner", provider['name']),
          _buildInfoLine("Email", provider['email']),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onApproveProvider(provider['id']),
                  icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                  label: const Text("Approve", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onRejectProvider(provider['id']),
                  icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.white),
                  label: const Text("Reject", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildApprovedCard(Map<String, dynamic> provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(provider['businessName'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  if (provider['verified'] ?? false) const Icon(Icons.verified, size: 14, color: Colors.blue),
                ],
              ),
              Text(provider['category'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          _buildStatusBadge("Approved", Colors.green),
        ],
      ),
    );
  }

  // --- Tab 2: Users Management ---
  Widget _buildUsersTab() {
    final regularUsers = widget.users.where((u) => u['role'] == 'user').toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: regularUsers.length,
      itemBuilder: (context, index) {
        final user = regularUsers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              _buildInfoLine("Name", user['name']),
              _buildInfoLine("Email", user['email']),
              _buildInfoLine("Phone", user['phone']),
            ],
          ),
        );
      },
    );
  }

  // --- Tab 3: Stats Overview ---
  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("System Overview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                _buildStatRow("Total Users", widget.users.length.toString()),
                _buildStatRow("Total Providers", widget.providers.length.toString()),
                _buildStatRow("Approved", widget.providers.where((p) => p['approved'] == true).length.toString(), color: Colors.green),
                _buildStatRow("Pending", widget.providers.where((p) => p['approved'] == false).length.toString(), color: Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoLine(String label, String? val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(val ?? "N/A", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String val, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color ?? Colors.black)),
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
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: "Providers"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Users"),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
      ],
    );
  }
}