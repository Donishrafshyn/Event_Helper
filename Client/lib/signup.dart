import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

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
  final Function(SignupData data)? onSignup;
  final VoidCallback? onBackToHome;
  final VoidCallback? onSwitchToLogin;

  const SignupPage({
    super.key,
    this.onSignup,
    this.onBackToHome,
    this.onSwitchToLogin,
  });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final SignupData _formData = SignupData();
  bool _isLoading = false;

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

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _formData.email.trim(),
        password: _formData.password.trim(),
      );

      Map<String, dynamic> userProfile = {
        'uid': userCredential.user!.uid,
        'name': _formData.name.trim(),
        'email': _formData.email.trim(),
        'phone': _formData.phone.trim(),
        'role': _formData.role.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_formData.role == UserRole.provider) {
        userProfile['businessName'] = _formData.businessName?.trim();
        userProfile['category'] = _formData.category;
        userProfile['description'] = _formData.description?.trim();
        userProfile['isApproved'] = false;
      }

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userProfile);
      } catch (firestoreError) {
        await userCredential.user?.delete();
        throw Exception("Firestore Error: $firestoreError");
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account created! Please login.")));
      
      // Fix: Force navigation to Login screen after success
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Auth Error: ${e.message}")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("General Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Register As"),
                    _buildRoleToggle(),
                    const SizedBox(height: 20),
                    _buildLabel("Full Name"),
                    _buildTextField(hint: "John Doe", icon: Icons.person_outline, onSaved: (val) => _formData.name = val ?? ''),
                    const SizedBox(height: 20),
                    _buildLabel("Email Address"),
                    _buildTextField(hint: "your@email.com", icon: Icons.mail_outline, onSaved: (val) => _formData.email = val ?? ''),
                    const SizedBox(height: 20),
                    _buildLabel("Phone Number"),
                    _buildTextField(hint: "+1234567890", icon: Icons.phone_outlined, onSaved: (val) => _formData.phone = val ?? ''),
                    if (_formData.role == UserRole.provider) ...[
                      const SizedBox(height: 20),
                      _buildLabel("Business Name"),
                      _buildTextField(hint: "Your Business Name", icon: Icons.business_outlined, onSaved: (val) => _formData.businessName = val),
                      const SizedBox(height: 20),
                      _buildLabel("Service Category"),
                      _buildDropdownField(),
                      const SizedBox(height: 20),
                      _buildLabel("Business Description"),
                      _buildTextField(hint: "Describe your services...", icon: Icons.description_outlined, maxLines: 3, onSaved: (val) => _formData.description = val),
                    ],
                    const SizedBox(height: 20),
                    _buildLabel("Password"),
                    _buildTextField(hint: "Create a password", icon: Icons.lock_outline, isPassword: true, onSaved: (val) => _formData.password = val ?? ''),
                    const SizedBox(height: 32),
                    _isLoading ? const Center(child: CircularProgressIndicator()) : _buildSubmitButton(),
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
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)])),
      child: Row(
        children: [
          IconButton(onPressed:() {
            // Fix: Fallback navigation
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginPage()));
            }
          }, icon: const Icon(Icons.arrow_back, color: Colors.white)),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text("Join our event platform", style: TextStyle(color: Colors.white70, fontSize: 12)),
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
          decoration: BoxDecoration(color: isSelected ? const Color(0xFFFAF5FF) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? const Color(0xFF9333EA) : Colors.grey.shade200, width: 2)),
          child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF9333EA) : Colors.grey))),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)));

  Widget _buildTextField({required String hint, required IconData icon, required FormFieldSetter<String> onSaved, bool isPassword = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: TextFormField(
        obscureText: isPassword,
        maxLines: maxLines,
        onSaved: onSaved,
        validator: (val) => (val == null || val.isEmpty) ? "Field required" : null,
        decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: Colors.grey), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15)),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _formData.category,
          hint: const Text("Select category"),
          items: _categories.map((cat) => DropdownMenuItem(value: cat['value'], child: Text(cat['label']!))).toList(),
          onChanged: (val) => setState(() => _formData.category = val),
          validator: (val) => (val == null) ? "Please select a category" : null,
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]), borderRadius: BorderRadius.circular(15)),
        child: ElevatedButton(
          onPressed: _handleSignup,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          child: const Text("Create Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          // Fix: Force navigation to Login
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        },
        child: RichText(
          text: const TextSpan(
            text: "Already have an account? ",
            style: TextStyle(color: Colors.grey, fontSize: 14),
            children: [TextSpan(text: "Sign In", style: TextStyle(color: Color(0xFF9333EA), fontWeight: FontWeight.bold))],
          ),
        ),
      ),
    );
  }
}
