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
  String _searchQuery = ''; 

  Future<void> _updateProviderStatus(String uid, {required bool approved, bool rejected = false}) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isApproved': approved,
        'isRejected': rejected,
        'role': approved ? 'provider' : 'user',
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approved ? "Provider Approved!" : "Provider Restricted!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _confirmReject(String uid, String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restrict Approved Provider?"),
        content: Text("Are you sure you want to revoke approval for $name? They will be moved to the Rejected list and their services will be hidden."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Yes, Restrict", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) _updateProviderStatus(uid, approved: false, rejected: true);
  }

  Future<void> _confirmDelete(String uid, String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: Text("Are you sure you want to permanently delete $name?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Delete Forever", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm == true) _deleteUser(uid);
  }

  Future<void> _deleteUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Deleted")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete Error: $e")));
    }
  }

  void _showBookingFullDetails(Map<String, dynamic> b) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.event_note, color: Colors.purple), SizedBox(width: 10), Text("Booking Detail")]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailLabel("Customer"), Text(b['userName'] ?? "N/A"),
              _detailLabel("Contact Number"), Text(b['customerPhone'] ?? "N/A", style: const TextStyle(color: Colors.blue)),
              _detailLabel("Provider"), Text(b['serviceName'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
              _detailLabel("Event"), Text(b['eventName'] ?? "N/A"),
              _detailLabel("Type"), Text(b['eventType'] ?? "N/A"),
              _detailLabel("Date"), Text(b['eventDate'] ?? "N/A"),
              _detailLabel("Location"), Text(b['eventLocation'] ?? "N/A"),
              _detailLabel("Guests"), Text(b['guestCount']?.toString() ?? "N/A"),
              _detailLabel("Status"), Text((b['status'] ?? "pending").toUpperCase(), 
                  style: TextStyle(fontWeight: FontWeight.bold, color: b['status'] == 'completed' ? Colors.blue : (b['status'] == 'confirmed' ? Colors.green : Colors.orange))),
              const Divider(),
              _detailLabel("User Message"),
              Text(b['message'] ?? "No message provided.", style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.person, color: Colors.blue), SizedBox(width: 10), Text("User Oversight")]),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailLabel("Full Name"), Text(user['name'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
                _detailLabel("Email"), Text(user['email'] ?? "N/A"),
                _detailLabel("Phone"), Text(user['phone'] ?? "N/A"),
                const Divider(height: 30),
                const Text("User Booking History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                _buildBookingListStream(FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: user['uid'])),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  void _showProviderDetails(Map<String, dynamic> provider, bool showApproveAction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.business, color: Color(0xFF9333EA)), SizedBox(width: 10), Text("Provider Oversight")]),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailLabel("Business Name"), Text(provider['businessName'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                _detailLabel("Category"), Text(provider['category'] ?? "N/A"),
                _detailLabel("Pricing"), Text("₹ ${provider['price'] ?? 'N/A'}"),
                _detailLabel("Description"), Text(provider['description'] ?? "N/A"),
                const Divider(height: 30),
                const Text("Feedback History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                _buildProviderReviewsList(provider['id']),
                const Divider(height: 30),
                const Text("Booking History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                _buildBookingListStream(FirebaseFirestore.instance.collection('bookings').where('providerId', isEqualTo: provider['id'])),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          if (showApproveAction) ElevatedButton(
            onPressed: () { Navigator.pop(context); _updateProviderStatus(provider['id'], approved: true); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Approve", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingListStream(Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        if (snapshot.data!.docs.isEmpty) return const Text("No bookings found.", style: TextStyle(color: Colors.grey, fontSize: 12));
        return Column(
          children: snapshot.data!.docs.map((doc) {
            var b = doc.data() as Map<String, dynamic>;
            return Card(
              color: Colors.grey[50], margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true, 
                onTap: () => _showBookingFullDetails(b),
                title: Text(b['serviceName'] ?? "Service"), 
                subtitle: Text("${b['eventDate']} • ${b['status'].toString().toUpperCase()}"),
                trailing: const Icon(Icons.chevron_right, size: 14),
              )
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildProviderReviewsList(String providerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reviews').where('providerId', isEqualTo: providerId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Text("No reviews yet.", style: TextStyle(color: Colors.grey, fontSize: 12));
        return Column(
          children: snapshot.data!.docs.map((doc) {
            var r = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(r['userName'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Row(children: [const Icon(Icons.star, color: Colors.orange, size: 12), Text(" ${r['rating']}", style: const TextStyle(fontSize: 12))])
                ]),
                Text(r['comment'] ?? "", style: const TextStyle(fontSize: 11)),
              ]),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _detailLabel(String text) => Padding(padding: const EdgeInsets.only(top: 10, bottom: 2), child: Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)));

  @override
  Widget build(BuildContext context) {
    if (_isLoggingOut) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final allUsers = snapshot.data!.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
        
        final approved = allUsers.where((u) => u['isApproved'] == true).toList();
        final rejected = allUsers.where((u) => u['isRejected'] == true).toList();
        final pending = allUsers.where((u) => u.containsKey('businessName') && u['isApproved'] != true && u['isRejected'] != true).toList();
        final regularUsers = allUsers.where((u) => u['role'] == 'user' && !u.containsKey('businessName')).toList();

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(children: [
            _buildHeader(allUsers.length, pending.length, approved.length),
            Expanded(child: IndexedStack(index: _activeTab, children: [
              _buildProvidersTab(pending, approved, rejected),
              _buildUsersTab(regularUsers),
              _buildStatsTab(allUsers.length, approved.length, pending.length),
              _buildAlertsTab(),
            ]))
          ]),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildHeader(int total, int pending, int approved) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 24),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)])),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Admin Panel", style: TextStyle(color: Colors.white70, fontSize: 12)), Text("System Control", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
          IconButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), icon: const Icon(Icons.home_outlined, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.white24)),
        ]),
        const SizedBox(height: 20),
        Row(children: [_buildStatCard(total.toString(), "Total"), _buildStatCard(pending.toString(), "Pending"), _buildStatCard(approved.toString(), "Approved")]),
      ]),
    );
  }

  Widget _buildStatCard(String val, String lbl) => Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)), child: Column(children: [Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text(lbl, style: const TextStyle(color: Colors.white70, fontSize: 10))])));

  Widget _buildProvidersTab(List<Map<String, dynamic>> pending, List<Map<String, dynamic>> approved, List<Map<String, dynamic>> rejected) {
    final allProviders = [...pending, ...approved, ...rejected];
    final filteredProviders = allProviders.where((p) {
      final name = (p['businessName'] ?? '').toLowerCase();
      final category = (p['category'] ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || category.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(hintText: "Search providers...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (_searchQuery.isEmpty) ...[
                if (pending.isNotEmpty) ...[const Text("Pending Approvals", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 12), ...pending.map((p) => _buildProviderCard(p, "pending")), const SizedBox(height: 24)],
                if (approved.isNotEmpty) ...[const Text("Approved Providers", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 12), ...approved.map((p) => _buildProviderCard(p, "approved")), const SizedBox(height: 24)],
                if (rejected.isNotEmpty) ...[const Text("Rejected Providers", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)), const SizedBox(height: 12), ...rejected.map((p) => _buildProviderCard(p, "rejected"))],
              ] else ...[
                const Text("Search Results", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...filteredProviders.map((p) {
                  String type = p['isApproved'] == true ? "approved" : (p['isRejected'] == true ? "rejected" : "pending");
                  return _buildProviderCard(p, type);
                }),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider, String type) {
    bool isPending = type == "pending"; bool isRejected = type == "rejected"; bool isApproved = type == "approved";
    Color cardColor = isPending ? const Color(0xFFFFFBEB) : (isRejected ? const Color(0xFFFEF2F2) : Colors.white);
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: isPending ? const Color(0xFFFEF3C7) : Colors.grey.shade100)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(provider['businessName'] ?? "Business", style: const TextStyle(fontWeight: FontWeight.bold)), Text(type.toUpperCase(), style: TextStyle(color: isApproved ? Colors.green : (isRejected ? Colors.red : Colors.orange), fontSize: 9, fontWeight: FontWeight.bold))]),
        Text(provider['category'] ?? "N/A", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => _showProviderDetails(provider, !isApproved), child: const Text("Oversight Review"))),
          const SizedBox(width: 8),
          if (isPending || isRejected) IconButton(onPressed: () => _updateProviderStatus(provider['id'], approved: true), icon: const Icon(Icons.check_circle, color: Colors.green)),
          if (isPending || isApproved) IconButton(onPressed: () => _confirmReject(provider['id'], provider['businessName'] ?? "provider"), icon: const Icon(Icons.cancel, color: Colors.red)),
          if (isRejected) IconButton(onPressed: () => _confirmDelete(provider['id'], provider['businessName'] ?? "provider"), icon: const Icon(Icons.delete_forever, color: Colors.redAccent)),
        ])
      ]),
    );
  }

  Widget _buildUsersTab(List<Map<String, dynamic>> users) => ListView.builder(
    padding: const EdgeInsets.all(16), itemCount: users.length,
    itemBuilder: (context, index) {
      final user = users[index];
      return Card(
        margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          onTap: () => _showUserDetails(user),
          leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
          title: Text(user['name'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(user['email'] ?? "No Email"),
          trailing: const Icon(Icons.chevron_right, size: 18),
        ),
      );
    },
  );

  Widget _buildAlertsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Important System Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        _alertHeader("New Feedbacks", Icons.star_outline, Colors.orange),
        _buildFeedbackAlerts(),
        const SizedBox(height: 24),
        _alertHeader("New Booking Requests", Icons.calendar_today_outlined, Colors.blue),
        _buildBookingAlerts(),
      ],
    );
  }

  Widget _alertHeader(String title, IconData icon, Color color) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]));

  Widget _buildFeedbackAlerts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reviews').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        if (snapshot.data!.docs.isEmpty) return const Text("No recent feedback.", style: TextStyle(color: Colors.grey, fontSize: 12));
        return Column(children: snapshot.data!.docs.map((doc) {
          var r = doc.data() as Map<String, dynamic>;
          return Card(elevation: 0, color: Colors.orange[50], margin: const EdgeInsets.only(bottom: 8), child: ListTile(dense: true, title: Text("${r['userName']} rated a provider"), subtitle: Text(r['comment'] ?? ""), trailing: Text("${r['rating']} ⭐")));
        }).toList());
      }
    );
  }

  Widget _buildBookingAlerts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        if (snapshot.data!.docs.isEmpty) return const Text("No recent bookings.", style: TextStyle(color: Colors.grey, fontSize: 12));
        return Column(children: snapshot.data!.docs.map((doc) {
          var b = doc.data() as Map<String, dynamic>;
          return Card(elevation: 0, color: Colors.blue[50], margin: const EdgeInsets.only(bottom: 8), 
            child: ListTile(
              onTap: () => _showBookingFullDetails(b),
              title: Text("New Request for ${b['serviceName']}"), 
              subtitle: Text("Event: ${b['eventName']}")));
        }).toList());
      }
    );
  }

  Widget _buildStatsTab(int totalUsers, int approvedProviders, int pendingProviders) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Global Statistics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings').where('status', isNotEqualTo: 'completed').snapshots(),
              builder: (context, bSnap) {
                int activeBookings = bSnap.hasData ? bSnap.data!.docs.length : 0;
                return _buildStatRow("Active System Bookings", activeBookings.toString());
              }
            ),
            _buildStatRow("Approved Service Providers", approvedProviders.toString(), color: Colors.green),
            _buildStatRow("New Pending Requests", pendingProviders.toString(), color: Colors.orange),
          ]),
        ),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () async { setState(() => _isLoggingOut = true); await FirebaseAuth.instance.signOut(); Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const EventHelperHome()), (route) => false); }, icon: const Icon(Icons.logout), label: const Text("Logout"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))),
      ]),
    );
  }

  Widget _buildStatRow(String label, String val, {Color? color}) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color))]));

  Widget _buildBottomNav() => BottomNavigationBar(currentIndex: _activeTab, onTap: (index) => setState(() => _activeTab = index), type: BottomNavigationBarType.fixed, selectedItemColor: const Color(0xFF9333EA), items: const [BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: "Providers"), BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Users"), BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"), BottomNavigationBarItem(icon: Icon(Icons.notifications_active_outlined), label: "Alerts")]);
}
