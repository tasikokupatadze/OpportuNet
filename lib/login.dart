import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup.dart';
import 'main.dart';

Future<UserCredential?> signInWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn  =  GoogleSignIn.instance;
    
    await googleSignIn.initialize();

    final GoogleSignInAccount googleUser = 
      await googleSignIn.authenticate();

    final GoogleSignInClientAuthorization? authorization =
      await googleUser.authorizationClient.authorizationForScopes(
        ["email", "profile"],
      );

    final String? idToken = googleUser.authentication.idToken;
   

    final credential = GoogleAuthProvider.credential(
      accessToken: authorization?.accessToken,
      idToken: idToken,
    );
    
    final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

    
    final user = userCredential.user;

    if (user !=null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email ?? '',
        'name': user.displayName ?? '',
        'role': 'user',
      }, SetOptions(merge: true));

    }

    return userCredential;
  } catch (e) {
    debugPrint("Google Sign-In failed: $e");
    return null;
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
  void initState() {
    super.initState();
  }

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
                    labelStyle: TextStyle(color: Color(0xff84d6fe))),
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
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  try {
                    UserCredential userCredential =
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: loginemailctrl.text.trim(),
                      password: loginpswrdctrl.text.trim(),
                    );

                    final uid = userCredential.user!.uid;

                    final doc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .get();

                    //final data = doc.data();

                    if (!mounted) return;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  } on FirebaseAuthException catch (e) {
                    String message = "Login failed";

                    switch (e.code) {
                      case "user-not-found":
                        message = "No user found with this email";
                        break;
                      case "wrong-password":
                        message = "Wrong password";
                        break;
                      case "invalid-email":
                        message = "Invalid email format";
                        break;
                      case "invalid-credential":
                        message = "Wrong email or password";
                        break;
                      case "user-disabled":
                        message = "This account is disabled";
                        break;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                },
                child: const Text("Login",
                    style: TextStyle(
                        color: Color(0xff84d6fe),
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final user = await signInWithGoogle();

                  if (user != null) {
                    Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => HomeScreen()),);
                  }
                },
                icon: Image.asset(
                  "assets/google.webp",
                  height: 22,
                ),
                label: const Text("Sign in with Google"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
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
                child: const Text("Don't have an account? Sign up",
                    style: TextStyle(
                        color: Color(0xff84d6fe),
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
