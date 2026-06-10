import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'main.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isPswrdHidden = true;
  bool _acceptedTerms = false;

  final TextEditingController signupemailctrl = TextEditingController();
  final TextEditingController pswrdctrl = TextEditingController();
  final TextEditingController namectrl = TextEditingController();
  final TextEditingController surnamectrl = TextEditingController();
  final TextEditingController agectrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    namectrl.dispose();
    surnamectrl.dispose();
    agectrl.dispose();
    signupemailctrl.dispose();
    pswrdctrl.dispose();
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: namectrl,
                decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Color(0xff84d6fe))),
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Zა-ჰ]'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextField(
                controller: surnamectrl,
                decoration: const InputDecoration(
                    labelText: "Surname",
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Color(0xff84d6fe))),
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Zა-ჰ]'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextField(
                controller: agectrl,
                decoration: const InputDecoration(
                    labelText: "Age",
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Color(0xff84d6fe))),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 15),
              TextField(
                controller: signupemailctrl,
                decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Color(0xff84d6fe))),
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z0-9@._-]'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextField(
                controller: pswrdctrl,
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
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptedTerms = value!;
                  });
                },
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Color(0xff84d6fe)),
                    children: [
                      const TextSpan(text: "I have read and agree to the "),
                      TextSpan(
                        text: "Terms & Conditions",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final url = Uri.parse(
                                "https://docs.google.com/document/d/1mnCgKafSmjXpOZLhBrfHs9Dq5bXT9bx06oZ_BBjXV6k/edit?usp=sharing");
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          },
                      ),
                      const TextSpan(text: " and "),
                      TextSpan(
                        text: "Privacy & Policy",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final url = Uri.parse(
                                "https://docs.google.com/document/d/1ZVM54y9rXpq_vEWOW-5cO6KEZH0koECwn-ivQEDhuaw/edit?usp=sharing");
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          },
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (namectrl.text.isEmpty ||
                      surnamectrl.text.isEmpty ||
                      agectrl.text.isEmpty ||
                      pswrdctrl.text.isEmpty ||
                      !signupemailctrl.text.contains("@") ||
                      !signupemailctrl.text.contains(".")) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text("Please fill all of the fields correctly")),
                    );
                    return;
                  }
                  if (!_acceptedTerms) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("You must accept both fields"),
                      ),
                    );
                    return;
                  }

                  try {
                    UserCredential userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: signupemailctrl.text.trim(),
                      password: pswrdctrl.text.trim(),
                    );

                    final uid = userCredential.user!.uid;

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .set({
                      'name': namectrl.text.trim(),
                      'surname': surnamectrl.text.trim(),
                      'age': int.parse(agectrl.text.trim()),
                      'email': signupemailctrl.text.trim(),
                      'role': 'user',
                      'aboutMe': '',
                    });

                    if (!context.mounted) return;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  } on FirebaseAuthException catch (e) {
                    String message = "Sign up failed";

                    if (e.code == "email-already-in-use") {
                      message = "This email is already registered";
                    } else if (e.code == "weak-password") {
                      message = "Password is too weak";
                    } else if (e.code == "invalid-email") {
                      message = "Invalid email";
                    } 

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                },
                child: const Text("Sign Up",
                    style: TextStyle(
                        color: Color(0xff84d6fe),
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text("Already have an account? Login",
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
