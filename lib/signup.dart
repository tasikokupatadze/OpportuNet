import 'notification_service.dart';
import 'app_ui.dart';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isPswrdHidden = true;
  bool _acceptedTerms = false;
  bool _isSigningUp = false;

  final TextEditingController signupemailctrl = TextEditingController();
  final TextEditingController pswrdctrl = TextEditingController();
  final TextEditingController confirmPswrdctrl = TextEditingController();
  final TextEditingController namectrl = TextEditingController();
  final TextEditingController surnamectrl = TextEditingController();

  bool isPasswordValid(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Za-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  @override
  void dispose() {
    namectrl.dispose();
    surnamectrl.dispose();
    signupemailctrl.dispose();
    pswrdctrl.dispose();
    confirmPswrdctrl.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
    required BuildContext context,
  }) {
    const brand = Color(0xff84d6fe);
    const darkBrand = Color(0xff2b88b4);

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: darkBrand),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: brand, width: 2),
      ),
    );
  }

  Future<void> openLink(String link) async {
    final url = Uri.parse(link);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xff84d6fe);
    const darkBrand = Color(0xff2b88b4);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 48,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Image.asset(
          'assets/opportunet1.png',
          height: 42,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 29),
                  // NAME
                  TextField(
                    controller: namectrl,
                    keyboardType: TextInputType.name,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r"[a-zA-Zა-ჰ\s'-]"),
                      ),
                    ],
                    decoration: fieldDecoration(
                      label: "Name",
                      icon: Icons.person_outline,
                      context: context,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // SURNAME
                  TextField(
                    controller: surnamectrl,
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r"[a-zA-Zა-ჰ\s'-]"),
                      ),
                    ],
                    decoration: fieldDecoration(
                      label: "Surname",
                      icon: Icons.badge_outlined,
                      context: context,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // EMAIL
                  TextField(
                    controller: signupemailctrl,
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9@._-]'),
                      ),
                    ],
                    decoration: fieldDecoration(
                      label: "Email",
                      icon: Icons.email_outlined,
                      context: context,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // PASSWORD
                  TextField(
                    controller: pswrdctrl,
                    obscureText: _isPswrdHidden,
                    decoration: fieldDecoration(
                      label: "Password",
                      icon: Icons.lock_outline,
                      context: context,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPswrdHidden
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPswrdHidden = !_isPswrdHidden;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // CONFIRM PASSWORD
                  TextField(
                    controller: confirmPswrdctrl,
                    obscureText: _isPswrdHidden,
                    decoration: fieldDecoration(
                      label: "Confirm password",
                      icon: Icons.lock_outline,
                      context: context,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPswrdHidden
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPswrdHidden = !_isPswrdHidden;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // TERMS AND CONDITIONS
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: brand,
                    value: _acceptedTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptedTerms = value ?? false;
                      });
                    },
                    title: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 13,
                        ),
                        children: [
                          const TextSpan(text: "I agree to the "),
                          TextSpan(
                            text: "Terms & Conditions",
                            style: const TextStyle(
                              color: darkBrand,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                openLink(
                                  "https://docs.google.com/document/d/1mnCgKafSmjXpOZLhBrfHs9Dq5bXT9bx06oZ_BBjXV6k/edit?usp=sharing",
                                );
                              },
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: const TextStyle(
                              color: darkBrand,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                openLink(
                                  "https://docs.google.com/document/d/1ZVM54y9rXpq_vEWOW-5cO6KEZH0koECwn-ivQEDhuaw/edit?usp=sharing",
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // SIGN UP BUTTON
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSigningUp
                          ? null
                          : () async {
                              if (namectrl.text.trim().isEmpty ||
                                  surnamectrl.text.trim().isEmpty ||
                                  pswrdctrl.text.isEmpty ||
                                  signupemailctrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please fill all fields."),
                                  ),
                                );
                                return;
                              }

                              if (!signupemailctrl.text.contains("@") ||
                                  !signupemailctrl.text.contains(".")) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please enter a valid email.",
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (!isPasswordValid(pswrdctrl.text)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Password must contain at least 8 characters, one letter and one number.",
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (pswrdctrl.text != confirmPswrdctrl.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Passwords do not match."),
                                  ),
                                );
                                return;
                              }

                              if (!_acceptedTerms) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "You must accept the terms and privacy policy.",
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isSigningUp = true);
                              try {
                                final email = signupemailctrl.text.trim();

                                final userCredential = await FirebaseAuth
                                    .instance
                                    .createUserWithEmailAndPassword(
                                  email: email,
                                  password: pswrdctrl.text,
                                );

                                final user = userCredential.user!;

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .set({
                                  'name': namectrl.text.trim(),
                                  'surname': surnamectrl.text.trim(),
                                  'email': email,
                                  'role': 'user',
                                  'aboutMe': '',
                                  'profileImage': '',
                                  'age': '',
                                  'requiresEmailVerification': true,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                                await user.sendEmailVerification();
                                await NotificationService.instance.signOut();

                                if (!context.mounted) return;

                                await showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Verify your email'),
                                    content: const Text(
                                      'We sent a verification link to your email address. Please verify your email before logging in.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                        },
                                        child: const Text(
                                          'OK',
                                          style: TextStyle(color: darkBrand),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (!context.mounted) return;
                                Navigator.pop(context);
                              } on FirebaseAuthException catch (e) {
                                String message =
                                    'Registration failed. Please try again.';

                                if (e.code == 'email-already-in-use') {
                                  message = 'This email is already registered.';
                                } else if (e.code == 'weak-password') {
                                  message =
                                      'Please choose a stronger password.';
                                } else if (e.code == 'invalid-email') {
                                  message = 'Please enter a valid email.';
                                }

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              } catch (e) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Your account could not be fully created. Please try again.',
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isSigningUp = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brand,
                        foregroundColor: brandInk,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSigningUp
                          ? const BusyIndicator()
                          : const Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // LOGIN LINK
                  Center(
                    child: TextButton(
                      onPressed: _isSigningUp
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(48, 48),
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const TextSpan(
                              text: "Log in",
                              style: TextStyle(
                                color: darkBrand,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
