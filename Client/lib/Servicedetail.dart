import 'dart:io';
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

  Widget _buildImageWidget(String? path, {double radius = 30, bool isFullHeader = false}) {
    if (path == null || path.isEmpty) {
      if (isFullHeader) {
        return Image.network('https://via.placeholder.com/400', fit: BoxFit.cover);
      }
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFF3E8FF),
        child: Text(provider['businessName']?[0] ?? "S",
            style: TextStyle(fontSize: radius * 0.8, color: const Color(0xFF9333EA))),
      );
    }

    bool isLocal = path.startsWith('/') || path.contains(':\\');
    ImageProvider imageProvider = isLocal ? FileImage(File(path)) : NetworkImage(path) as ImageProvider;

    if (isFullHeader) {
      return Image(image: imageProvider, fit: BoxFit.cover, width: double.infinity);
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: imageProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 200,
        leading: TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4B5563), size: 18),
          label: const Text("Back to Services", style: TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              children: [
                _buildImageHeader(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildServiceTitleCard(),
                      const SizedBox(height: 16),
                      _buildProviderCard(),
                      const SizedBox(height: 16),
                      _buildFeaturesCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildStickyFooter(context),
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    String? mainImage = provider['profileImage'];
    return Container(
      margin: const EdgeInsets.all(16),
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: _buildImageWidget(mainImage, isFullHeader: true)),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(30)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(service['name'] ?? provider['businessName'] ?? "Service", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFBBF24), size: 20),
              Text(" ${provider['rating'] ?? '4.8'}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Icon(Icons.verified_user_outlined, color: Color(0xFF3B82F6), size: 16),
              const Text(" Verified Provider", style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Text(provider['description'] ?? "No description available.", style: const TextStyle(color: Color(0xFF374151), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildProviderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Service Provider", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageWidget(provider['profileImage'], radius: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider['businessName'] ?? provider['name'] ?? "Provider", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(provider['category'] ?? "Event Services", style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    const SizedBox(height: 12),
                    _buildContactRow(Icons.phone_outlined, provider['phone'] ?? "N/A"),
                    _buildContactRow(Icons.mail_outline, provider['email'] ?? "N/A"),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's Included", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _FeatureRow("Professional Quality Service"),
          _FeatureRow("On-time delivery"),
          _FeatureRow("Certified experts"),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(BuildContext context) {
    // Look for price in both service and provider maps
    dynamic priceValue = service['price'] ?? provider['price'];
    String priceDisplay = priceValue != null ? "₹ $priceValue" : "Negotiable";

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Pricing", style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                Text(priceDisplay, style: const TextStyle(color: Color(0xFF9333EA), fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            ElevatedButton(
              onPressed: isAuthenticated ? () => onBookNow(provider['id'] ?? '') : (provider['role'] == 'user' ? onLogin : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAuthenticated ? const Color(0xFF9333EA) : Colors.grey[400], 
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: Text(
                isAuthenticated 
                  ? "Book Now" 
                  : (provider['role'] == 'user' ? "Sign In to Book" : "View Only Mode"), 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [Icon(icon, size: 14, color: const Color(0xFF6B7280)), const SizedBox(width: 8), Text(text, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13))]),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20), const SizedBox(width: 10), Text(text, style: const TextStyle(color: Color(0xFF374151), fontSize: 15))]),
    );
  }
}
