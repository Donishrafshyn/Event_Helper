import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceList extends StatefulWidget {
  final String category;
  final VoidCallback onBack;
  final Function(Map<String, dynamic> service) onSelectService;

  const ServiceList({
    super.key,
    required this.category,
    required this.onBack,
    required this.onSelectService,
  });

  @override
  State<ServiceList> createState() => _ServiceListState();
}

class _ServiceListState extends State<ServiceList> {
  String _searchQuery = '';

  final Map<String, String> _categoryNames = {
    'all': 'All Services',
    'decorator': 'Decorators',
    'photographer': 'Photographers',
    'dj': 'DJs',
    'caterer': 'Caterers',
    'sound-system': 'Sound Systems',
    'venue': 'Venues',
    'makeup': 'Makeup Artists',
    'anchoring': 'Anchoring Services',
    'dance-event': 'Dance Events'
  };

  Widget _buildProviderImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF9333EA).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.business, color: Color(0xFF9333EA), size: 32),
      );
    }

    bool isLocal = path.startsWith('/') || path.contains(':\\');
    ImageProvider imageProvider = isLocal ? FileImage(File(path)) : NetworkImage(path) as ImageProvider;

    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'provider')
                  .where('isApproved', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text("Error: ${snapshot.error}"),
                ));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                List<Map<String, dynamic>> providers = snapshot.data!.docs.map((doc) {
                  return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
                }).toList();

                if (widget.category != 'all') {
                  providers = providers.where((p) => p['category'] == widget.category).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  providers = providers.where((p) => 
                    (p['businessName'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                if (providers.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: providers.length,
                  itemBuilder: (context, index) => _buildServiceCard(providers[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.white24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_categoryNames[widget.category] ?? 'Services',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("Available providers", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search providers...",
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white60),
              filled: true,
              fillColor: Colors.white24,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> provider) {
    return GestureDetector(
      onTap: () => widget.onSelectService(provider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            _buildProviderImage(provider['profileImage']),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider['businessName'] ?? provider['name'] ?? "Provider",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1),
                  Text(provider['description'] ?? "Professional ${provider['category']} service.",
                      style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const Text(" 4.8", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Spacer(),
                      Text(provider['price'] != null ? "₹${provider['price']}" : "Details",
                          style: const TextStyle(color: Color(0xFF9333EA), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No ${widget.category} found", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
