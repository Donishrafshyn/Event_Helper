import 'package:flutter/material.dart';

class ServiceList extends StatefulWidget {
  final List<Map<String, dynamic>> services;
  final String category;
  final VoidCallback onBack;
  final Function(String serviceId) onSelectService;

  const ServiceList({
    super.key,
    required this.services,
    required this.category,
    required this.onBack,
    required this.onSelectService,
  });

  @override
  State<ServiceList> createState() => _ServiceListState();
}

class _ServiceListState extends State<ServiceList> {
  String _searchQuery = '';
  String _sortBy = 'rating';

  // Mapping category names for display
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

  @override
  Widget build(BuildContext context) {
    // Filter and Sort Logic
    List<Map<String, dynamic>> filtered = widget.services.where((service) {
      final nameMatches = service['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final categoryMatches = widget.category == 'all' || service['category'] == widget.category;
      return nameMatches && categoryMatches;
    }).toList();

    if (_sortBy == 'price-low') {
      filtered.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    } else if (_sortBy == 'price-high') {
      filtered.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(filtered.length),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildServiceCard(filtered[index]),
            ),
          ),
        ],
      ),
    );
  }

  // --- Header with Gradient, Search, and Sort Chips ---
  Widget _buildHeader(int count) {
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
                  Text("$count services available", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Bar
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search services...",
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white60),
              filled: true,
              fillColor: Colors.white24,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          // Sort Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip('rating', '⭐ Best Rated'),
                _buildSortChip('price-low', '💰 Price: Low to High'),
                _buildSortChip('price-high', '💎 Price: High to Low'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String value, String label) {
    bool isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? const Color(0xFF9333EA) : Colors.white,
          fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        )),
      ),
    );
  }

  // --- Service Card ---
  Widget _buildServiceCard(Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () => widget.onSelectService(service['id']),
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
            // Image with Availability Dot
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    service['images']?[0] ?? 'https://via.placeholder.com/150',
                    width: 90, height: 90, fit: BoxFit.cover,
                  ),
                ),
                if (service['availability'] == true)
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1),
                  Text(service['description'],
                      style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const Text(" 4.8", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Spacer(),
                      Text(_getPriceDisplay(service),
                          style: const TextStyle(color: Color(0xFF9333EA), fontWeight: FontWeight.bold)),
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

  String _getPriceDisplay(Map<String, dynamic> service) {
    if (service['priceType'] == 'negotiable') return 'Negotiable';
    String suffix = service['priceType'] == 'per-hour' ? '/hr' : (service['priceType'] == 'per-day' ? '/day' : '');
    return "\$${service['price']}$suffix";
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No services found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}