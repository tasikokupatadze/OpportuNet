

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'userprofile.dart';
import 'commentssheet.dart';
import 'createpost.dart';

const kAccent = Color(0xff84d6fe);
const kAccentDark = Color(0xff2a9fd8);
const kBg = Color(0xfff4f9fc);
const kBorder = Color(0xffdbeaf2);
const kInk = Color(0xff13202b);

class FeedCategory {
  final String name;
  final IconData icon;
  final Color color;
  const FeedCategory(this.name, this.icon, this.color);
}

const kCategories = <FeedCategory>[
  FeedCategory("All", Icons.apps_rounded, kAccentDark),
  FeedCategory("Math", Icons.calculate_outlined, Color(0xff6c7ae0)),
  FeedCategory("Coding", Icons.code_rounded, Color(0xff1fa67a)),
  FeedCategory("Arts", Icons.palette_outlined, Color(0xffe0724f)),
  FeedCategory("Languages", Icons.translate_rounded, Color(0xffd29a1e)),
  FeedCategory("Career", Icons.work_outline_rounded, Color(0xff8a6d5b)),
  FeedCategory("General", Icons.forum_outlined, Color(0xff6b7a86)),
];

FeedCategory categoryOf(String name) => kCategories.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => kCategories.last,
    );

enum FeedSort { newest, popular, saved }

class CommunityFeed extends StatefulWidget {
  const CommunityFeed({super.key});
  @override
  State<CommunityFeed> createState() => _CommunityFeedState();
}

class _CommunityFeedState extends State<CommunityFeed> {
  String _category = "All";
  FeedSort _sort = FeedSort.newest;
  String _query = "";
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _apply(List<QueryDocumentSnapshot> docs) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final q = _query.trim().toLowerCase();
    final list = docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final cat = (data["category"] ?? "General") as String;
      if (_category != "All" && cat.toLowerCase() != _category.toLowerCase())
        return false;
      if (_sort == FeedSort.saved &&
          !(List.from(data["savedBy"] ?? []).contains(uid))) return false;
      if (q.isNotEmpty) {
        final hay =
            "${data["text"] ?? ""} ${data["username"] ?? ""}".toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
    if (_sort == FeedSort.popular) {
      list.sort((a, b) {
        final la = ((a.data() as Map)["likes"] ?? 0) as int;
        final lb = ((b.data() as Map)["likes"] ?? 0) as int;
        return lb.compareTo(la);
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("posts")
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            final all = snapshot.data?.docs ?? [];
            final counts = <String, int>{"All": all.length};
            for (final d in all) {
              final c = categoryOf(
                      ((d.data() as Map)["category"] ?? "General") as String)
                  .name;
              counts[c] = (counts[c] ?? 0) + 1;
            }
            final posts = _apply(all);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header()),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedFilters(
                    child: _filterBar(counts),
                  ),
                ),
                if (snapshot.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _empty(Icons.error_outline, "Something went wrong",
                        "${snapshot.error}"),
                  )
                else if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                        child: CircularProgressIndicator(color: kAccentDark)),
                  )
                else if (posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _empty(
                      categoryOf(_category).icon,
                      _category == "All"
                          ? "No posts yet"
                          : "No $_category posts yet",
                      "Be the first to start a conversation.",
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 100),
                    sliver: SliverList.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, i) =>
                          FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .get(),
                        builder: (context, roleSnapshot) {
                          final roleData = roleSnapshot.data?.data()
                              as Map<String, dynamic>?;
                          final isOrganizer = roleData?['role'] == 'organizer';

                          return PostCard(
                            post: posts[i],
                            isOrganizer: isOrganizer,
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kInk,
        elevation: 2,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CreatePost(
                      category: _category == "All" ? null : _category)));
        },
        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
        label: const Text("New post",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: "Search posts or people",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _query = "";
                        }),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: kAccentDark, width: 1.5)),
              ),
            ),
          ],
        ),
      );

  Widget _filterBar(Map<String, int> counts) => Container(
        color: kBg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: kCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = kCategories[i];
                  final selected = c.name == _category;
                  final n = counts[c.name] ?? 0;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected ? c.color : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: selected ? c.color : kBorder),
                      ),
                      child: Row(children: [
                        Icon(c.icon,
                            size: 17, color: selected ? Colors.white : c.color),
                        const SizedBox(width: 6),
                        Text(c.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                color: selected ? Colors.white : kInk)),
                        if (n > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : c.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text("$n",
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? Colors.white : c.color)),
                          ),
                        ],
                      ]),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(children: [
                _sortTab("Newest", FeedSort.newest),
                _sortTab("Popular", FeedSort.popular),
                _sortTab("Saved", FeedSort.saved),
              ]),
            ),
          ],
        ),
      );

  Widget _sortTab(String label, FeedSort s) {
    final sel = _sort == s;
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: InkWell(
        onTap: () => setState(() => _sort = s),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? kInk : kInk.withValues(alpha: 0.45))),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 3,
            width: sel ? 22 : 0,
            decoration: BoxDecoration(
                color: kAccentDark, borderRadius: BorderRadius.circular(2)),
          ),
        ]),
      ),
    );
  }

  Widget _empty(IconData icon, String title, String sub) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.18),
                  shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: kAccentDark),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 4),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(color: kInk.withValues(alpha: 0.55))),
          ]),
        ),
      );
}

