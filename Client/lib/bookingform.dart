import 'dart:io';
import 'package:flutter/material.dart';

// Data model matching your React interface
class BookingFormData {
  String serviceId = '';
  String eventName = '';
  String eventDate = '';
  String eventLocation = '';
  String eventType = '';
  int guestCount = 50;
  String customerPhone = ''; // Added field
  String message = '';

  BookingFormData({required this.serviceId});
}

class BookingForm extends StatefulWidget {
  final Map<String, dynamic> service;
  final VoidCallback onBack;
  final Function(BookingFormData data) onSubmit;

  const BookingForm({
    super.key,
    required this.service,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  late BookingFormData _formData;

  final List<String> _eventTypes = [
    'Wedding', 'Birthday Party', 'Corporate Event', 'Anniversary',
    'Engagement', 'Baby Shower', 'Graduation', 'Conference', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _formData = BookingFormData(serviceId: widget.service['id']?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar( // FIXED typo: changed appApp to appBar
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: widget.onBack,
        ),
        title: const Text("Book Service",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildServiceInfoCard(),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Event Name"),
                    _buildTextField(
                      hint: "e.g., Sarah & Michael's Wedding",
                      onSaved: (val) => _formData.eventName = val ?? '',
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("Event Type"),
                    _buildDropdown(),
                    const SizedBox(height: 20),

                    _buildLabel("Contact Number"), // Added field UI
                    _buildTextField(
                      hint: "Your mobile number",
                      icon: Icons.phone_android_outlined,
                      isNumber: true,
                      onSaved: (val) => _formData.customerPhone = val ?? '',
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("Event Date"),
                    _buildDatePicker(),
                    const SizedBox(height: 20),

                    _buildLabel("Event Location"),
                    _buildTextField(
                      hint: "Venue name and address",
                      icon: Icons.location_on_outlined,
                      onSaved: (val) => _formData.eventLocation = val ?? '',
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("Expected Guest Count"),
                    _buildTextField(
                      hint: "50",
                      icon: Icons.people_outline,
                      isNumber: true,
                      onSaved: (val) => _formData.guestCount = int.tryParse(val ?? '50') ?? 50,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("Additional Message"),
                    _buildTextField(
                      hint: "Any special requirements...",
                      icon: Icons.description_outlined,
                      maxLines: 4,
                      onSaved: (val) => _formData.message = val ?? '',
                    ),
                    const SizedBox(height: 32),

                    _buildSubmitButton(),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        "Your booking request will be sent to the service provider for confirmation.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfoCard() {
    String? path = widget.service['profileImage'] ?? widget.service['images']?[0];
    
    Widget imageWidget;
    if (path == null || path.isEmpty) {
      imageWidget = Container(
        width: 80, height: 80, color: Colors.grey[200],
        child: const Icon(Icons.business, color: Colors.grey),
      );
    } else {
      bool isLocal = path.startsWith('/') || path.contains(':\\');
      ImageProvider imageProvider = isLocal ? FileImage(File(path)) : NetworkImage(path) as ImageProvider;
      imageWidget = Image(image: imageProvider, width: 80, height: 80, fit: BoxFit.cover);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: imageWidget),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.service['businessName'] ?? widget.service['name'] ?? "No Name",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(widget.service['category'] ?? "Service",
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _buildTextField({
    required String hint,
    IconData? icon,
    required FormFieldSetter<String> onSaved,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      onSaved: onSaved,
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      hint: const Text("Select event type"),
      items: _eventTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
      onChanged: (val) => setState(() => _formData.eventType = val ?? ''),
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      readOnly: true,
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          setState(() => _formData.eventDate = picked.toString().split(' ')[0]);
        }
      },
      validator: (val) => (_formData.eventDate.isEmpty) ? "Required" : null,
      decoration: InputDecoration(
        hintText: _formData.eventDate.isEmpty ? "Select date" : _formData.eventDate,
        prefixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            widget.onSubmit(_formData);
          }
        },
        icon: const Icon(Icons.send, size: 18),
        label: const Text("Send Booking Request", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
