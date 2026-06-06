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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'roadmaps.dart';
import 'volunteering.dart';
import 'exchange.dart';
import 'schools.dart';
import 'olympiads.dart';
import 'login.dart';
import 'userprofile.dart';
import 'savedPosts.dart';
import 'calendar.dart';
import 'commentsSheet.dart';
import 'createpost.dart';
import 'signup.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

const String profileImageKey = 'profile_image';
const String aboutMeKey = "about_me";


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

final apiKey = dotenv.env['groqApiKey'];

List<Map<String, String>> users = [];

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'OpportuNet',
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xff84d6fe),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xff84d6fe),
          ),
          themeMode: mode,
          home: const SignUpScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String? _profileImagePath;

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

      final data = doc.data() as Map<String, dynamic>;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load profile")),
      );
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': _namePrflctrl.text.trim(),
      'surname': _surnamePrflctrl.text.trim(),
      'age': _agePrflctrl.text.trim(),
      'aboutMe': _abtMePrflctrl.text.trim(),
      'profileImage': _profileImagePath ?? '',
    }, SetOptions(merge: true));
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
              "You are a helpful admissions assistant for Georgian students who want to study abroad. Give clear, practical, supportive answers."
        }
      ];

      for (var doc in recentDocs) {
        history.add({
          "role": "user",
          "content": doc["text"] ?? "",
        });

        if (doc["aiResponse"] != null &&
            doc["aiResponse"].toString().isNotEmpty &&
            !doc["aiResponse"].toString().startsWith("Error") &&
            !doc["aiResponse"].toString().startsWith("API Error")) {
          history.add({
            "role": "assistant",
            "content": doc["aiResponse"],
          });
        }
      }

      final response = await httpai.post(
        Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": history,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode != 200) {
        await docRef.update({
          "aiResponse": "API Error ${response.statusCode}",
        });
        return;
      }

      final data = jsonDecode(response.body);
      final aiText = data["choices"][0]["message"]["content"].toString().trim();

      await docRef.update({
        "aiResponse": aiText,
      });
    } catch (e) {
      if (docRef != null) {
        await docRef.update({
          "aiResponse": "Error: $e",
        });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chat history deleted")),
      );
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
    Color accent = Colors.black87,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.black54,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff84d6fe).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xff2b88b4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    maxLines: maxLines,
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.text.trim().isEmpty
                            ? "Not added yet"
                            : controller.text.trim(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onPressed,
            icon: Icon(isEditing ? Icons.check_circle : Icons.edit_outlined),
            color: isEditing ? Colors.green : const Color(0xff2b88b4),
          ),
        ],
      ),
    );
  }

  Widget _hubTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    "Explore",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff2b88b4),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Color(0xff2b88b4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff84d6fe),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CalendarScreen(isOrganizer: _isOrganizer),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text(
                      "Academic Calendar",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.83,
                    children: [
                      _hubTile(
                        title: "Olympiads & Contests",
                        subtitle: "National & International",
                        icon: Icons.emoji_events_rounded,
                        accent: const Color(0xfff7d774),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const OlympScreen()),
                          );
                        },
                      ),
                      _hubTile(
                        title: "Volunteering",
                        subtitle: "Organizations & Local places",
                        icon: Icons.volunteer_activism_rounded,
                        accent: const Color(0xffb8f0c9),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const VlntrScreen()),
                          );
                        },
                      ),
                      _hubTile(
                        title: "Exchange Programs",
                        subtitle: "Short & long term programs",
                        icon: Icons.flight_takeoff_rounded,
                        accent: const Color(0xffffc6b3),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ExchPrgrmScreen()),
                          );
                        },
                      ),
                      _hubTile(
                        title: "Roadmaps",
                        subtitle: "For each year of high schools",
                        icon: Icons.route_rounded,
                        accent: const Color(0xffbfe8ff),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RoadmapScreen()),
                          );
                        },
                      ),
                      _hubTile(
                        title: "Schools",
                        subtitle: "Best schools for college prep",
                        icon: Icons.school_rounded,
                        accent: const Color(0xffd8c7ff),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SchoolScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case 1:
        return Scaffold(
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("posts")
                .orderBy("timestamp", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = snapshot.data!.docs;

              if (posts.isEmpty) {
                return const Center(
                  child: Text(
                    "No posts yet",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 90),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final data = post.data() as Map<String, dynamic>;

                  final String userId = data["userId"] ?? "";
                  final String username = data["username"] ?? "user";
                  final String text = data["text"] ?? "";
                  final String imageUrl = data["imageUrl"] ?? "";
                  final String profileImage = data["profileImage"] ?? "";
                  final int likes = data["likes"] ?? 0;
                  final int commentsCount = data["commentsCount"] ?? 0;
                  final List likedBy = data["likedBy"] ?? [];

                  final currentUser = FirebaseAuth.instance.currentUser;
                  final bool isLiked =
                      currentUser != null && likedBy.contains(currentUser.uid);

                  final List savedBy = List.from(data["savedBy"] ?? []);
                  final bool isSaved =
                      currentUser != null && savedBy.contains(currentUser.uid);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xffdbeaf2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserProfile(uid: userId),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.grey.shade300,
                                child: ClipOval(
                                  child: profileImage.isNotEmpty
                                      ? Image.network(
                                          profileImage,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            );
                                          },
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserProfile(uid: userId),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xff84d6fe)
                                            .withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        "Community post",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xff84d6fe),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == "delete") {
                                  final currentUser =
                                      FirebaseAuth.instance.currentUser;
                                  if (currentUser == null) return;

                                  if (currentUser.uid == userId) {
                                    await FirebaseFirestore.instance
                                        .collection("posts")
                                        .doc(post.id)
                                        .delete();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Post deleted")),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "You can only delete your own posts"),
                                      ),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: "delete",
                                  child: Text("Delete"),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (text.isNotEmpty)
                          Text(
                            text,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: Colors.black87,
                            ),
                          ),
                        if (imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 220,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 42,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                final currentUser =
                                    FirebaseAuth.instance.currentUser;
                                if (currentUser == null) return;

                                final postRef = FirebaseFirestore.instance
                                    .collection("posts")
                                    .doc(post.id);

                                if (isLiked) {
                                  await postRef.update({
                                    "likedBy": FieldValue.arrayRemove(
                                        [currentUser.uid]),
                                    "likes": FieldValue.increment(-1),
                                  });
                                } else {
                                  await postRef.update({
                                    "likedBy": FieldValue.arrayUnion(
                                        [currentUser.uid]),
                                    "likes": FieldValue.increment(1),
                                  });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color:
                                          isLiked ? Colors.red : Colors.black87,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 5),
                                    Text("$likes"),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.white,
                                  builder: (_) =>
                                      CommentsSheet(postId: post.id),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.mode_comment_outlined,
                                      size: 21,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 5),
                                    Text("$commentsCount"),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () async {
                                final currentUser =
                                    FirebaseAuth.instance.currentUser;
                                if (currentUser == null) return;

                                final postRef = FirebaseFirestore.instance
                                    .collection("posts")
                                    .doc(post.id);

                                if (isSaved) {
                                  await postRef.update({
                                    "savedBy": FieldValue.arrayRemove(
                                        [currentUser.uid]),
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Removed from saved posts"),
                                    ),
                                  );
                                } else {
                                  await postRef.set({
                                    "savedBy": FieldValue.arrayUnion(
                                        [currentUser.uid]),
                                  }, SetOptions(merge: true));

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Saved")),
                                  );
                                }
                              },
                              icon: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: Colors.yellow,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfile(uid: userId),
                              ),
                            );
                          },
                          child: const Text(
                            "View profile",
                            style: TextStyle(
                              color: Color(0xff84d6fe),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xff84d6fe),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePost()),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      case 2:
        return Container(
          color: const Color(0xfff4f9fc),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.black12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy, color: Color(0xff84d6fe)),
                    const SizedBox(width: 10),
                    const Text(
                      "AI Assistant",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Delete chat history?"),
                            content: const Text(
                              "This will remove all your AI messages",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Color(0xff84d6fe),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
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
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .where("userId", isEqualTo: uid)
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {}

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No messages yet"),
                      );
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
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xff84d6fe),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(text,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            ),
                            if (aiResponse == null ||
                                aiResponse.toString().isEmpty)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Row(
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
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    doc["aiResponse"] ?? "",
                                    style:
                                        const TextStyle(color: Colors.black87),
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
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.black12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: aictrl,
                          decoration: const InputDecoration(
                            hintText: "Ask something...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xff84d6fe),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () {
                            sendMessage();
                          }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 3:
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xff84d6fe),
                              Color(0xffb6ebff),
                            ],
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
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "${_namePrflctrl.text} ${_surnamePrflctrl.text}"
                                      .trim()
                                      .isEmpty
                                  ? "Your Profile"
                                  : "${_namePrflctrl.text} ${_surnamePrflctrl.text}"
                                      .trim(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _abtMePrflctrl.text.trim().isEmpty
                                  ? "Tap edit below to add something about yourself."
                                  : _abtMePrflctrl.text.trim(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _profileActionCard(
                                    icon: Icons.bookmark_border,
                                    accent: Colors.yellow,
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _profileActionCard(
                                    icon: Icons.logout,
                                    accent: Colors.red,
                                    title: "Log out",
                                    subtitle: "Leave account",
                                    onTap: () async {
                                      await FirebaseAuth.instance.signOut();

                                      if (!mounted) return;

                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        "Profile details",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _profileEditCard(
                        title: "Name",
                        icon: Icons.badge_outlined,
                        isEditing: _editNamePrfl,
                        controller: _namePrflctrl,
                        hintText: "Enter your name",
                        onPressed: () async {
                          if (_editNamePrfl) {
                            await _saveProfile();
                          }
                          setState(() {
                            _editNamePrfl = !_editNamePrfl;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _profileEditCard(
                        title: "Surname",
                        icon: Icons.person_outline,
                        isEditing: _editSurnamePrfl,
                        controller: _surnamePrflctrl,
                        hintText: "Enter your surname",
                        onPressed: () async {
                          if (_editSurnamePrfl) {
                            await _saveProfile();
                          }
                          setState(() {
                            _editSurnamePrfl = !_editSurnamePrfl;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _profileEditCard(
                        title: "Age",
                        icon: Icons.cake_outlined,
                        isEditing: _editAgePrfl,
                        controller: _agePrflctrl,
                        hintText: "Enter your age",
                        keyboardType: TextInputType.number,
                        onPressed: () async {
                          if (_editAgePrfl) {
                            await _saveProfile();
                          }
                          setState(() {
                            _editAgePrfl = !_editAgePrfl;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _profileEditCard(
                        title: "About me",
                        icon: Icons.edit_note,
                        isEditing: _editAbtMePrfl,
                        controller: _abtMePrflctrl,
                        hintText: "Tell people something about yourself",
                        maxLines: 4,
                        onPressed: () async {
                          if (_editAbtMePrfl) {
                            await _saveProfile();
                          }
                          setState(() {
                            _editAbtMePrfl = !_editAbtMePrfl;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
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
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff84d6fe)
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.dark_mode_outlined,
                                    color: Color(0xff2b88b4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
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
        );
      default:
        return const SizedBox();
    }
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
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xff84d6fe),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Posts feed",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: "AI",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
