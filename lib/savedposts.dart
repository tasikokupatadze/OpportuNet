import 'package:material_ui/material_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_ui.dart';
import 'community_feed.dart';

class SavedPostsScreen extends StatefulWidget {
  final String currentUserId;
  const SavedPostsScreen({super.key, required this.currentUserId});
  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  late Stream<QuerySnapshot> _stream;
  bool _isOrganizer = false;
  @override
  void initState() {
    super.initState();
    _connect();
    _loadRole();
  }

  void _connect() {
    _stream = FirebaseFirestore.instance
        .collection('posts')
        .where('savedBy', arrayContains: widget.currentUserId)
        .snapshots();
  }

  Future<void> _loadRole() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      if (mounted)
        {setState(() => _isOrganizer = doc.data()?['role'] == 'organizer');}
    } catch (_) {
      // Role-specific actions stay hidden when the role cannot be loaded.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(centerTitle: true, title: const AppLogo()),
        body: ContentWidth(
          maxWidth: 760,
          child: StreamBuilder<QuerySnapshot>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return LoadError(
                  message: context.l10n.loadSavedFailed,
                  onRetry: () => setState(_connect),
                );
              }
              if (!snapshot.hasData)
                {return const Center(child: CircularProgressIndicator());}
              final posts = snapshot.data!.docs;
              if (posts.isEmpty)
               { return Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      context.l10n.noSavedPostsYet,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );}
              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: posts.length,
                itemBuilder: (_, i) =>
                    PostCard(post: posts[i], isOrganizer: _isOrganizer),
              );
            },
          ),
        ),
      );
}
