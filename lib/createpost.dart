import 'app_ui.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';

class CreatePost extends StatefulWidget {
  final String? category;
  const CreatePost({super.key, this.category});

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  final TextEditingController controller = TextEditingController();
  bool _isPosting = false;
  final List<String> _categories = [
    'General',
    'Math',
    'Coding',
    'Arts',
    'Languages',
    'Career',
  ];

  String _selectedCategory = 'General';

  Future<void> uploadPost() async {
    final text = controller.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (text.isEmpty || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Write something before posting")),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Your profile could not be found. Please log out and log in again.",
            ),
          ),
        );
        return;
      }

      final userData = userDoc.data()!;

      final String name = userData["name"] ?? "";
      final String surname = userData["surname"] ?? "";
      final String username =
          "$name $surname".trim().isEmpty ? "user" : "$name $surname".trim();
      final String profileImage = userData["profileImage"] ?? "";

      await FirebaseFirestore.instance.collection("posts").add({
        "text": text,
        "userId": user.uid,
        "username": username,
        "profileImage": profileImage,
        "imageUrl": "",
        "timestamp": FieldValue.serverTimestamp(),
        "likes": 0,
        "likedBy": [],
        "commentsCount": 0,
        "savedBy": [],
        "category": _selectedCategory,
      });

      controller.clear();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to post: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.category != null && _categories.contains(widget.category)) {
      _selectedCategory = widget.category!;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Image.asset('assets/opportunet1.png', height: 60),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ContentWidth(
          maxWidth: 760,
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xff84d6fe),
                              child:
                                  Icon(Icons.person, color: brandInk, size: 28),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Share something",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Post category',
                            prefixIcon: const Icon(
                              Icons.category_outlined,
                              color: Color(0xff2b88b4),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: (constraints.maxHeight - 260)
                              .clamp(180.0, 600.0)
                              .toDouble(),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: controller,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: const InputDecoration(
                                hintText: "Write something...",
                                border: InputBorder.none,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isPosting ? null : uploadPost,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff84d6fe),
                              foregroundColor: brandInk,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isPosting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: brandInk,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Post",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold