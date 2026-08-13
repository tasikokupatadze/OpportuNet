import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class AddOlympScreen extends StatefulWidget {
  const AddOlympScreen({super.key});

  @override
  State<AddOlympScreen> createState() => _AddOlympScreenState();
}

class _AddOlympScreenState extends State<AddOlympScreen> {
  final _titlectrl = TextEditingController();

  final _descriptionctrl = TextEditingController();
  final _websitectrl = TextEditingController();
  final _agectrl = TextEditingController();
  final _costctrl = TextEditingController();

  File? _selectedImage;
  Uint8List? _webImage;

  final ImagePicker _picker = ImagePicker();

  Future<String?> _uploadImage() async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";

      final ref = FirebaseStorage.instance
          .ref()
          .child("activity_images")
          .child(fileName);

      if (kIsWeb) {
        if (_webImage == null) return null;
        await ref.putData(_webImage!);
      } else {
        if (_selectedImage == null) return null;
        await ref.putFile(_selectedImage!);
      }
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Image upload failed: $e");
      return null;
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    if (kIsWeb) {
      _webImage = await image.readAsBytes();
    } else {
      _selectedImage = File(image.path);
    }

    setState(() {});
  }

  Future<void> _publishActivity() async {
    final title = _titlectrl.text.trim();

    final description = _descriptionctrl.text.trim();
    final website = _websitectrl.text.trim();
    final age = _agectrl.text.trim();
    final cost = _costctrl.text.trim();

    if (title.isEmpty || description.isEmpty || website.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields."),
        ),
      );
      return;
    }

    if (_selectedImage == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an image."),
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final imageUrl = await _uploadImage();

      if (imageUrl == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image upload failed."),
          ),
        );
        return;
      }
      await FirebaseFirestore.instance.collection("olympiads").add({
        "title": title,
        "description": description,
        "website": website,
        "ageRequirements": age,
        "cost": cost,
        "imageUrl": imageUrl,
        "createdBy": user.uid,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Activity published!"),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titlectrl.dispose();
    _descriptionctrl.dispose();
    _websitectrl.dispose();
    _agectrl.dispose();
    _costctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset(
          'assets/opportunet1.png',
          height: 55,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),

            // Image placeholder
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade200,
                ),
                child: (_selectedImage == null && _webImage == null)
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 45),
                          SizedBox(height: 8),
                          Text("Add Activity Image"),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: kIsWeb
                            ? Image.memory(
                                _webImage!,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              )),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titlectrl,
              decoration: const InputDecoration(
                labelText: "Activity Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 16),

            TextField(
              controller: _descriptionctrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _websitectrl,
              decoration: const InputDecoration(
                labelText: "Website",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _agectrl,
              decoration: const InputDecoration(
                labelText: "Age Requirements",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _costctrl,
              decoration: const InputDecoration(
                labelText: "Cost",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _publishActivity,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  "Publish Activity",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
