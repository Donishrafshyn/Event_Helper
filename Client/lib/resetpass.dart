import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final Function(String newPassword) onResetComplete;

  const ResetPasswordPage({super.key, required this.email, required this.onResetComplete});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text("Reset password for ${widget.email}",
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 24),
                _buildPasswordField(_passController, "New Password"),
                const SizedBox(height: 16),
                _buildPasswordField(_confirmPassController, "Confirm New Password"),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFDB2777)]),
      ),
      child: const Center(child: Text("Create New Password",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_passController.text == _confirmPassController.text) {
            widget.onResetComplete(_passController.text); //
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDB2777),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text("Update Password", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}