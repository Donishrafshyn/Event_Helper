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
      setState(() { _isEditing = false; _isSaving = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showBookingDetails(String id, Map<String, dynamic> booking) {
    String status = booking['status'] ?? 'pending';
    bool canGiveFeedback = status == 'confirmed' || status == 'completed';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Booking Details", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailItem("Event", booking['eventName'] ?? "N/A"),
            _detailItem("Provider", booking['serviceName'] ?? "N/A"),
            _detailItem("Status", status.toUpperCase(), color: status == 'completed' ? Colors.blue : (status == 'confirmed' ? Colors.green : Colors.orange)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          if (canGiveFeedback) ElevatedButton.icon(
            onPressed: () { Navigator.pop(context); _showFeedbackDialog(booking); },
            icon: const Icon(Icons.star, size: 18, color: Colors.white),
            label: const Text("Give Feedback", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          )
        ],
      ),
    );
  }

  void _showFeedbackDialog(Map<String, dynamic> booking) {
    double rating = 5.0;
    bool isSubmitting = false;
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental close
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Rate Service", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("How was your experience?", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => IconButton(
                icon: Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.orange, size: 32),
                onPressed: isSubmitting ? null : () => setDialogState(() => rating = index + 1.0),
              ))),
              const SizedBox(height: 10),
              TextField(
                controller: commentController, 
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  hintText: "Write your feedback...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ), 
                maxLines: 3
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context), 
              child: const Text("Cancel")
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                setDialogState(() => isSubmitting = true);
                try {
                  await FirebaseFirestore.instance.collection('reviews').add({
                    'providerId': booking['providerId'],
                    'userId': widget.user['uid'],
                    'userName': widget.user['name'],
                    'rating': rating,
                    'comment': commentController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Feedback submitted successfully!"), backgroundColor: Colors.green)
                    );
                  }
                } catch (e) {
                  setDialogState(() => isSubmitting = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9333EA)),
              child: isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Submit", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value, {Color? color}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)), Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color ?? Colors.black87))]));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggingOut) return const Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Logging out...")] )));
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(children: [_buildHeader(), Expanded(child: IndexedStack(index: _activeTab, children: [_buildBookingsTab(), const Center(child: Text("Alerts coming soon")), _buildProfileTab()]))]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)])),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Welcome back", style: TextStyle(color: Colors.white70, fontSize: 12)), Text(_nameController.text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
        IconButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), icon: const Icon(Icons.home_outlined, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.white24)),
      ]),
    );
  }

  Widget _buildBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: widget.user['uid']).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No bookings yet"));
        return ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var booking = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var id = snapshot.data!.docs[index].id;
            String status = booking['status'] ?? 'pending';
            bool canReview = status == 'confirmed' || status == 'completed';

            return GestureDetector(
              onTap: () => _showBookingDetails(id, booking),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(booking['eventName'] ?? "Event", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), _buildStatusBadge(status)]),
                  const Divider(height: 24),
                  _buildDetailRow("Type", booking['eventType'] ?? "N/A"),
                  _buildDetailRow("Date", booking['eventDate'] ?? "N/A"),
                  const SizedBox(height: 8),
                  if (canReview) const Text("Tap to give feedback ⭐", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))
                  else const Text("Waiting for provider to accept...", style: TextStyle(color: Colors.grey, fontSize: 10)),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Profile Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), TextButton(onPressed: () => setState(() => _isEditing = !_isEditing), child: Text(_isEditing ? "Cancel" : "Edit", style: const TextStyle(color: Color(0xFF9333EA))))]),
            _buildEditableRow("Full Name", _nameController, Icons.person_outline),
            _buildEditableRow("Phone", _phoneController, Icons.phone_outlined),
          ]),
        ),
        const SizedBox(height: 24),
        _isEditing ? _buildSaveButton() : _buildLogoutButton(),
      ]),
    );
  }

  Widget _buildEditableRow(String label, TextEditingController controller, IconData icon) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)), _isEditing ? TextField(controller: controller, decoration: InputDecoration(isDense: true, border: InputBorder.none, prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9333EA)))) : Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(controller.text, style: const TextStyle(fontWeight: FontWeight.bold)))]));
  }

  Widget _buildSaveButton() => SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _updateProfile, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9333EA)), child: const Text("Save Changes", style: TextStyle(color: Colors.white))));

  Widget _buildLogoutButton() => SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () async { setState(() => _isLoggingOut = true); await widget.onLogout(); }, icon: const Icon(Icons.logout, color: Colors.white), label: const Text("Logout", style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))));

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'confirmed') color = Colors.green;
    if (status == 'rejected') color = Colors.red;
    if (status == 'completed') color = Colors.blue;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  }

  Widget _buildDetailRow(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)), Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))]));

  Widget _buildBottomNav() => BottomNavigationBar(currentIndex: _activeTab, onTap: (index) => setState(() => _activeTab = index), selectedItemColor: const Color(0xFF9333EA), items: const [BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Bookings"), BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Alerts"), BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile")]);
}
