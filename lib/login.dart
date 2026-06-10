import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup.dart';
import 'main.dart';

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

Future<void> createUserDoc(User user) async {
  debugPrint("CREATE USER DOC START");

  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'email': user.email ?? '',
    'name': user.displayName?.split(' ').first ?? '',
    'surname': (user.displayName != null && user.displayName!.contains(' '))
        ? user.displayName!.split(' ').sublist(1).join(' ')
        : '',
    'role': 'user',
  }, SetOptions(merge: true));
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
        debugPrint("Google account linked successfully");
      }
    }

    return userCredential;
  } on FirebaseAuthException catch (e) {
    debugPrint("Email login error: ${e.code}");
    rethrow;
  }
}

Future<UserCredential?> handleGoogleAutoLink() async {
  try {
    final googleProvider = GoogleAuthProvider();

    return await FirebaseAuth.instance.signInWithPopup(googleProvider);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'account-exists-with-different-credential') {
      pendingGoogleCredential = e.credential;
      final email = e.email;

      debugPrint("Account already exists for $email");

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
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
                    debugPrint("LOGIN BUTTON CLICKED");

                    final email = loginemailctrl.text.trim();
                    final password = loginpswrdctrl.text.trim();

                    debugPrint("EMAIL: $email");

                    final userCredential =
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );

                    debugPrint("LOGIN SUCCESS");

                    final user = userCredential.user;

                    if (user != null) {
                      debugPrint("USER EXISTS: ${user.uid}");
                      await createUserDoc(user);
                    }

                    if (!context.mounted) return;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  } on FirebaseAuthException catch (e) {
                    debugPrint("FIREBASE ERROR: ${e.code}");

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Login failed: ${e.code}")),
                    );
                  } catch (e) {
                    debugPrint("UNKNOWN ERROR: $e");
                  }
                },
                child: const Text(
                  "Login",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final user = await handleGoogleAutoLink();

                    if (user != null) {}

                    if (!context.mounted) return;
                    
                    {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(),
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'need-email-login') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Login with email/password first to link your Google account",
                          ),
                        ),
                      );
                    }
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
              const SizedBox(height: 15),
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
    );
  }
}
