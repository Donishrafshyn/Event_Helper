import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  final Function(String email) onVerifyEmail;

  const ForgotPasswordPage({super.key, required this.onVerifyEmail});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Reset Your Password",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Enter your email to verify if an account exists.",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                _buildTextField(emailController, "Email Address", Icons.email_outlined),
                const SizedBox(height: 24),
                _buildSubmitButton(() => onVerifyEmail(emailController.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reuse your existing gradient header style
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]),
      ),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
          const Text("Forgot Password", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildSubmitButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9333EA),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text("Verify Email", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}