import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';

class ProviderDashboard extends StatefulWidget {
  final Map<String, dynamic> provider;
  final VoidCallback onHome;
  final Future<void> Function() onLogout;

  const ProviderDashboard({
    super.key,
    required this.provider,
    required this.onHome,
    required this.onLogout,
  });

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _activeTab = 0; 
  bool _isLoggingOut = false;

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': status});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking ${status.toUpperCase()}")),
        );
      }
    } catch (e) {
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
            children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Logging out...")],
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
                _buildServicesTab(),
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
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Provider Dashboard", style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(widget.provider['businessName'] ?? "Business Name",
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings').where('providerId', isEqualTo: widget.provider['uid']).snapshots(),
            builder: (context, snapshot) {
              int pending = 0;
              int confirmed = 0;
              if (snapshot.hasData) {
                pending = snapshot.data!.docs.where((d) => d['status'] == 'pending').length;
                confirmed = snapshot.data!.docs.where((d) => d['status'] == 'confirmed').length;
              }
              return Row(
                children: [
                  _buildStatCard(pending.toString(), "Pending"),
                  _buildStatCard(confirmed.toString(), "Booked"),
                  _buildStatCard(widget.provider['category'] ?? "N/A", "Category"),
                ],
              );
            }
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
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: widget.provider['uid'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No booking requests yet."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var booking = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var id = snapshot.data!.docs[index].id;
            bool isPending = booking['status'] == 'pending';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: isPending ? Border.all(color: Colors.orange.shade100) : null),
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
                  const SizedBox(height: 10),
                  Text("Date: ${booking['eventDate']}", style: const TextStyle(color: Colors.grey)),
                  Text("Location: ${booking['eventLocation']}", style: const TextStyle(color: Colors.grey)),
                  if (isPending) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(onPressed: () => _updateBookingStatus(id, 'confirmed'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Accept", style: TextStyle(color: Colors.white)))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton(onPressed: () => _updateBookingStatus(id, 'rejected'), child: const Text("Reject", style: TextStyle(color: Colors.red)))),
                      ],
                    )
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildServicesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('services').where('providerId', isEqualTo: widget.provider['uid']).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.add), label: const Text("Add New Service")),
            const SizedBox(height: 16),
            ...snapshot.data!.docs.map((doc) {
              var service = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(service['name']),
                subtitle: Text("${service['price']}"),
                trailing: const Icon(Icons.edit),
              );
            }).toList(),
          ],
        );
      }
    );
  }

  Widget _buildNotificationsTab() => const Center(child: Text("Alerts coming soon"));

  Widget _buildProfileTab() {
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
                const Text("Business Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildProfileRow("Business Name", widget.provider['businessName']),
                _buildProfileRow("Owner", widget.provider['name']),
                _buildProfileRow("Email", widget.provider['email']),
                _buildProfileRow("Phone", widget.provider['phone']),
                _buildProfileRow("Category", widget.provider['category']),
                _buildProfileRow("Status", "✓ Approved", isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                setState(() => _isLoggingOut = true);
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const EventHelperHome()), (route) => false);
                }
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String? value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'confirmed' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _activeTab,
      onTap: (index) => setState(() => _activeTab = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF9333EA),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: "Bookings"),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: "Services"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Alerts"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
      ],
    );
  }
}
