import 'app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'userprofile.dart';
import 'commentssheet.dart';
import 'createpost.dart';

const kAccent = brandBlue;
const kAccentDark = brandBlueDark;

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
  late Stream<QuerySnapshot> _postsStream = _connectPosts();
  Stream<QuerySnapshot> _connectPosts() => FirebaseFirestore.instance
      .collection('posts')
      .orderBy('timestamp', descending: true)
      .snapshots();

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
      if (_category != "All" && cat.toLowerCase() != _category.toLowerCase()) {
        return false;
      }
      if (_sort == FeedSort.saved &&
          !(List.from(data["savedBy"] ?? []).contains(uid))) {
        return false;
      }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ContentWidth(
        maxWidth: 760,
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<QuerySnapshot>(
            stream: _postsStream,
            builder: (context, snapshot) {
              final all = snapshot.data?.docs ?? [];
              final counts = <String, int>{"All": all.length};
              for (final d in all) {
                final c = categoryOf(
                  ((d.data() as Map)["category"] ?? "General") as String,
                ).name;
                counts[c] = (counts[c] ?? 0) + 1;
              }
              final posts = _apply(all);

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header()),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedFilters(
                      extent: 118 +
                          (MediaQuery.textScalerOf(context).scale(14) - 14) * 3,
                      child: _filterBar(counts),
                    ),
                  ),
                  if (snapshot.hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: LoadError(
                        message: context.l10n.loadPostsFailed,
                        onRetry: () =>
                            setState(() => _postsStream = _connectPosts()),
                      ),
                    )
                  else if (snapshot.connectionState == ConnectionState.waiting)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: kAccentDark),
                      ),
                    )
                  else if (posts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _empty(
                        categoryOf(_category).icon,
                        _query.trim().isNotEmpty
                            ? context.l10n.noMatchingPosts
                            : _sort == FeedSort.saved
                                ? context.l10n.noSavedPostsHere
                                : _category == 'All'
                                    ? context.l10n.noPostsYet
                                    : context.l10n.noCategoryPosts(
                                        postCategoryLabel(context, _category),
                                      ),
                        _query.trim().isNotEmpty
                            ? context.l10n.tryDifferentSearch
                            : _sort == FeedSort.saved
                                ? context.l10n.saveWithBookmark
                                : context.l10n.beFirst,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(14, 6, 14, 100),
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
                            final isOrganizer =
                                roleData?['role'] == 'organizer';

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
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        elevation: 2,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreatePost(category: _category == "All" ? null : _category),
            ),
          );
        },
        icon: Icon(
          Icons.edit_rounded,
          color: Theme.of(context).colorScheme.surface,
          size: 20,
        ),
        label: Text(
          context.l10n.newPost,
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: context.l10n.searchPostsOrPeople,
                prefixIcon: Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _query = "";
                        }),
                      ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: kAccentDark, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _filterBar(Map<String, int> counts) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48 *
                  (MediaQuery.textScalerOf(context).scale(14) / 14)
                      .clamp(1.0, 3.0),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 14),
                itemCount: kCategories.length,
                separatorBuilder: (_, __) => SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = kCategories[i];
                  final selected = c.name == _category;
                  final n = counts[c.name] ?? 0;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c.name),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? brandInk
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected
                              ? brandInk
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            c.icon,
                            size: 17,
                            color: selected ? Colors.white : c.color,
                          ),
                          SizedBox(width: 6),
                          Text(
                            postCategoryLabel(context, c.name),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: selected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (n > 0) ...[
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : c.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$n",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? Colors.white : c.color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                children: [
                  _sortTab(context.l10n.sortNewest, FeedSort.newest),
                  _sortTab(context.l10n.sortPopular, FeedSort.popular),
                  _sortTab(context.l10n.saved, FeedSort.saved),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _sortTab(String label, FeedSort s) {
    final sel = _sort == s;
    return Padding(
      padding: EdgeInsets.only(right: 18),
      child: InkWell(
        onTap: () => setState(() => _sort = s),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                ),
              ),
              SizedBox(height: 4),
              AnimatedContainer(
                duration: Duration(milliseconds: 180),
                height: 3,
                width: sel ? 22 : 0,
                decoration: BoxDecoration(
                  color: kAccentDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(IconData icon, String title, String sub) => Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: kAccentDark),
              ),
              SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      );
}

class _PinnedFilters extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double extent;
  _PinnedFilters({required this.child, required this.extent});
  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      SizedBox.expand(child: child);
  @override
  bool shouldRebuild(covariant _PinnedFilters old) => true;
}

