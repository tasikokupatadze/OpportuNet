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
                      label: context.l10n.name,
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
                      label: context.l10n.surname,
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
                      label: context.l10n.email,
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
                      label: context.l10n.password,
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
                      label: context.l10n.confirmPassword,
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
                          TextSpan(text: context.l10n.agreePrefix),
                          TextSpan(
                            text: context.l10n.terms,
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
                          TextSpan(text: context.l10n.and),
                          TextSpan(
                            text: context.l10n.privacyPolicy,
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
                                  SnackBar(
                                    content: Text(context.l10n.fillAllFields),
                                  ),
                                );
                                return;
                              }

                              if (!signupemailctrl.text.contains("@") ||
                                  !signupemailctrl.text.contains(".")) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.invalidEmail,
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (!isPasswordValid(pswrdctrl.text)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.passwordRule,
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (pswrdctrl.text != confirmPswrdctrl.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.l10n.passwordsDontMatch),
                                  ),
                                );
                                return;
                              }

                              if (!_acceptedTerms) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.mustAcceptTerms,
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isSigningUp = true);
                              var accountCreated = false;
                              try {
                                await FirebaseAuth.instance.setLanguageCode(
                                    context.appLanguageCode);
                                final email = signupemailctrl.text.trim();

                                final userCredential = await FirebaseAuth
                                    .instance
                                    .createUserWithEmailAndPassword(
                                  email: email,
                                  password: pswrdctrl.text,
                                );
                                accountCreated = true;

                                final user = userCredential.user!;

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .set({
                                  'name': namectrl.text.trim(),
                                  'surname': surnamectrl.text.trim(),
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
                                    title: Text(context.l10n.verifyEmailTitle),
                                    content: Text(
                                      context.l10n.verifyEmailBody,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                        },
                                        child: Text(
                                          context.l10n.ok,
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
                                    context.l10n.registrationFailed;

                                if (e.code == 'email-already-in-use') {
                                  message = context.l10n.emailInUse;
                                } else if (e.code == 'weak-password') {
                                  message =
                                      context.l10n.strongerPassword;
                                } else if (e.code == 'invalid-email') {
                                  message = context.l10n.invalidEmail;
                                }

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              } catch (e) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      accountCreated
                                          ? context.l10n.accountPartlyCreated
                                          : context.l10n.registrationFailed,
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
                          : Text(
                              context.l10n.createAccount,
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
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(context.l10n.haveAccount),
                        TextButton(
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
                          child: Text(
                            context.l10n.logIn,
                            style: TextStyle(
                              color: darkBrand,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
