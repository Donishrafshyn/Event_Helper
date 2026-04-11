import 'package:event/signup.dart';
import 'package:event/verifymail.dart';
import 'package:event/home.dart'; // Import EventHelperHome
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your dashboards
import 'Admindashboard.dart';
import 'Userdashboard.dart'; 
import 'Providerdashboard.dart';

enum UserRole { user, provider, admin }

class LoginPage extends StatefulWidget {
  final Function(String email, String password, UserRole role)? onLogin;
  final VoidCallback? onSwitchToSignup;

  const LoginPage({
    super.key,
    this.onLogin,
    this.onSwitchToSignup,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.user;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const EventHelperHome()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const EventHelperHome()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        String roleInDb = userDoc.get('role');
        
        if (roleInDb.toLowerCase() == _selectedRole.name.toLowerCase()) {
          if (!mounted) return;
          _navigateByRole(_selectedRole, userDoc.data() as Map<String, dynamic>);
        } else {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Account Error: You are registered as a $roleInDb, but selected ${_selectedRole.name}")),
          );
        }
      } else {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User profile not found in database")),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? "Login failed";
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateByRole(UserRole role, Map<String, dynamic> userData) {
    Widget nextScreen;
    switch (role) {
      case UserRole.admin:
        nextScreen = AdminDashboard(
          admin: userData,
          onHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
          onLogout: () => _handleLogout(context),
        );
        break;
      case UserRole.provider:
        nextScreen = ProviderDashboard(
          provider: userData,
          onHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
          onLogout: () => _handleLogout(context),
        );
        break;
      case UserRole.user:
        nextScreen = UserDashboard(
          user: userData,
          onHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
          onLogout: () => _handleLogout(context),
        );
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Login As", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  _buildRoleSelector(),
                  const SizedBox(height: 24),
                  _buildLabel("Email Address"),
                  _buildTextField(_emailController, "your@email.com", Icons.mail_outline),
                  const SizedBox(height: 20),
                  _buildLabel("Password"),
                  _buildTextField(_passwordController, "Enter your password", Icons.lock_outline, isPassword: true),
                  const SizedBox(height: 32),
                  _isLoading ? const Center(child: CircularProgressIndicator()) : _buildSubmitButton(),
                  const SizedBox(height: 24),
                  _buildFooterLinks(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text("Welcome back!", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: UserRole.values.map((role) {
        bool isSelected = _selectedRole == role;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedRole = role),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFAF5FF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? const Color(0xFF9333EA) : Colors.grey.shade200, width: 2),
              ),
              child: Center(
                child: Text(role.name.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF9333EA) : Colors.grey)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500))
  );

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200)
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
          onPressed: _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("Sign In", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignupPage(
              onSignup: (data){}, 
              onBackToHome: () => Navigator.pop(context), 
              onSwitchToLogin: () => Navigator.pop(context)
            ))),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
                children: [
                  TextSpan(text: "Don't have an account? "),
                  TextSpan(text: "Sign Up", style: TextStyle(color: Color(0xFF9333EA), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordPage(onVerifyEmail: (e){}))),
            child: const Text("Forgot your password? Reset", style: TextStyle(color: Color(0xFF9333EA), fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}