class PostCard extends StatelessWidget {
  final QueryDocumentSnapshot post;
  final bool isOrganizer;
  const PostCard({super.key, required this.post, required this.isOrganizer});

  void _openProfile(BuildContext context, String uid) {
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.invalidUserProfile)),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfile(uid: uid)),
    );
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
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header: avatar, username, category, timestamp, menu.
          Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 4, 0),
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
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openProfile(context, userId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(cat.icon, size: 13, color: cat.color),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                postCategoryLabel(context, cat.name),
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  _ago(context, ts.toDate()),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.45),
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
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
                          title: Text(context.l10n.deletePostTitle),
                          content: Text(
                            context.l10n.deletePostBody,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: Text(context.l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: Text(
                                context.l10n.delete,
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
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                            SnackBar(content: Text(context.l10n.postDeleted)));
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(context.l10n.postDeleteFailed)),
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: "profile",
                      child: Text(context.l10n.viewProfile),
                    ),
                    if (user?.uid == userId || isOrganizer)
                      PopupMenuItem(
                          value: "delete", child: Text(context.l10n.delete)),
                  ],
                ),
              ],
            ),
          ),

          // Post text: outside the header Row.
          // Post text
          if (text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: _PostBody(key: ValueKey(post.id), text: text),
            ),

          // Post image: outside the header Row.
          if (imageUrl.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Center(
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
            padding: EdgeInsets.fromLTRB(6, 6, 6, 6),
            child: Row(
              children: [
                _action(
                  context,
                  icon: isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isLiked
                      ? Color(0xffe5484d)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
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
                  context,
                  icon: Icons.chat_bubble_outline_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  label: "$commentsCount",
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      builder: (_) => CommentsSheet(postId: post.id),
                    );
                  },
                ),
                Spacer(),
                IconButton(
                  icon: Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isSaved
                        ? Color(0xffe8b100)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
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
                          isSaved
                              ? context.l10n.removedFromSaved
                              : context.l10n.savedConfirm,
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
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) =>
      InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 21, color: color),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  static String _ago(BuildContext context, DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return context.l10n.agoNow;
    if (diff.inMinutes < 60) return context.l10n.agoMinutes(diff.inMinutes);
    if (diff.inHours < 24) return context.l10n.agoHours(diff.inHours);
    if (diff.inDays < 7) return context.l10n.agoDays(diff.inDays);
    return "${d.day}/${d.month}/${d.year}";
  }
}

class _PostBody extends StatefulWidget {
  const _PostBody({super.key, required this.text});

  final String text;

  @override
  State<_PostBody> createState() => _PostBodyState();
}

class _PostBodyState extends State<_PostBody> {
  static const int _previewLines = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth <= 480;
        final style = DefaultTextStyle.of(context).style.copyWith(
              fontSize: compact ? 13.0 : 15.0,
              height: compact ? 1.35 : 1.45,
              letterSpacing: 0.0,
              color: Theme.of(context).colorScheme.onSurface,
            );

        if (!compact) return Text(widget.text, style: style);

        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
          maxLines: _previewLines,
          ellipsis: '…',
        )..layout(maxWidth: constraints.maxWidth);

        final needsToggle = painter.didExceedMaxLines;
        painter.dispose();

        if (!needsToggle) return Text(widget.text, style: style);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : _previewLines,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child:
                  Text(_expanded ? context.l10n.seeLess : context.l10n.seeMore),
            ),
          ],
        );
      },
    );
  }
}
