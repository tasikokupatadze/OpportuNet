import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup.dart';
import 'main.dart';
import 'resetpass.dart';

AuthCredential? pendingGoogleCredential;

Future<UserCredential?> signInWithGoogleWeb() async {
  try {
    final provider = GoogleAuthProvider();

    final userCredential =
        await FirebaseAuth.instance.signInWithPopup(provider);

    final user = userCredential.user;

    if (user != null) {
      await createUserDoc(user);
    }

    return userCredential;
  } catch (e) {
    return null;
  }
}

Future<void> createUserDoc(
  User user, {
  String? name,
  String? surname,
}) async {
  final userRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid);

  final snapshot = await userRef.get();

  if (!snapshot.exists) {
    final displayName = user.displayName ?? '';
    final nameParts = displayName.trim().split(RegExp(r'\s+'));

    await userRef.set({
      'name': name ?? (nameParts.isNotEmpty ? nameParts.first : ''),
      'surname': surname ??
          (nameParts.length > 1
              ? nameParts.skip(1).join(' ')
              : ''),
      'email': user.email ?? '',
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

  final provider = GoogleAuthProvider();

  try {
    await user.linkWithPopup(provider);
  } catch (e) {
    rethrow;
  } 
}

Future<UserCredential?> signInWithEmailAutoLink(
  String email,
  String password,
) async {
  try {
    final userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;

    if (user != null) {
      await createUserDoc(user);

      if (pendingGoogleCredential != null) {
        await user.linkWithCredential(
          pendingGoogleCredential!,
        );
        pendingGoogleCredential = null;
      }
    }

    return userCredential;
  } on FirebaseAuthException {
    rethrow;
  }
}

Future<UserCredential?> handleGoogleAutoLink() async {
  try {
    final googleProvider = GoogleAuthProvider();

    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithPopup(googleProvider);

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
        title: Image.asset(
          'assets/opportunet1.png',
          height: 60,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const SizedBox(height: 20),
              TextField(
                controller: loginemailctrl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Color(0xff84d6fe)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: loginpswrdctrl,
                obscureText: _isPswrdHidden,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  labelStyle: const TextStyle(color: Color(0xff84d6fe)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPswrdHidden ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPswrdHidden = !_isPswrdHidden;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () async {
                  if (loginemailctrl.text.isEmpty ||
                      loginpswrdctrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill all fields"),
                      ),
                    );
                    return;
                  }

                  try {
                    final email = loginemailctrl.text.trim();
                    final password = loginpswrdctrl.text;

                    final userCredential =
                        await signInWithEmailAutoLink(email, password);

                    final user = userCredential?.user;

                    if (user == null) return;

                    await user.reload();

                    final refreshedUser = FirebaseAuth.instance.currentUser!;

                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(refreshedUser.uid)
                        .get();

                    final requiresVerification =
                        userDoc.data()?['requiresEmailVerification'] == true;

                    if (requiresVerification && !refreshedUser.emailVerified) {
                      await FirebaseAuth.instance.signOut();

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please verify your email before logging in.',
                          ),
                        ),
                      );

                      return;
                    }

                    if (requiresVerification && refreshedUser.emailVerified) {
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
                        message = 'Incorrect email or password.';
                        break;

                      case 'wrong-password':
                        message = 'Incorrect password.';
                        break;

                      case 'invalid-email':
                        message = 'Please enter a valid email.';
                        break;

                      case 'too-many-requests':
                        message = 'Too many attempts. Please try again later.';
                        break;

                      case 'need-email-login':
                        message = 'Please log in using your email and password first.';
                        break;

                      default:
                        message = 'Login failed. Please try again.';
                    }

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );

                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Something went wrong. Please try again.'),
                      ),
                    );
                  }},
                child: const Text(
                  "Login",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                )
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ResetPassScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Forgot password?",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
              onPressed: () async {
                try {
                  final userCredential = await handleGoogleAutoLink();
                  final user = userCredential?.user;

                  if (user == null) return;

                  if (!context.mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                  );

                } on FirebaseAuthException catch (e) {
                  if (!context.mounted) return;

                  if (e.code == 'need-email-login') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Login with email/password first to link your Google account",
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google sign-in failed. Please try again.'),
                      ),
                    );
                  }

                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Google sign-in failed. Please try again.'),
                    ),
                  );
                }
              },
                icon: Image.asset(
                  "assets/google.webp",
                  height: 22,
                ),
                label: const Text("Continue with Google"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Color(0xff84d6fe),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SignUpScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Don't have an account? Sign up",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),);
  }
}
