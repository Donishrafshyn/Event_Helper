import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isEditing = false;
  bool _isSaving = false;
  String? _localImagePath;

  late TextEditingController _nameController;
  late TextEditingController _businessNameController;
  late TextEditingController _phoneController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _localImagePath = widget.provider['profileImage'];
    _nameController = TextEditingController(text: widget.provider['name'] ?? '');
    _businessNameController = TextEditingController(text: widget.provider['businessName'] ?? '');
    _phoneController = TextEditingController(text: widget.provider['phone'] ?? '');
    _categoryController = TextEditingController(text: widget.provider['category'] ?? '');
    _priceController = TextEditingController(text: widget.provider['price']?.toString() ?? '');
    _descController = TextEditingController(text: widget.provider['description'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose(); _businessNameController.dispose(); _phoneController.dispose();
    _categoryController.dispose(); _priceController.dispose(); _descController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileChanges() async {
    setState(() => _isSaving = true);
    try {
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? widget.provider['uid'];
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'category': _categoryController.text.trim().toLowerCase(),
        'price': _priceController.text.trim(),
        'description': _descController.text.trim(),
      });
      setState(() { _isEditing = false; _isSaving = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save Error: $e")));
    }
  }

  void _showBookingDetails(String id, Map<String, dynamic> booking) {
    String status = booking['status'] ?? 'pending';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [const Icon(Icons.event_note, color: Colors.purple), const SizedBox(width: 10), Text(booking['eventName'] ?? "Request Details", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailLabel("Contact Number"), Text(booking['customerPhone'] ?? "N/A", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              _detailLabel("Event Type"), Text(booking['eventType'] ?? "N/A"),
              _detailLabel("Date"), Text(booking['eventDate'] ?? "N/A"),
              _detailLabel("Location"), Text(booking['eventLocation'] ?? "N/A"),
              _detailLabel("Guest Count"), Text(booking['guestCount']?.toString() ?? "N/A"),
              const Divider(),
              _detailLabel("Customer Message"),
              Text(booking['message'] ?? "No message provided.", style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          if (status == 'pending') ...[
            ElevatedButton(onPressed: () { Navigator.pop(context); _updateBookingStatus(id, 'confirmed'); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Accept", style: TextStyle(color: Colors.white))),
            ElevatedButton(onPressed: () { Navigator.pop(context); _updateBookingStatus(id, 'rejected'); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Reject", style: TextStyle(color: Colors.white))),
          ],
          if (status == 'confirmed') 
            ElevatedButton(onPressed: () { Navigator.pop(context); _updateBookingStatus(id, 'completed'); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: const Text("Mark Completed", style: TextStyle(color: Colors.white))),
          if (status == 'cancelled')
            const Padding(
              padding: EdgeInsets.only(right: 16.0, bottom: 8.0),
              child: Text("CANCELLED BY USER", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': status});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Booking marked as $status")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _pickLocalImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      try {
        final String uid = FirebaseAuth.instance.currentUser?.uid ?? widget.provider['uid'];
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'profileImage': pickedFile.path});
        setState(() => _localImagePath = pickedFile.path);
      } catch (e) { debugPrint("Error: $e"); }
    }
  }

  Widget _buildProfileImage({double radius = 25}) {
    if (_localImagePath == null) return CircleAvatar(radius: radius, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white, size: radius));
    if (_localImagePath!.startsWith('/') || _localImagePath!.contains(':\\')) return CircleAvatar(radius: radius, backgroundImage: FileImage(File(_localImagePath!)));
    return CircleAvatar(radius: radius, backgroundImage: NetworkImage(_localImagePath!));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggingOut) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(children: [_buildHeader(), Expanded(child: IndexedStack(index: _activeTab, children: [_buildBookingsTab(), _buildReviewsTab(), _buildAlertsTab(), _buildProfileTab()]))]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 24),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)])),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            GestureDetector(onTap: _pickLocalImage, child: Stack(children: [_buildProfileImage(radius: 25), const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 8, backgroundColor: Colors.white, child: Icon(Icons.camera_alt, size: 10, color: Colors.purple)))] )),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Provider Dashboard", style: TextStyle(color: Colors.white70, fontSize: 11)), Text(_businessNameController.text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
          ]),
          IconButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), icon: const Icon(Icons.home_outlined, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.white24)),
        ]),
        const SizedBox(height: 20),
        _buildLiveStats(),
      ]),
    );
  }

  Widget _buildLiveStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reviews').where('providerId', isEqualTo: widget.provider['uid']).snapshots(),
      builder: (context, snapshot) {
        double avgRating = 0.0;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          avgRating = snapshot.data!.docs.map((d) => d['rating'] as double).reduce((a, b) => a + b) / snapshot.data!.docs.length;
        }
        return Row(children: [
          _buildStatCard(avgRating.toStringAsFixed(1), "Rating"), 
          _buildStatCard(snapshot.hasData ? snapshot.data!.docs.length.toString() : "0", "Reviews"), 
          _buildStatCard(_categoryController.text.toUpperCase(), "Category")
        ]);
      },
    );
  }

  Widget _buildStatCard(String val, String lbl) => Expanded(
        child: Container(
          height: 85,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  val,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lbl,
                style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      );

  Widget _buildBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').where('providerId', isEqualTo: widget.provider['uid']).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No booking requests yet."));

        // Sort by eventDate descending (newest first)
        final sortedBookings = docs.toList()..sort((a, b) {
          String dateA = (a.data() as Map<String, dynamic>)['eventDate'] ?? '';
          String dateB = (b.data() as Map<String, dynamic>)['eventDate'] ?? '';
          return dateB.compareTo(dateA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: sortedBookings.length,
          itemBuilder: (context, index) {
            var booking = sortedBookings[index].data() as Map<String, dynamic>;
            var id = sortedBookings[index].id;
            return GestureDetector(
              onTap: () => _showBookingDetails(id, booking),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(booking['eventName'] ?? "Event", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), _buildStatusBadge(booking['status'] ?? "pending")]),
                  const Divider(height: 24),
                  _buildCompactRow("Date", booking['eventDate']),
                  const SizedBox(height: 8),
                  const Text("Tap to view full details", style: TextStyle(color: Color(0xFF9333EA), fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reviews').where('providerId', isEqualTo: widget.provider['uid']).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No feedback yet."));
        
        final reviews = snapshot.data!.docs.toList()..sort((a, b) {
          Timestamp? t1 = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          Timestamp? t2 = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (t1 == null) return -1;
          if (t2 == null) return 1;
          return t2.compareTo(t1);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: reviews.length,
          itemBuilder: (context, index) {
            var review = reviews[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(review['userName'] ?? "User"),
                subtitle: Text(review['comment'] ?? ""),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, color: Colors.orange, size: 16), Text(" ${review['rating']}")]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Notifications Center", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        _buildApprovalAlert(),
        const Divider(height: 32),
        _alertSectionHeader("System Notifications", Icons.notifications_active_outlined, Colors.purple),
        _buildSystemAlerts(),
        const SizedBox(height: 20),
        _alertSectionHeader("New Event Requests", Icons.mail_outline, Colors.blue),
        _buildBookingAlerts(),
        const SizedBox(height: 20),
        _alertSectionHeader("Recent Customer Feedback", Icons.star_outline, Colors.orange),
        _buildReviewAlerts(),
      ],
    );
  }

  Widget _buildSystemAlerts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: widget.provider['uid'])
          .where('status', isEqualTo: 'cancelled')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text("No important alerts.", style: TextStyle(color: Colors.grey, fontSize: 12));
        
        final cancelledBookings = snapshot.data!.docs.toList()..sort((a, b) {
          Timestamp? t1 = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          Timestamp? t2 = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (t1 == null) return 1;
          if (t2 == null) return -1;
          return t2.compareTo(t1);
        });

        return Column(
          children: cancelledBookings.map((doc) {
            var b = doc.data() as Map<String, dynamic>;
            return Card(
              elevation: 0,
              color: Colors.red[50],
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: Text("Booking Cancelled: ${b['eventName']}"),
                subtitle: Text("The customer '${b['userName']}' has cancelled this request."),
                onTap: () => _showBookingDetails(doc.id, b),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildApprovalAlert() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.provider['uid']).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var data = snapshot.data!.data() as Map<String, dynamic>;
        bool isApproved = data['isApproved'] == true;
        bool isRejected = data['isRejected'] == true;
        return Card(
          color: isApproved ? Colors.green[50] : (isRejected ? Colors.red[50] : Colors.blue[50]),
          child: ListTile(
            leading: Icon(isApproved ? Icons.verified : (isRejected ? Icons.block : Icons.hourglass_empty), color: isApproved ? Colors.green : (isRejected ? Colors.red : Colors.blue)),
            title: Text(isApproved ? "Business Approved!" : (isRejected ? "Access Restricted" : "Application Under Review")),
            subtitle: Text(isApproved ? "Your services are now visible to everyone." : (isRejected ? "An admin has rejected your application." : "Wait for admin approval to start.")),
          ),
        );
      },
    );
  }

  Widget _buildBookingAlerts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: widget.provider['uid'])
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text("Error: ${snapshot.error}");
        if (!snapshot.hasData) return const LinearProgressIndicator();
        
        final pendingRequests = snapshot.data!.docs;

        if (pendingRequests.isEmpty) {
          return const Text("No new requests.", style: TextStyle(color: Colors.grey, fontSize: 12));
        }

        // Sort in memory: Newest first
        final sortedRequests = pendingRequests.toList()..sort((a, b) {
          Timestamp? t1 = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          Timestamp? t2 = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (t1 == null) return 1;
          if (t2 == null) return -1;
          return t2.compareTo(t1);
        });

        return Column(
          children: sortedRequests.map((doc) {
            var b = doc.data() as Map<String, dynamic>;
            return Card(
              elevation: 0, 
              color: Colors.blue[50], 
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => _showBookingDetails(doc.id, b), 
                title: Text("New Request: ${b['eventName']}"), 
                subtitle: Text("Type: ${b['eventType']} • Customer: ${b['userName']}"),
                trailing: const Icon(Icons.fiber_new, color: Colors.blue),
              )
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildReviewAlerts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reviews').where('providerId', isEqualTo: widget.provider['uid']).limit(3).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text("No recent feedback.", style: TextStyle(color: Colors.grey, fontSize: 12));
        return Column(children: snapshot.data!.docs.map((doc) {
          var r = doc.data() as Map<String, dynamic>;
          return Card(elevation: 0, color: Colors.orange[50], child: ListTile(title: Text("${r['userName']} left a review"), trailing: Text("${r['rating']} ⭐")));
        }).toList());
      },
    );
  }

  Widget _alertSectionHeader(String title, IconData icon, Color color) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14))]));

  Widget _buildProfileTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.provider['uid']).snapshots(),
      builder: (context, snapshot) {
        String statusText = "Pending Review";
        if (snapshot.hasData) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          if (data['isApproved'] == true) statusText = "Approved";
          else if (data['isRejected'] == true) statusText = "Access Restricted";
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Business Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), TextButton(onPressed: () => setState(() => _isEditing = !_isEditing), child: Text(_isEditing ? "Cancel" : "Edit", style: const TextStyle(color: Color(0xFF9333EA))))]),
                _buildEditableField("Business Name", _businessNameController, Icons.business),
                _buildEditableField("Owner Name", _nameController, Icons.person),
                _buildCompactRow("Email", widget.provider['email']),
                _buildEditableField("Phone", _phoneController, Icons.phone),
                _buildEditableField("Category", _categoryController, Icons.category),
                _buildEditableField("Price", _priceController, Icons.currency_rupee),
                _buildEditableField("Description", _descController, Icons.description, isMultiLine: true),
                _buildCompactRow("Status", statusText),
              ]),
            ),
            const SizedBox(height: 20),
            _isEditing ? (_isSaving ? const CircularProgressIndicator() : _buildSaveButton()) : _buildLogoutButton(),
          ]),
        );
      }
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, {bool isMultiLine = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        _isEditing ? TextField(controller: controller, maxLines: isMultiLine ? 3 : 1, decoration: InputDecoration(prefixIcon: Icon(icon, size: 16), isDense: true, border: InputBorder.none))
                   : Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 8), Text(controller.text, style: const TextStyle(fontWeight: FontWeight.bold))]),
      ]),
    );
  }

  Widget _buildCompactRow(String label, String? value) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)), Text(value ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold))]));
  }

  Widget _detailLabel(String text) => Padding(padding: const EdgeInsets.only(top: 10, bottom: 2), child: Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)));

  Widget _buildSaveButton() => SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveProfileChanges, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9333EA)), child: const Text("Save Changes", style: TextStyle(color: Colors.white))));

  Widget _buildLogoutButton() => SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () async { setState(() => _isLoggingOut = true); await FirebaseAuth.instance.signOut(); Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const EventHelperHome()), (route) => false); }, icon: const Icon(Icons.logout, color: Colors.white), label: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))));

  Widget _buildStatusBadge(String status) {
    Color color = status == 'confirmed' ? Colors.green : (status == 'rejected' || status == 'cancelled' ? Colors.red : (status == 'completed' ? Colors.blue : Colors.orange));
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _activeTab, 
      onTap: (index) => setState(() => _activeTab = index), 
      type: BottomNavigationBarType.fixed, 
      selectedItemColor: const Color(0xFF9333EA), 
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: "Bookings"), 
        BottomNavigationBarItem(icon: Icon(Icons.rate_review_outlined), label: "Reviews"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Alerts"), 
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile")
      ]
    );
  }
}
