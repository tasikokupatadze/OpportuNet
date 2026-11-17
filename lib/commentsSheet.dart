import 'app_ui.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';

import 'userprofile.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;

  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentCtrl = TextEditingController();

  bool _isOrganizer = false;
  bool _isSending = false;

  CollectionReference get _commentsRef => FirebaseFirestore.instance
      .collection("posts")
      .doc(widget.postId)
      .collection("comments");

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!mounted) return;

    setState(() {
      _isOrganizer = userDoc.data()?["role"] == "organizer";
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_isSending) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _commentCtrl.text.trim().isEmpty) return;

    final commentText = _commentCtrl.text.trim();
    setState(() => _isSending = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      final String name = userData["name"] ?? "";
      final String surname = userData["surname"] ?? "";
      final String profileImage = userData["profileImage"] ?? "";

      await _commentsRef.add({
        "userId": user.uid,
        "name": name,
        "surname": surname,
        "profileImage": profileImage,
        "text": commentText,
        "timestamp": FieldValue.serverTimestamp(),
        "likes": 0,
        "likedBy": [],
        "commentsCount": 0,
      });

      await FirebaseFirestore.instance
          .collection("posts")
          .doc(widget.postId)
          .set({
        "commentsCount": FieldValue.increment(1),
      }, SetOptions(merge: true));

      if (mounted && _commentCtrl.text.trim() == commentText)
        {_commentCtrl.clear();}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to add comment: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _editComment(String commentId, String oldText) async {
    final controller = TextEditingController(text: oldText);

    final newText = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit comment"),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "Write your comment...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(dialogContext, text);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newText == null || newText == oldText || !mounted) return;

    try {
      await _commentsRef.doc(commentId).update({
        "text": newText,
        "edited": true,
        "editedAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to edit comment: $e")));
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete comment?"),
          content: const Text("Are you sure you want to delete this comment?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final commentRef = _commentsRef.doc(commentId);
        final commentDoc = await transaction.get(commentRef);

        if (!commentDoc.exists) return;

        transaction.delete(commentRef);

        final postRef =
            FirebaseFirestore.instance.collection("posts").doc(widget.postId);

        transaction.update(postRef, {
          "commentsCount": FieldValue.increment(-1),
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to delete comment: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                "Comments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _commentsRef
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final comments = snapshot.data!.docs;

                    if (comments.isEmpty) {
                      return const Center(child: Text("No comments yet"));
                    }

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final commentDoc = comments[index];
                        final comment =
                            commentDoc.data() as Map<String, dynamic>;

                        final String userId = comment["userId"] ?? "";
                        final String name = comment["name"] ?? "";
                        final String surname = comment["surname"] ?? "";
                        final String profileImage =
                            comment["profileImage"] ?? "";
                        final String fullName = "$name $surname".trim();
                        final String commentText = comment["text"] ?? "";

                        final bool isOwner = userId == currentUserId;
                        final bool canDelete = isOwner || _isOrganizer;

                        return ListTile(
                          leading: GestureDetector(
                            onTap: userId.isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            UserProfile(uid: userId),
                                      ),
                                    );
                                  },
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey.shade300,
                              child: ClipOval(
                                child: profileImage.isNotEmpty
                                    ? Image.network(
                                        profileImage,
                                        width: 36,
                                        height: 36,
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
                          title: GestureDetector(
                            onTap: userId.isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            UserProfile(uid: userId),
                                      ),
                                    );
                                  },
                            child: Text(
                              fullName.isEmpty ? "User" : fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff2b88b4),
                              ),
                            ),
                          ),
                          subtitle: Text(commentText),
                          trailing: (isOwner || canDelete)
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == "edit" && isOwner) {
                                      _editComment(commentDoc.id, commentText);
                                    } else if (value == "delete" && canDelete) {
                                      _deleteComment(commentDoc.id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (isOwner)
                                      const PopupMenuItem(
                                        value: "edit",
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text("Edit"),
                                          ],
                                        ),
                                      ),
                                    if (canDelete)
                                      const PopupMenuItem(
                                        value: "delete",
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        decoration: InputDecoration(
                          hintText: "Add a comment...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isSending ? null : _addComment,
                      tooltip: 'Send comment',
                      icon: _isSending
                          ? const BusyIndicator()
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
