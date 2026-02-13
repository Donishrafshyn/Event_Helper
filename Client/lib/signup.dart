import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'login.dart';


// Enum and Data Model to match your React types
enum UserRole { user, provider, admin }

class SignupData {
  String name = '';
  String email = '';
  String password = '';
  String phone = '';
  UserRole role = UserRole.user;
  String? businessName;
  String? description;
  String? category;

  SignupData();
}

class SignupPage extends StatefulWidget {
  final Function(SignupData data) onSignup;
  final VoidCallback onBackToHome;
  final VoidCallback onSwitchToLogin;

  const SignupPage({
    super.key,
    required this.onSignup,
    required this.onBackToHome,
    required this.onSwitchToLogin,
  });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final SignupData _formData = SignupData();

  // Categories list matching your React component
  final List<Map<String, String>> _categories = [
    {'value': 'decorator', 'label': 'Decorator'},
    {'value': 'photographer', 'label': 'Photographer'},
    {'value': 'dj', 'label': 'DJ'},
    {'value': 'caterer', 'label': 'Caterer'},
    {'value': 'sound-system', 'label': 'Sound System'},
    {'value': 'venue', 'label': 'Venue'},
    {'value': 'videographer', 'label': 'Videographer'},
    {'value': 'makeup', 'label': 'Makeup Artist'},
    {'value': 'anchoring', 'label': 'Anchoring/Host'},
    {'value': 'dance-event', 'label': 'Dance Event'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // 1. Gradient Header
          _buildHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Register As Toggle
                    _buildLabel("Register As"),
                    _buildRoleToggle(),

                    const SizedBox(height: 20),

                    // 3. Basic Info Fields
                    _buildLabel("Full Name"),
                    _buildTextField(
                      hint: "John Doe",
                      icon: Icons.person_outline,
                      onSaved: (val) => _formData.name = val ?? '',
                    ),

                    const SizedBox(height: 20),

                    _buildLabel("Email Address"),
                    _buildTextField(
                      hint: "your@email.com",
                      icon: Icons.mail_outline,
                      onSaved: (val) => _formData.email = val ?? '',
                    ),

                    const SizedBox(height: 20),

                    _buildLabel("Phone Number"),
                    _buildTextField(
                      hint: "+1234567890",
                      icon: Icons.phone_outlined,
                      onSaved: (val) => _formData.phone = val ?? '',
                    ),

                    // 4. Conditional Provider Fields
                    if (_formData.role == UserRole.provider) ...[
                      const SizedBox(height: 20),
                      _buildLabel("Business Name"),
                      _buildTextField(
                        hint: "Your Business Name",
                        icon: Icons.business_outlined,
                        onSaved: (val) => _formData.businessName = val,
                      ),

                      const SizedBox(height: 20),
                      _buildLabel("Service Category"),
                      _buildDropdownField(),

                      const SizedBox(height: 20),
                      _buildLabel("Business Description"),
                      _buildTextField(
                        hint: "Describe your services...",
                        icon: Icons.description_outlined,
                        maxLines: 3,
                        onSaved: (val) => _formData.description = val,
                      ),
                    ],

                    const SizedBox(height: 20),

                    _buildLabel("Password"),
                    _buildTextField(
                      hint: "Create a password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      onSaved: (val) => _formData.password = val ?? '',
                    ),

                    const SizedBox(height: 32),

                    // 5. Submit Button
                    _buildSubmitButton(),

                    // 6. Login Toggle
                    _buildLoginLink(),
                  ],
                ),
              ),
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
        gradient: LinearGradient(
          colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed:() => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Create Account",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text("Join our event platform",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Row(
      children: [
        _roleButton("User", UserRole.user),
        const SizedBox(width: 10),
        _roleButton("Service Provider", UserRole.provider),
      ],
    );
  }

  Widget _roleButton(String label, UserRole role) {
    bool isSelected = _formData.role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _formData.role = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFAF5FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF9333EA) : Colors.grey.shade200,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF9333EA) : Colors.grey,
                )),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required FormFieldSetter<String> onSaved,
    bool isPassword = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        obscureText: isPassword,
        maxLines: maxLines,
        onSaved: onSaved,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _formData.category,
          hint: const Text("Select category"),
          items: _categories.map((cat) {
            return DropdownMenuItem(
              value: cat['value'],
              child: Text(cat['label']!),
            );
          }).toList(),
          onChanged: (val) => setState(() => _formData.category = val),
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              widget.onSignup(_formData);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("Create Account",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPage(
                // Remove explicit types (String, String) to fix assignment error
                onLogin: (email, password, role) {
                  print("Login success logic for $email");
                },
                onSwitchToSignup: () {
                  Navigator.pop(context); // Go back if already on signup
                },
              ),
            ),
          );
        },
        child: RichText(
          text: const TextSpan(
            text: "Already have an account? ",
            style: TextStyle(color: Colors.grey, fontSize: 14),
            children: [
              TextSpan(
                text: "Sign In",
                style: TextStyle(
                  color: Color(0xFF9333EA),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }}