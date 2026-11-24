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
        SnackBar(content: Text(context.l10n.enterEmail)),
      );
      return;
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.invalidEmail)),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await FirebaseAuth.instance.setLanguageCode(context.appLanguageCode);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.resetLinkSent,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-email':
          message = context.l10n.invalidEmail;
          break;
        case 'too-many-requests':
          message = context.l10n.tooManyAttempts;
          break;
        case 'network-request-failed':
          message = context.l10n.checkInternet;
          break;
        default:
          message = context.l10n.requestFailed;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.somethingWentWrong),
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
                  decoration: InputDecoration(
                    labelText: context.l10n.email,
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
                        : Text(
                            context.l10n.resetPassword,
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
