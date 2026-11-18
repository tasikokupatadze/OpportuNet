import 'app_ui.dart';

import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPassScreen extends StatefulWidget {
  const ResetPassScreen({super.key});

  @override
  State<ResetPassScreen> createState() => _ResetPassScreenState();
}

class _ResetPassScreenState extends State<ResetPassScreen> {
  final TextEditingController _emailresetctrl = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailresetctrl.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    if (_isSending) return;
    final email = _emailresetctrl.text.trim();

    // Check for empty email
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email address")),
      );
      return;
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address")),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "If an account exists for this email, "
            "you will receive a password reset link.",
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-email':
          message = "Please enter a valid email address.";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Please try again later.";
          break;
        case 'network-request-failed':
          message = "Check your internet connection.";
          break;
        default:
          message = "Unable to process your request. Please try again.";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong. Please try again."),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset('assets/opportunet1.png', height: 55),
      ),
      body: SafeArea(
        top: false,
        child: ContentWidth(
          maxWidth: 480,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _emailresetctrl,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : resetPassword,
                    child: _isSending
                        ? const BusyIndicator()
                        : const Text(
                            "Reset Password",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
