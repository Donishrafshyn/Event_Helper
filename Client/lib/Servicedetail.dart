import 'package:flutter/material.dart';

class ServiceDetail extends StatelessWidget {
  final Map<String, dynamic> service;
  final Map<String, dynamic> provider;
  final VoidCallback onBack;
  final Function(String serviceId) onBookNow;
  final bool isAuthenticated;
  final VoidCallback onLogin;

  const ServiceDetail({
    super.key,
    required this.service,
    required this.provider,
    required this.onBack,
    required this.onBookNow,
    required this.isAuthenticated,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Matching bg-gray-50
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 200,
        leading: TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4B5563), size: 18),
          label: const Text("Back to Services",
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120), // Padding for sticky footer
            child: Column(
              children: [
                // 1. Image Header with "Available" Badge
                _buildImageHeader(),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 2. Service Title Card
                      _buildServiceTitleCard(),
                      const SizedBox(height: 16),

                      // 3. Service Provider Card
                      _buildProviderCard(),
                      const SizedBox(height: 16),

                      // 4. What's Included Card
                      _buildFeaturesCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. Sticky Bottom Price Bar
          _buildStickyFooter(),
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    final List images = service['images'] ?? [];
    return Container(
      margin: const EdgeInsets.all(16),
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(images.isNotEmpty ? images[0] : 'https://via.placeholder.com/400'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981), // Green-500
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text("Available", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTitleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(service['name'] ?? "Wedding Decoration Package",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFBBF24), size: 20),
              Text(" ${provider['rating'] ?? '4.8'}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(" (${provider['reviewCount'] ?? '127'} reviews)", style: const TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(width: 8),
              const Icon(Icons.verified_user_outlined, color: Color(0xFF3B82F6), size: 16),
              const Text(" Verified Provider", style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            service['description'] ?? "Complete wedding venue decoration including floral arrangements, lighting, and stage setup",
            style: const TextStyle(color: Color(0xFF374151), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Service Provider", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFF3E8FF),
                child: Text(provider['businessName']?[0] ?? "S",
                    style: const TextStyle(fontSize: 24, color: Color(0xFF9333EA))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider['businessName'] ?? "Elegant Decor Studio",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(provider['description'] ?? "Premium event decoration services with 10+ years of experience",
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    const SizedBox(height: 12),
                    _buildContactRow(Icons.phone_outlined, provider['phone'] ?? "+1234567891"),
                    _buildContactRow(Icons.mail_outline, provider['email'] ?? "sarah@elegantdecor.com"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    final List features = service['features'] ?? ['Floral arrangements', 'Stage decoration', 'LED lighting', 'Table centerpieces', 'Backdrop design'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("What's Included", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 10),
                Text(feature.toString(), style: const TextStyle(color: Color(0xFF374151), fontSize: 15)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildStickyFooter() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Fixed Price", style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                Text("\$${service['price'] ?? '2500'}",
                    style: const TextStyle(color: Color(0xFF9333EA), fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
            ElevatedButton(
              onPressed: isAuthenticated ? () => onBookNow(service['id']) : onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isAuthenticated ? "Book Now" : "Sign In to Book",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        ],
      ),
    );
  }
}