class _PinnedFilters extends SliverPersistentHeaderDelegate {
  final Widget child;
  _PinnedFilters({required this.child});
  @override
  double get minExtent => 88;
  @override
  double get maxExtent => 88;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);
  @override
  bool shouldRebuild(covariant _PinnedFilters old) => true;
}

class PostCard extends StatelessWidget {
  final QueryDocumentSnapshot post;
  final bool isOrganizer;
  const PostCard({super.key, required this.post, required this.isOrganizer});

  void _openProfile(BuildContext context, String uid) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => UserProfile(uid: uid)));
  }

  @override
  Widget build(BuildContext context) {
    final data = post.data() as Map<String, dynamic>;
    final String userId = data["userId"] ?? "";
    final String username = data["username"] ?? "user";
    final String text = data["text"] ?? "";
    final String imageUrl = data["imageUrl"] ?? "";
    final int likes = data["likes"] ?? 0;
    final int commentsCount = data["commentsCount"] ?? 0;
    final cat = categoryOf((data["category"] ?? "General") as String);
    final user = FirebaseAuth.instance.currentUser;
    final isLiked =
        user != null && List.from(data["likedBy"] ?? []).contains(user.uid);
    final isSaved =
        user != null && List.from(data["savedBy"] ?? []).contains(user.uid);
    final ts = data["timestamp"];
    final ref = FirebaseFirestore.instance.collection("posts").doc(post.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header: avatar, username, category, timestamp, menu.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openProfile(context, userId),
                  child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                    builder: (context, s) {
                      String img = "";
                      if (s.hasData && s.data!.exists) {
                        img = (s.data!.data()
                                as Map<String, dynamic>)["profileImage"] ??
                            "";
                      }

                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: cat.color.withValues(alpha: 0.15),
                        backgroundImage:
                            img.isNotEmpty ? NetworkImage(img) : null,
                        child: img.isEmpty
                            ? Text(
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : "?",
                                style: TextStyle(
                                  color: cat.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openProfile(context, userId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: kInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(cat.icon, size: 13, color: cat.color),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                cat.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cat.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (ts is Timestamp) ...[
                              Text(
                                "  ·  ",
                                style: TextStyle(
                                  color: kInk.withValues(alpha: 0.35),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  _ago(ts.toDate()),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kInk.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: kInk.withValues(alpha: 0.5),
                  ),
                  onSelected: (v) async {
                    if (v == "profile") {
                      _openProfile(context, userId);
                      return;
                    }

                    if (v == "delete" && user != null) {
                      if (user.uid != userId && !isOrganizer) return;

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text("Delete post?"),
                          content: const Text(
                            "Are you sure you want to permanently delete this post?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      try {
                        await ref.delete();

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Post deleted")),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Could not delete post: $e"),
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: "profile",
                      child: Text("View profile"),
                    ),
                    if (user?.uid == userId || isOrganizer)
                      const PopupMenuItem(
                        value: "delete",
                        child: Text("Delete"),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Post text: outside the header Row.
          if (text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: kInk,
                ),
              ),
            ),

          // Post image: outside the header Row.
          if (imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: kBg,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Like, comments, and save actions.
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            child: Row(
              children: [
                _action(
                  icon: isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isLiked
                      ? const Color(0xffe5484d)
                      : kInk.withValues(alpha: 0.7),
                  label: "$likes",
                  onTap: () async {
                    if (user == null) return;
                    await ref.update({
                      "likedBy": isLiked
                          ? FieldValue.arrayRemove([user.uid])
                          : FieldValue.arrayUnion([user.uid]),
                      "likes": FieldValue.increment(isLiked ? -1 : 1),
                    });
                  },
                ),
                _action(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: kInk.withValues(alpha: 0.7),
                  label: "$commentsCount",
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      builder: (_) => CommentsSheet(postId: post.id),
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isSaved
                        ? const Color(0xffe8b100)
                        : kInk.withValues(alpha: 0.7),
                  ),
                  onPressed: () async {
                    if (user == null) return;

                    if (isSaved) {
                      await ref.update({
                        "savedBy": FieldValue.arrayRemove([user.uid]),
                      });
                    } else {
                      await ref.set({
                        "savedBy": FieldValue.arrayUnion([user.uid]),
                      }, SetOptions(merge: true));
                    }

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isSaved ? "Removed from saved posts" : "Saved",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
          {required IconData icon,
          required Color color,
          required String label,
          required VoidCallback onTap}) =>
      InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: kInk.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return "now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";
    return "${d.day}/${d.month}/${d.year}";
  }
}
