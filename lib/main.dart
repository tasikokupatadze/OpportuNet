import 'notification_service.dart';
import 'notification_bell.dart';
import 'app_ui.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import 'package:http/http.dart' as httpai;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'savedposts.dart';
import 'authgate.dart';
import 'home_feed.dart';
import 'community_feed.dart';

import 'package:flutter_markdown/flutter_markdown.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

const String profileImageKey = 'profile_image';
const String aboutMeKey = "about_me";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();

  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

  themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
  unawaited(NotificationService.instance.start());
}

List<Map<String, String>> users = [];

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          navigatorKey: notificationNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'OpportuNet',
          theme: appTheme(Brightness.light),
          darkTheme: appTheme(Brightness.dark),
          themeMode: mode,
          home: const AuthGate(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _profileImagePath;

  int _selectedIndex = 0;
  final Set<int> _visitedTabs = {0};
  late Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream;

  void _connectMessages() {
    _messagesStream = FirebaseFirestore.instance
        .collection('messages')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  bool _editNamePrfl = false;
  bool _editSurnamePrfl = false;
  bool _editAgePrfl = false;
  bool _editAbtMePrfl = false;
  bool _isOrganizer = false;

  final ImagePicker _picker = ImagePicker();

  final TextEditingController _abtMePrflctrl = TextEditingController();
  final TextEditingController _namePrflctrl = TextEditingController();
  final TextEditingController _surnamePrflctrl = TextEditingController();
  final TextEditingController _agePrflctrl = TextEditingController();
  late TextEditingController aictrl;
  late String uid;
  final ScrollController scrollctrl = ScrollController();

  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    aictrl = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    uid = user!.uid;
    _connectMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) NotificationService.instance.openPending();
    });

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;

      if (user != null) {
        _loadProfile();
      } else {}
    });
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      var doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'name': '',
          'surname': '',
          'age': '',
          'email': user.email ?? '',
          'aboutMe': '',
          'profileImage': '',
          'role': 'user',
        });

        doc = await docRef.get();
      }

      final data = doc.data() ?? <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        _namePrflctrl.text = data['name'] ?? '';
        _surnamePrflctrl.text = data['surname'] ?? '';
        _agePrflctrl.text = (data['age'] ?? '').toString();
        _abtMePrflctrl.text = data['aboutMe'] ?? '';
        _profileImagePath = data['profileImage'] ?? '';
        _isOrganizer = (data['role'] ?? 'user') == 'organizer';
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to load profile: $e")));
    }
  }

  Future<bool> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final oldName = _namePrflctrl.text.trim();
    final oldSurname = _surnamePrflctrl.text.trim();

    final newUsername = "$oldName $oldSurname".trim();

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': oldName,
        'surname': oldSurname,
        'age': _agePrflctrl.text.trim(),
        'aboutMe': _abtMePrflctrl.text.trim(),
        'profileImage': _profileImagePath ?? '',
        'email': user.email ?? '',
      }, SetOptions(merge: true));

      // Keep the username on existing posts in sync.
      final posts = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var i = 0; i < posts.docs.length; i += 450) {
        final batch = FirebaseFirestore.instance.batch();
        final end = (i + 450 < posts.docs.length) ? i + 450 : posts.docs.length;

        for (final post in posts.docs.sublist(i, end)) {
          batch.update(post.reference, {
            'username': newUsername.isEmpty ? 'user' : newUsername,
          });
        }

        await batch.commit();
      }

      if (!mounted) return true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));

      return false;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _abtMePrflctrl.dispose();
    _namePrflctrl.dispose();
    _surnamePrflctrl.dispose();
    _agePrflctrl.dispose();
    aictrl.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final text = aictrl.text.trim();
    if (text.isEmpty) return;

    if (uid.isEmpty) {
      return;
    }

    aictrl.clear();

    DocumentReference? docRef;

    try {
      docRef = await FirebaseFirestore.instance.collection("messages").add({
        "text": text,
        "userId": uid,
        "timestamp": FieldValue.serverTimestamp(),
        "aiResponse": null,
      });

      final messagesSnapshot = await FirebaseFirestore.instance
          .collection("messages")
          .where("userId", isEqualTo: uid)
          .get();

      final docs = messagesSnapshot.docs.toList();

      docs.sort((a, b) {
        final aTime = a.data()["timestamp"];
        final bTime = b.data()["timestamp"];

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return -1;
        if (bTime == null) return 1;

        return aTime.compareTo(bTime);
      });

      final recentDocs =
          docs.length > 10 ? docs.sublist(docs.length - 10) : docs;

      List<Map<String, dynamic>> history = [
        {
          "role": "system",
          "content":
              "You are a helpful admissions assistant for Georgian students who want to study abroad. Give clear, practical, supportive answers.",
        },
      ];

      for (var doc in recentDocs) {
        history.add({"role": "user", "content": doc["text"] ?? ""});

        if (doc["aiResponse"] != null &&
            doc["aiResponse"].toString().isNotEmpty &&
            !doc["aiResponse"].toString().startsWith("Error") &&
            !doc["aiResponse"].toString().startsWith("API Error")) {
          history.add({"role": "assistant", "content": doc["aiResponse"]});
        }
      }

      final response = await httpai.post(
        Uri.parse("https://callai-docslpktsq-uc.a.run.app"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": history,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode != 200) {
        await docRef.update({"aiResponse": "API Error ${response.statusCode}"});
        return;
      }

      final data = jsonDecode(response.body);
      final aiText = data["choices"][0]["message"]["content"].toString().trim();

      await docRef.update({"aiResponse": aiText});
    } catch (e) {
      if (docRef != null) {
        await docRef.update({"aiResponse": "Error: $e"});
      }
    }
  }

  Future<void> clearChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Chat history deleted")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete chat history")),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
  }

  ImageProvider _getProfileImage() {
    if (_profileImagePath == null || _profileImagePath!.isEmpty) {
      return const AssetImage("assets/avatar.jpg");
    }

    final path = _profileImagePath!;

    if (path.startsWith("http")) {
      return NetworkImage(path);
    }

    return const AssetImage("assets/avatar.jpg");
  }

  Future<void> _pickImage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        final file = File(image.path);
        uploadTask = storageRef.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      await uploadTask;

      final downloadUrl = await storageRef.getDownloadURL();

      if (!mounted) return;

      setState(() {
        _profileImagePath = downloadUrl;
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profileImage': downloadUrl,
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload profile image")),
      );
    }
  }

  Widget _profileActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color accent = brandInk,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 24),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileEditCard({
    required String title,
    required IconData icon,
    required bool isEditing,
    required TextEditingController controller,
    required String hintText,
    required Future<void> Function() onPressed,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xff84d6fe).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Color(0xff2b88b4)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    maxLines: maxLines,
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        controller.text.trim().isEmpty
                            ? "Not added yet"
                            : controller.text.trim(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(width: 8),
          IconButton(
            onPressed: onPressed,
            icon: Icon(isEditing ? Icons.check_circle : Icons.edit_outlined),
            color: isEditing ? Colors.green : Color(0xff2b88b4),
          ),
        ],
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return HomeFeed(isOrganizer: _isOrganizer);
      case 1:
        return CommunityFeed();
      case 2:
        return ContentWidth(
          maxWidth: 800,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(bottom: BorderSide(color: Colors.black12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.smart_toy, color: Color(0xff84d6fe)),
                      SizedBox(width: 10),
                      Text(
                        "AI Assistant",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Delete chat history?"),
                              content: Text(
                                "This will remove all your AI messages",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(color: Color(0xff84d6fe)),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    "Delete",
                                    style: TextStyle(color: Color(0xff84d6fe)),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (shouldDelete == true) {
                            await clearChatHistory();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return LoadError(
                          message:
                              'Could not load your messages. Check your connection and try again.',
                          onRetry: () => setState(_connectMessages),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text("No messages yet"));
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        reverse: true,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];

                          final text = doc["text"] ?? "";
                          final aiResponse = doc["aiResponse"];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 4),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xff84d6fe),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    text,
                                    style: TextStyle(color: brandInk),
                                  ),
                                ),
                              ),
                              if (aiResponse == null ||
                                  aiResponse.toString().isEmpty)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 4),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text("AI is thinking..."),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 4),
                                    padding: EdgeInsets.all(12),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.75,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: MarkdownBody(
                                      data: aiResponse.toString(),
                                      styleSheet: MarkdownStyleSheet(
                                        p: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                        h1: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        h2: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        h3: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        listBullet: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 14,
                                        ),
                                        code: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          fontSize: 13,
                                        ),
                                        codeblockDecoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(12, 10, 12, 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(top: BorderSide(color: Colors.black12)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: aictrl,
                            keyboardType: TextInputType.multiline,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: "Ask something...",
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xff84d6fe),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.send, color: brandInk),
                          onPressed: () {
                            sendMessage();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case 3:
        return ContentWidth(
          maxWidth: 800,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xff84d6fe), Color(0xffb6ebff)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(
                                      radius: 56,
                                      backgroundColor: Colors.white,
                                      child: CircleAvatar(
                                        radius: 52,
                                        backgroundImage: _getProfileImage(),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 14),
                              Text(
                                "${_namePrflctrl.text} ${_surnamePrflctrl.text}"
                                        .trim()
                                        .isEmpty
                                    ? "Your Profile"
                                    : "${_namePrflctrl.text} ${_surnamePrflctrl.text}"
                                        .trim(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: brandInk,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _abtMePrflctrl.text.trim().isEmpty
                                    ? "Tap edit below to add something about yourself."
                                    : _abtMePrflctrl.text.trim(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: brandInk,
                                ),
                              ),
                              SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: _profileActionCard(
                                      icon: Icons.bookmark_border,
                                      accent: Colors.amber.shade800,
                                      title: "Saved Posts",
                                      subtitle: "Open collection",
                                      onTap: () {
                                        final user =
                                            FirebaseAuth.instance.currentUser;
                                        if (user == null) return;

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SavedPostsScreen(
                                              currentUserId: user.uid,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _profileActionCard(
                                      icon: Icons.logout,
                                      accent: Colors.red,
                                      title: "Log out",
                                      subtitle: "Leave account",
                                      onTap: () async {
                                        try {
                                          await NotificationService.instance
                                              .signOut();
                                        } catch (_) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Could not finish logging out. Check your connection and try again.'),
                                          ));
                                
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 22),
                        Text(
                          "Profile details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 14),
                        _profileEditCard(
                          title: "Name",
                          icon: Icons.badge_outlined,
                          isEditing: _editNamePrfl,
                          controller: _namePrflctrl,
                          hintText: "Enter your name",
                          onPressed: () async {
                            if (_editNamePrfl) {
                              final saved = await _saveProfile();
                              if (!saved) return;
                            }

                            setState(() {
                              _editNamePrfl = !_editNamePrfl;
                            });
                          },
                        ),
                        SizedBox(height: 12),
                        _profileEditCard(
                          title: "Surname",
                          icon: Icons.person_outline,
                          isEditing: _editSurnamePrfl,
                          controller: _surnamePrflctrl,
                          hintText: "Enter your surname",
                          onPressed: () async {
                            if (_editSurnamePrfl) {
                              final saved = await _saveProfile();
                              if (!saved) return;
                            }

                            setState(() {
                              _editSurnamePrfl = !_editSurnamePrfl;
                            });
                          },
                        ),
                        SizedBox(height: 12),
                        _profileEditCard(
                          title: "Age",
                          icon: Icons.cake_outlined,
                          isEditing: _editAgePrfl,
                          controller: _agePrflctrl,
                          hintText: "Enter your age",
                          keyboardType: TextInputType.number,
                          onPressed: () async {
                            if (_editAgePrfl) {
                              final saved = await _saveProfile();
                              if (!saved) return;
                            }

                            setState(() {
                              _editAgePrfl = !_editAgePrfl;
                            });
                          },
                        ),
                        SizedBox(height: 12),
                        _profileEditCard(
                          title: "About me",
                          icon: Icons.edit_note,
                          isEditing: _editAbtMePrfl,
                          controller: _abtMePrflctrl,
                          hintText: "Tell people something about yourself",
                          maxLines: 4,
                          onPressed: () async {
                            if (_editAbtMePrfl) {
                              final saved = await _saveProfile();
                              if (!saved) return;
                            }

                            setState(() {
                              _editAbtMePrfl = !_editAbtMePrfl;
                            });
                          },
                        ),
                        SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ValueListenableBuilder<ThemeMode>(
                            valueListenable: themeNotifier,
                            builder: (context, mode, _) {
                              return Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Color(0xff84d6fe)
                                          .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.dark_mode_outlined,
                                      color: Color(0xff2b88b4),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Appearance",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          "Switch between light and dark mode",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: mode == ThemeMode.dark,
                                    onChanged: (value) async {
                                      themeNotifier.value = value
                                          ? ThemeMode.dark
                                          : ThemeMode.light;
                                      SharedPreferences prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setBool('isDarkMode', value);
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: const [NotificationBell()],
          title: Image.asset('assets/opportunet1.png', height: 60),
          centerTitle: true,
        ),
        body: SafeArea(
          top: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: List.generate(
              4,
              (index) => _visitedTabs.contains(index)
                  ? _getPage(index)
                  : SizedBox.shrink(),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: "Posts feed",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: "AI"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
