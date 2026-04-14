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
  String _sortBy = 'name_asc'; // name_asc, name_desc, rating, price_asc, price_desc

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
          _buildSortBar(),
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

                // Since we need to sort by rating which is in a different collection,
                // we'll use a Future to get all ratings first if sorting by rating is selected.
                // However, for performance and simplicity in this UI, we'll fetch providers 
                // and then sort them.
                
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getProcessedProviders(snapshot.data!.docs),
                  builder: (context, providerSnapshot) {
                    if (!providerSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    List<Map<String, dynamic>> providers = providerSnapshot.data!;

                    if (providers.isEmpty) return _buildEmptyState();

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: providers.length,
                      itemBuilder: (context, index) => _buildServiceCard(providers[index]),
                    );
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getProcessedProviders(List<QueryDocumentSnapshot> docs) async {
    List<Map<String, dynamic>> providers = docs.map((doc) {
      return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
    }).toList();

    // Filter by category
    if (widget.category != 'all') {
      providers = providers.where((p) => p['category'] == widget.category).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      providers = providers.where((p) => 
        (p['businessName'] ?? p['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Attach average ratings for sorting
    for (var p in providers) {
      String pid = p['uid'] ?? p['id'];
      var reviewSnap = await FirebaseFirestore.instance.collection('reviews').where('providerId', isEqualTo: pid).get();
      if (reviewSnap.docs.isEmpty) {
        p['avgRating'] = 0.0;
        p['reviewCount'] = 0;
      } else {
        double total = 0;
        for (var d in reviewSnap.docs) {
          total += (d.data())['rating'] ?? 0;
        }
        p['avgRating'] = total / reviewSnap.docs.length;
        p['reviewCount'] = reviewSnap.docs.length;
      }
    }

    // Sort
    providers.sort((a, b) {
      switch (_sortBy) {
        case 'name_asc':
          return (a['businessName'] ?? a['name'] ?? '').toString().compareTo((b['businessName'] ?? b['name'] ?? '').toString());
        case 'name_desc':
          return (b['businessName'] ?? b['name'] ?? '').toString().compareTo((a['businessName'] ?? a['name'] ?? '').toString());
        case 'rating':
          return (b['avgRating'] as double).compareTo(a['avgRating'] as double);
        case 'price_asc':
          double priceA = double.tryParse(a['price']?.toString() ?? '0') ?? 0;
          double priceB = double.tryParse(b['price']?.toString() ?? '0') ?? 0;
          return priceA.compareTo(priceB);
        case 'price_desc':
          double priceA = double.tryParse(a['price']?.toString() ?? '0') ?? 0;
          double priceB = double.tryParse(b['price']?.toString() ?? '0') ?? 0;
          return priceB.compareTo(priceA);
        default:
          return 0;
      }
    });

    return providers;
  }

  Widget _buildSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.sort, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          const Text("Sort by:", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _sortChip("A-Z", 'name_asc'),
                  _sortChip("Z-A", 'name_desc'),
                  _sortChip("Rating", 'rating'),
                  _sortChip("Price Low-High", 'price_asc'),
                  _sortChip("Price High-Low", 'price_desc'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, String value) {
    bool isSelected = _sortBy == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) setState(() => _sortBy = value);
        },
        selectedColor: const Color(0xFF9333EA),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
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
                      Text(provider['reviewCount'] == 0 ? " New" : " ${provider['avgRating'].toStringAsFixed(1)} (${provider['reviewCount']})", 
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
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
