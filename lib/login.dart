import 'notification_service.dart';
import 'app_ui.dart';

import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'signup.dart';
import 'main.dart';
import 'resetpass.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

AuthCredential? pendingGoogleCredential;
Future<void>? _googleSignInInitialization;

Future<UserCredential?> signInWithGoogleWeb() async {
  try {
    final provider = GoogleAuthProvider();
    final userCredential = await FirebaseAuth.instance.signInWithPopup(
      provider,
    );

    final user = userCredential.user;
    if (user != null) {
      await createUserDoc(user);
    }

    return userCredential;
  } catch (e) {
    return null;
  }
}

Future<void> createUserDoc(User user, {String? name, String? surname}) async {
  final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

  final snapshot = await userRef.get();

  if (!snapshot.exists) {
    final displayName = user.displayName ?? '';
    final nameParts = displayName.trim().split(RegExp(r'\s+'));

    await userRef.set({
      'name': name ?? (nameParts.isNotEmpty ? nameParts.first : ''),
      'surname':
          surname ?? (nameParts.length > 1 ? nameParts.skip(1).join(' ') : ''),
      'role': 'user',
      'aboutMe': '',
      'profileImage': '',
      'age': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

Future<void> linkGoogle() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  if (kIsWeb) {
    await user.linkWithPopup(GoogleAuthProvider());
    return;
  }

  final credential = await _nativeGoogleCredential();
  if (credential == null) {
    await user.linkWithProvider(GoogleAuthProvider());
    return;
  }
  await user.linkWithCredential(credential);
}

/// Gets a Google credential from the native Android/iOS account picker.
///
/// Returns null when the device can't show it (for example an Android
/// device or emulator without Google Play services), so callers can fall
/// back to Firebase's browser-based Google sign-in.
Future<AuthCredential?> _nativeGoogleCredential() async {
  try {
    await handleNativeGoogleSignInInitialization();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-id-token-missing',
        message: 'Google did not return an ID token.',
      );
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.providerConfigurationError ||
        e.code == GoogleSignInExceptionCode.uiUnavailable) {
      debugPrint(
          'Native Google sign-in unavailable (${e.description}); using browser flow.');
      return null;
    }
    rethrow;
  }
}

Future<UserCredential?> signInWithEmailAutoLink(
  String email,
  String password,
) async {
  try {
    final userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    final user = userCredential.user;

    if (user != null) {
      await createUserDoc(user);

      if (pendingGoogleCredential != null) {
        await user.linkWithCredential(pendingGoogleCredential!);
        pendingGoogleCredential = null;
      }
    }

    return userCredential;
  } on FirebaseAuthException {
    rethrow;
  }
}

Future<void> handleNativeGoogleSignInInitialization() async {
  await (_googleSignInInitialization ??= GoogleSignIn.instance.initialize(
    serverClientId:
        '150055874798-uh56m7jqp34l662qqie29u3rpev8n32k.apps.googleusercontent.com',
  ));
}

Future<UserCredential?> handleGoogleAutoLink() async {
  try {
    late UserCredential userCredential;

    if (kIsWeb) {
      userCredential = await FirebaseAuth.instance.signInWithPopup(
        GoogleAuthProvider(),
      );
    } else {
      final credential = await _nativeGoogleCredential();
      userCredential = credential == null
          ? await FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider())
          : await FirebaseAuth.instance.signInWithCredential(credential);
    }

    final user = userCredential.user;
    if (user != null) {
      await createUserDoc(user);
    }

    return userCredential;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'account-exists-with-different-credential') {
      pendingGoogleCredential = e.credential;

      throw FirebaseAuthException(
        code: 'need-email-login',
        message: 'Please login with email/password first to link Google',
      );
    }

    rethrow;
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPswrdHidden = true;
  bool _isSigningIn = false;
  bool _isGoogleSigningIn = false;
  bool get _isBusy => _isSigningIn || _isGoogleSigningIn;

  final TextEditingController loginemailctrl = TextEditingController();
  final TextEditingController loginpswrdctrl = TextEditingController();

  @override
  void dispose() {
    loginemailctrl.dispose();
    loginpswrdctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  // EMAIL
                  TextField(
                    controller: loginemailctrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: context.l10n.email,
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: brandBlueDark,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: brandBlue, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // PASSWORD
                  TextField(
                    controller: loginpswrdctrl,
                    obscureText: _isPswrdHidden,
                    decoration: InputDecoration(
                      labelText: context.l10n.password,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: brandBlueDark,
                      ),
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
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: brandBlue, width: 2),
                      ),
                    ),
                  ),

                  // FORGOT PASSWORD
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isBusy
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ResetPassScreen(),
                                ),
                              );
                            },
                      child: Text(
                        context.l10n.forgotPassword,
                        style: TextStyle(
                          color: brandBlueDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // LOGIN BUTTON
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isBusy
                          ? null
                          : () async {
                              if (loginemailctrl.text.trim().isEmpty ||
                                  loginpswrdctrl.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.l10n.fillAllFields),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isSigningIn = true);
                              try {
                                final email = loginemailctrl.text.trim();
                                final password = loginpswrdctrl.text;

                                final userCredential =
                                    await signInWithEmailAutoLink(
                                  email,
                                  password,
                                );

                                final user = userCredential?.user;
                                if (user == null) return;

                                await user.reload();

                                final refreshedUser =
                                    FirebaseAuth.instance.currentUser!;

                                final userDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(refreshedUser.uid)
                                    .get();

                                final requiresVerification = userDoc
                                        .data()?['requiresEmailVerification'] ==
                                    true;

                                if (requiresVerification &&
                                    !refreshedUser.emailVerified) {
                                  await NotificationService.instance.signOut();

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.verifyEmailFirst,
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (requiresVerification &&
                                    refreshedUser.emailVerified) {
                                  await userDoc.reference.update({
                                    'requiresEmailVerification': false,
                                  });
                                }

                                await createUserDoc(refreshedUser);

                                if (!context.mounted) return;

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomeScreen(),
                                  ),
                                );
                              } on FirebaseAuthException catch (e) {
                                String message;

                                switch (e.code) {
                                  case 'user-not-found':
                                  case 'invalid-credential':
                                    message = context.l10n.wrongEmailOrPassword;
                                    break;
                                  case 'wrong-password':
                                    message = context.l10n.wrongPassword;
                                    break;
                                  case 'invalid-email':
                                    message = context.l10n.invalidEmail;
                                    break;
                                  case 'too-many-requests':
                                    message = context.l10n.tooManyAttempts;
                                    break;
                                  case 'need-email-login':
                                    message = context.l10n.emailLoginFirst;
                                    break;
                                  default:
                                    message = context.l10n.loginFailed;
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
                                      context.l10n.somethingWentWrong,
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isSigningIn = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        foregroundColor: brandInk,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSigningIn
                          ? const BusyIndicator()
                          : Text(
                              context.l10n.logIn,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // OR DIVIDER
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.withValues(alpha: 0.4),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          context.l10n.or,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // GOOGLE SIGN-IN
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isBusy
                          ? null
                          : () async {
                              setState(() => _isGoogleSigningIn = true);
                              try {
                                final result = await handleGoogleAutoLink();
                                if (result?.user == null || !context.mounted) {
                                  return;
                                }
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomeScreen(),
                                  ),
                                );
                              } on FirebaseAuthException catch (e) {
                                debugPrint(
                                  'GOOGLE AUTH: ${e.code}: ${e.message}',
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.code == 'need-email-login'
                                          ? context.l10n.linkGoogleNeedsEmail
                                          : context.l10n
                                              .googleCouldNotFinishCode(e.code),
                                    ),
                                  ),
                                );
                              } on GoogleSignInException catch (e) {
                                debugPrint(
                                  'GOOGLE SIGN-IN: ${e.code.name}: ${e.description} ${e.details ?? ''}',
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 8),
                                    content: Text(
                                      e.code ==
                                              GoogleSignInExceptionCode.canceled
                                          ? context.l10n.googleCancelled
                                          : context.l10n.googleFailed(
                                              e.code.name,
                                              e.description ?? 'unknown error',
                                            ),
                                    ),
                                  ),
                                );
                              } catch (e, stack) {
                                debugPrint('GOOGLE SIGN-IN ERROR: $e\n$stack');
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.googleCouldNotFinish,
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isGoogleSigningIn = false);
                                }
                              }
                            },
                      icon: Image.asset("assets/google.webp", height: 22),
                      label: _isGoogleSigningIn
                          ? const BusyIndicator()
                          : Text(context.l10n.continueWithGoogle),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brandBlueDark,
                        side: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SIGN-UP
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(context.l10n.noAccount),
                        TextButton(
                          onPressed: _isBusy
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignUpScreen(),
                                    ),
                                  );
                                },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(48, 48),
                            tapTargetSize: MaterialTapTargetSize.padded,
                          ),
                          child: Text(
                            context.l10n.signUp,
                            style: TextStyle(
                              color: brandBlueDark,
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
