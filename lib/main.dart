import 'notification_service.dart';
import 'notification_bell.dart';
import 'app_ui.dart';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'ai_chat.dart';
import 'calendar.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
// null = follow the device language.
ValueNotifier<Locale?> localeNotifier = ValueNotifier(null);

const String profileImageKey = 'profile_image';
const String aboutMeKey = "about_me";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();

  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

  themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  final languageCode = prefs.getString('languageCode');
  if (languageCode != null) localeNotifier.value = Locale(languageCode);

  // On Android, use the Firebase app from google-services.json: it is the one
  // registered for this package name and signing key, which Google Sign-In
  // needs. The Dart android options point at an older Firebase app.
  await Firebase.initializeApp(
    options: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? null
        : DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
  unawaited(NotificationService.instance.start());
}

List<Map<String, String>> users = [];

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeNotifier, localeNotifier]),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: notificationNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'OpportuNet',
          theme: appTheme(Brightness.light),
          darkTheme: appTheme(Brightness.dark),
          themeMode: themeNotifier.value,
          locale: localeNotifier.value,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthGate(),
          builder: (context, child) {
            // Push texts are sent in this language (see notification-functions).
            NotificationService.instance.setLanguage(context.appLanguageCode);
            return child!;
          },
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
  bool _isOrganizer = false;

  final ImagePicker _picker = ImagePicker();

  final TextEditingController _abtMePrflctrl = TextEditingController();
  final TextEditingController _namePrflctrl = TextEditingController();
  final TextEditingController _surnamePrflctrl = TextEditingController();
  final TextEditingController _agePrflctrl = TextEditingController();
  // Subject keys (kFilterSubjects), used by "For you" on Home and Ask AI.
  Set<String> _interests = {};
  late String uid;
  final ScrollController scrollctrl = ScrollController();

  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    uid = user!.uid;
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
          'aboutMe': '',
          'profileImage': '',
          'role': 'user',
        });

        doc = await docRef.get();
      }

      final data = doc.data() ?? <String, dynamic>{};

      // Emails used to be stored on profiles, where any signed-in user could
      // read them. Remove the old copy; Firebase Auth already has the email.
      if (data.containsKey('email')) {
        docRef.update({'email': FieldValue.delete()}).ignore();
      }

      if (!mounted) return;

      setState(() {
        _namePrflctrl.text = data['name'] ?? '';
        _surnamePrflctrl.text = data['surname'] ?? '';
        _agePrflctrl.text = (data['age'] ?? '').toString();
        _abtMePrflctrl.text = data['aboutMe'] ?? '';
        final interests = data['interests'];
        _interests = interests is List
            ? interests.whereType<String>().toSet()
            : <String>{};
        _profileImagePath = data['profileImage'] ?? '';
        _isOrganizer = (data['role'] ?? 'user') == 'organizer';
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.profileLoadFailed)));
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
        'interests': [
          for (final s in kFilterSubjects)
            if (_interests.contains(s)) s,
        ],
        'profileImage': _profileImagePath ?? '',
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
        SnackBar(content: Text(context.l10n.profileUpdated)),
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.profileSaveFailed)));

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
    super.dispose();
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
        SnackBar(content: Text(context.l10n.profileImageFailed)),
      );
    }
  }

  // Instagram-style counts; loaded once and refreshed after visiting Saved.
  Future<int?>? _postCount;
  Future<int?>? _savedCount;

  void _loadCounts() {
    final posts = FirebaseFirestore.instance.collection('posts');
    _postCount = posts
        .where('userId', isEqualTo: uid)
        .count()
        .get()
        .then((s) => s.count);
    _savedCount = posts
        .where('savedBy', arrayContains: uid)
        .count()
        .get()
        .then((s) => s.count);
  }

  Future<void> _openSavedPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedPostsScreen(currentUserId: user.uid),
      ),
    );
    if (mounted) setState(_loadCounts);
  }

  Future<void> _logOut() async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.logoutFailed;
    try {
      await NotificationService.instance.signOut();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  Future<void> _openEditProfile() async {
    final before = [
      _namePrflctrl.text,
      _surnamePrflctrl.text,
      _agePrflctrl.text,
      _abtMePrflctrl.text,
    ];
    final interestsBefore = {..._interests};

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var saving = false;
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            Widget field(
              TextEditingController controller,
              String label,
              String hint, {
              TextInputType? keyboardType,
              int maxLines = 1,
            }) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.editProfile,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    field(_namePrflctrl, context.l10n.name,
                        context.l10n.enterName),
                    field(_surnamePrflctrl, context.l10n.surname,
                        context.l10n.enterSurname),
                    field(_agePrflctrl, context.l10n.age, context.l10n.enterAge,
                        keyboardType: TextInputType.number),
                    field(_abtMePrflctrl, context.l10n.aboutMe,
                        context.l10n.aboutMeHint,
                        maxLines: 4),
                    Text(context.l10n.interests,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final subject in kFilterSubjects)
                          FilterChip(
                            avatar: Icon(kSubjectIcons[subject], size: 16),
                            label: Text(subjectLabel(context, subject)),
                            selected: _interests.contains(subject),
                            onSelected: (selected) => setSheet(() {
                              if (selected) {
                                _interests.add(subject);
                              } else {
                                _interests.remove(subject);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setSheet(() => saving = true);
                              final ok = await _saveProfile();
                              if (!sheetContext.mounted) return;
                              if (ok) {
                                Navigator.pop(sheetContext, true);
                              } else {
                                setSheet(() => saving = false);
                              }
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: saving
                          ? const BusyIndicator()
                          : Text(context.l10n.save),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved != true) {
      // Closed without saving: put the old values back.
      _namePrflctrl.text = before[0];
      _surnamePrflctrl.text = before[1];
      _agePrflctrl.text = before[2];
      _abtMePrflctrl.text = before[3];
      _interests = interestsBefore;
    }
    if (mounted) setState(() {});
  }

  Widget _stat(Future<int?> count, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<int?>(
              future: count,
              builder: (context, snapshot) => Text(
                snapshot.data?.toString() ?? '–',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _profileTab() {
    if (_postCount == null) _loadCounts();
    final colors = Theme.of(context).colorScheme;
    final fullName = "${_namePrflctrl.text} ${_surnamePrflctrl.text}".trim();
    final bio = _abtMePrflctrl.text.trim();

    return ContentWidth(
      maxWidth: 800,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          // Photo + counts
          Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: colors.surfaceContainerHighest,
                      backgroundImage: _getProfileImage(),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: brandBlueDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat(_postCount!, context.l10n.posts),
                    _stat(_savedCount!, context.l10n.saved,
                        onTap: _openSavedPosts),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name + bio
          Text(
            fullName.isEmpty ? context.l10n.yourProfile : fullName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            bio.isEmpty ? context.l10n.aboutMePrompt : bio,
            style: TextStyle(
              fontSize: 14,
              color: bio.isEmpty ? colors.onSurfaceVariant : colors.onSurface,
            ),
          ),
          const SizedBox(height: 14),

          // Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _openEditProfile,
                  child: Text(context.l10n.editProfile),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _openSavedPosts,
                  icon: const Icon(Icons.bookmark_border, size: 18),
                  label: Text(context.l10n.savedPosts),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Settings
          Text(
            context.l10n.settings,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: colors.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Column(
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, mode, _) => SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: Text(context.l10n.appearance),
                    subtitle: Text(context.l10n.appearanceSubtitle),
                    value: mode == ThemeMode.dark,
                    onChanged: (value) async {
                      themeNotifier.value =
                          value ? ThemeMode.dark : ThemeMode.light;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isDarkMode', value);
                    },
                  ),
                ),
                Divider(height: 1, color: colors.outlineVariant),
                ListTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(context.l10n.language),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    // Full width so each language gets half the row and
                    // "ქართული" never wraps.
                    child: SizedBox(
                      width: double.infinity,
                      // Language names stay in their own language.
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: brandBlue,
                          selectedForegroundColor: brandInk,
                          side: const BorderSide(color: brandBlueDark),
                        ),
                        segments: const [
                          ButtonSegment(value: 'ka', label: Text('ქართული')),
                          ButtonSegment(value: 'en', label: Text('English')),
                        ],
                        selected: {
                          Localizations.localeOf(context).languageCode,
                        },
                        onSelectionChanged: (values) async {
                          localeNotifier.value = Locale(values.first);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('languageCode', values.first);
                        },
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, color: colors.outlineVariant),
                ListTile(
                  leading: Icon(Icons.logout, color: colors.error),
                  title: Text(
                    context.l10n.logOut,
                    style: TextStyle(color: colors.error),
                  ),
                  onTap: _logOut,
                ),
              ],
            ),
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
        return AiChat(uid: uid);

      case 3:
        return _profileTab();
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
          leading: IconButton(
            key: const ValueKey('home-calendar-shortcut'),
            tooltip: context.l10n.academicCalendar,
            icon:
                const Icon(Icons.calendar_month_outlined, color: brandBlueDark),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CalendarScreen(isOrganizer: _isOrganizer),
              ),
            ),
          ),
          actions: const [NotificationBell()],
          title: const AppLogo(height: 60),
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
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: brandBlueDark),
              selectedIcon: Icon(Icons.home_rounded, color: brandBlueDark),
              label: context.l10n.navHome,
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined, color: brandBlueDark),
              selectedIcon: Icon(Icons.forum_rounded, color: brandBlueDark),
              label: context.l10n.navCommunity,
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, color: brandBlueDark),
              selectedIcon: Icon(Icons.auto_awesome, color: brandBlueDark),
              label: context.l10n.navAskAi,
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: brandBlueDark),
              selectedIcon: Icon(Icons.person_rounded, color: brandBlueDark),
              label: context.l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
