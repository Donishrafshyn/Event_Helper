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
  int _activeTab = 3; // Default to Profile for easier testing of this feature
  bool _isLoggingOut = false;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _localImagePath;

  // Controllers for editing
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
    
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.provider['name'] ?? '');
    _businessNameController = TextEditingController(text: widget.provider['businessName'] ?? '');
    _phoneController = TextEditingController(text: widget.provider['phone'] ?? '');
    _categoryController = TextEditingController(text: widget.provider['category'] ?? '');
    _priceController = TextEditingController(text: widget.provider['price']?.toString() ?? '');
    _descController = TextEditingController(text: widget.provider['description'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _descController.dispose();
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
      
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save Error: $e"), backgroundColor: Colors.red));
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile image updated!")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Firestore Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildProfileImage({double radius = 25}) {
    if (_localImagePath == null) {
      return CircleAvatar(radius: radius, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white, size: radius));
    }
    if (_localImagePath!.startsWith('/') || _localImagePath!.contains(':\\')) {
      return CircleAvatar(radius: radius, backgroundImage: FileImage(File(_localImagePath!)));
    }
    return CircleAvatar(radius: radius, backgroundImage: NetworkImage(_localImagePath!));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggingOut) {
      return const Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Logging out...")])));
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
                const Center(child: Text("Services list coming soon")),
                const Center(child: Text("Alerts coming soon")),
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
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)])),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(onTap: _pickLocalImage, child: Stack(children: [_buildProfileImage(radius: 25), const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 8, backgroundColor: Colors.white, child: Icon(Icons.camera_alt, size: 10, color: Colors.purple)))])),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Provider Dashboard", style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(_businessNameController.text.isEmpty ? "Business Name" : _businessNameController.text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
              IconButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } else {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const EventHelperHome()));
                  }
                },
                icon: const Icon(Icons.home_outlined, color: Colors.white), 
                style: IconButton.styleFrom(backgroundColor: Colors.white24)
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLiveStats(),
        ],
      ),
    );
  }

  Widget _buildLiveStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').where('providerId', isEqualTo: widget.provider['uid']).snapshots(),
      builder: (context, snapshot) {
        int pending = 0;
        int confirmed = 0;
        if (snapshot.hasData) {
          pending = snapshot.data!.docs.where((d) => d['status'] == 'pending').length;
          confirmed = snapshot.data!.docs.where((d) => d['status'] == 'confirmed').length;
        }
        return Row(children: [_buildStatCard(pending.toString(), "Pending"), _buildStatCard(confirmed.toString(), "Booked"), _buildStatCard(_categoryController.text.toUpperCase(), "Category")]);
      },
    );
  }

  Widget _buildStatCard(String value, String label) => Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: Column(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))])));

  Widget _buildBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').where('providerId', isEqualTo: widget.provider['uid']).snapshots(),
      builder: (context, snapshot) {
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
              margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(booking['eventName'] ?? "Event", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), _buildStatusBadge(booking['status'] ?? "pending")]),
                const SizedBox(height: 10),
                Text("Date: ${booking['eventDate']}", style: const TextStyle(color: Colors.grey)),
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: ElevatedButton(onPressed: () async => await FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': 'confirmed'}), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Accept", style: TextStyle(color: Colors.white)))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () async => await FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': 'rejected'}), child: const Text("Reject", style: TextStyle(color: Colors.red)))),
                  ])
                ]
              ]),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Business Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => setState(() => _isEditing = !_isEditing),
                  child: Text(_isEditing ? "Cancel" : "Edit", style: const TextStyle(color: Color(0xFF9333EA))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(child: GestureDetector(onTap: _pickLocalImage, child: _buildProfileImage(radius: 50))),
            const SizedBox(height: 20),
            _buildEditableField("Business Name", _businessNameController, Icons.business),
            _buildEditableField("Owner Name", _nameController, Icons.person),
            _buildProfileRow("Email (Read-only)", widget.provider['email'], icon: Icons.lock_outline),
            _buildEditableField("Phone", _phoneController, Icons.phone),
            _buildEditableField("Category", _categoryController, Icons.category),
            _buildEditableField("Starting Price", _priceController, Icons.currency_rupee),
            _buildEditableField("Description", _descController, Icons.description, isMultiLine: true),
            _buildProfileRow("Account Status", "✓ Approved", icon: Icons.verified_user),
          ]),
        ),
        const SizedBox(height: 20),
        _isEditing 
          ? (_isSaving ? const CircularProgressIndicator() : _buildSaveButton())
          : _buildLogoutButton(),
      ]),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, {bool isMultiLine = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          _isEditing 
            ? TextField(
                controller: controller,
                maxLines: isMultiLine ? 3 : 1,
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, size: 16, color: const Color(0xFF9333EA)),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              )
            : Row(
                children: [
                  Icon(icon, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(controller.text.isEmpty ? "Not set" : controller.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String? value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Row(
            children: [
              if (icon != null) Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(value ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveProfileChanges,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9333EA), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: const Text("Save All Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () async { setState(() => _isLoggingOut = true); await FirebaseAuth.instance.signOut(); if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const EventHelperHome()), (route) => false); }, icon: const Icon(Icons.logout, color: Colors.white), label: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))));
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'confirmed' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  }

  Widget _buildBottomNav() => BottomNavigationBar(currentIndex: _activeTab, onTap: (index) => setState(() => _activeTab = index), type: BottomNavigationBarType.fixed, selectedItemColor: const Color(0xFF9333EA), items: const [BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: "Bookings"), BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: "Services"), BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Alerts"), BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile")]);
}
