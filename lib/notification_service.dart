import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'notifications_screen.dart';
import 'notification_task_queue.dart';

final notificationNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> opportunetMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FCM displays notification payloads while the app is in the background.
  // Do not display another local notification here: that would duplicate it.
}

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final instance = NotificationService._();
  static const _vapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');
  final _messaging = FirebaseMessaging.instance;
  bool _started = false;
  bool _enabled = false;
  bool _busy = false;
  String? _error;
  String? _uid;
  // Keep ownership information even when preferences or a remote write fails.
  final _trackedTokens = <String, Set<String>>{};
  final _deviceMutations = NotificationTaskQueue();
  static const _networkWait = Duration(seconds: 20);
  bool _wantsAlerts = false;
  int _session = 0;
  Map<String, dynamic>? _pendingOpen;
  String? _lastOpenedMessage;

  String _lang = 'en';

  bool get enabled => _enabled;

  /// Records the app language ('en' or 'ka') on this device's registration
  /// so pushes arrive in it. Safe to call on every build.
  void setLanguage(String code) {
    final lang = code == 'ka' ? 'ka' : 'en';
    if (lang == _lang) return;
    _lang = lang;
    final uid = _uid;
    if (uid == null || !_enabled) return;
    unawaited(_deviceMutations.run(() async {
      final prefs = await SharedPreferences.getInstance();
      for (final token in _knownTokens(uid, prefs).toList()) {
        await _deviceRef(uid, token).update({
          'lang': lang,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }).catchError((Object error) {
      // The next registration (app start or token refresh) writes it again.
      debugPrint('Push language update pending: ${error.runtimeType}');
    }));
  }
  bool get busy => _busy;
  String? get error => _error;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      FirebaseMessaging.onBackgroundMessage(
          opportunetMessagingBackgroundHandler);
    }
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    FirebaseMessaging.onMessage.listen((message) {
      final context = notificationNavigatorKey.currentContext;
      if (_uid == null || !_enabled || !_wantsAlerts || context == null) return;
      if (!context.mounted) return;
      final title = message.notification?.title ?? 'New OpportuNet update';
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(title),
        action:
            SnackBarAction(label: 'View', onPressed: () => _queueOpen(message)),
      ));
      
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_queueOpen);
    _messaging.onTokenRefresh.listen((token) async {
      final uid = _uid;
      final session = _session;
      if (!_enabled || !_wantsAlerts || uid == null) return;
      try {
        await _registerToken(uid, session, token).timeout(_networkWait);
      } catch (_) {
        if (_isCurrent(uid, session)) {
          _error =
              'Could not update this device. Turn alerts off and on to retry.';
          notifyListeners();
        }
      }
    });
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _queueOpen(initial);
    } catch (_) {
      // The in-app inbox still works if push is unavailable on this platform.
    }
    if (kIsWeb) {
      final query = Uri.base.queryParameters;
      if (query['type'] != null && query['targetId'] != null) {
        _pendingOpen = Map<String, dynamic>.from(query);
        openPending();
      }
    }
  }

  bool _isCurrent(String uid, int session) =>
      _uid == uid &&
      _session == session &&
      FirebaseAuth.instance.currentUser?.uid == uid;

  bool _canRegister(String uid, int session) =>
      _wantsAlerts && _isCurrent(uid, session);

  Future<void> _onAuthChanged(User? user) async {
    // A very fast Enable tap can precede the initial auth-stream event.
    if (_uid == user?.uid) return;
    var session = ++_session;
    _uid = user?.uid;
    _enabled = false;
    _wantsAlerts = false;
    _busy = user != null;
    _error = null;
    notifyListeners();
    if (user == null) return;
    var wasOptedIn = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      wasOptedIn = prefs.getBool('push_enabled_${user.uid}') ?? false;
      if (!_isCurrent(user.uid, session)) return;
      if (!wasOptedIn) {
        // Recover cleanup interrupted by closing the app while offline.
        if (_knownTokens(user.uid, prefs).isNotEmpty) {
          await _removeCurrentDevice(user.uid).timeout(_networkWait);
        }
        return;
      }
      // Restore an existing choice without prompting for permission on startup.
      final settings =
          await _messaging.getNotificationSettings().timeout(_networkWait);
      if (!_isCurrent(user.uid, session)) return;
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }
      if (kIsWeb && _vapidKey.isEmpty) return;
      _wantsAlerts = true;
      final token = await _messaging
          .getToken(vapidKey: kIsWeb ? _vapidKey : null)
          .timeout(_networkWait);
      if (token == null || !_canRegister(user.uid, session)) return;
      await _registerToken(user.uid, session, token).timeout(_networkWait);
    } catch (_) {
      if (_isCurrent(user.uid, session)) {
        session = ++_session;
        _wantsAlerts = false;
        _error = wasOptedIn
            ? 'Could not restore alerts. Tap Enable alerts to try again.'
            : 'Could not finish turning alerts off. Check your connection and try again.';
        _cleanUpFailedAttempt(user.uid);
      }
    } finally {
      if (_isCurrent(user.uid, session)) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> enable() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_busy || uid == null) return;
    // Auth stream may not have emitted yet on a very fast first tap.
    _uid = uid;
    var session = ++_session;
    _wantsAlerts = true;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      if (kIsWeb && _vapidKey.isEmpty) {
        throw StateError(
            'Web alerts need the Firebase Web Push certificate key. '
            'Start the app with --dart-define=FCM_WEB_VAPID_KEY=your_public_key.');
      }
      if (!kIsWeb &&
          defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        throw StateError(
            'Phone/browser alerts are available on Android, iOS, and supported browsers.');
      }
      final settings = await _messaging.requestPermission(
          alert: true, badge: true, sound: true);
      if (!_canRegister(uid, session)) return;
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        throw StateError(
            'Notifications are blocked. Allow them in your browser or phone settings, then try again.');
      }
      final token = await _messaging
          .getToken(vapidKey: kIsWeb ? _vapidKey : null)
          .timeout(_networkWait);
      if (!_canRegister(uid, session)) return;
      if (token == null) {
        throw StateError(
            'This device is not ready for alerts. Please try again.');
      }
      await _registerToken(uid, session, token).timeout(_networkWait);
    } catch (e) {
      if (_isCurrent(uid, session)) {
        session = ++_session;
        _wantsAlerts = false;
        _enabled = false;
        _error = e is StateError
            ? e.message.toString()
            : 'Could not enable alerts. Check your connection and notification setup, then try again.';
        _cleanUpFailedAttempt(uid);
        debugPrint('Enable notifications failed: ${e.runtimeType}');
      }
    } finally {
      if (_isCurrent(uid, session)) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  DocumentReference<Map<String, dynamic>> _deviceRef(
          String uid, String token) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notificationDevices')
          .doc(base64Url.encode(utf8.encode(token)));

  Set<String> _knownTokens(String uid, SharedPreferences prefs) {
    final tokens = _trackedTokens.putIfAbsent(uid, () => <String>{});
    tokens.addAll(prefs.getStringList('push_tokens_$uid') ?? const []);
    final legacyToken = prefs.getString('push_token_$uid');
    if (legacyToken != null) tokens.add(legacyToken);
    return tokens;
  }

  Future<void> _saveTokens(
      SharedPreferences prefs, String uid, Set<String> tokens) async {
    if (!await prefs.setStringList('push_tokens_$uid', tokens.toList())) {
      throw StateError('Could not save notification settings on this device.');
    }
  }

  Future<void> _registerToken(String uid, int session, String token) =>
      _deviceMutations.run(() async {
        if (!_canRegister(uid, session)) return;
        final prefs = await SharedPreferences.getInstance();
        if (!_canRegister(uid, session)) return;
        final tokens = _knownTokens(uid, prefs)..add(token);
        // Record before sending: a queued/offline write may complete after the
        // caller times out or cancels. Cleanup must still know what to delete.
        await _saveTokens(prefs, uid, tokens);
        if (!_canRegister(uid, session)) return;
        await _deviceRef(uid, token).set({
          'token': token,
          'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
          'lang': _lang,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        for (final old in tokens.where((value) => value != token).toList()) {
          await _deviceRef(uid, old).delete();
          tokens.remove(old);
          await _saveTokens(prefs, uid, tokens);
        }
        await prefs.remove('push_token_$uid');
        if (!_canRegister(uid, session)) return;
        if (!await prefs.setBool('push_enabled_$uid', true)) {
          throw StateError(
              'Could not save notification settings on this device.');
        }
        if (_canRegister(uid, session)) {
          _enabled = true;
        } else if (_uid == uid && !_wantsAlerts) {
          // A stop may arrive while the local preference write is in flight.
          await prefs.setBool('push_enabled_$uid', false);
        }
      });

  void _cleanUpFailedAttempt(String uid) {
    // This is queued before controls become available again. A retry cannot
    // overtake cleanup, even if the failed attempt's remote write is pending.
    unawaited(_removeCurrentDevice(uid).catchError((Object error) {
      debugPrint('Notification cleanup pending: ${error.runtimeType}');
    }));
  }

  Future<void> disable() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final session = ++_session;
    _wantsAlerts = false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _recordStoppedChoice(uid, session).timeout(_networkWait);
      await _removeCurrentDevice(uid).timeout(_networkWait);
      if (_isCurrent(uid, session)) _enabled = false;
    } catch (_) {
      if (_isCurrent(uid, session)) {
        _error =
            'Could not confirm alerts are off. Check your connection and try again.';
      }
    } finally {
      if (_isCurrent(uid, session)) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> _recordStoppedChoice(String uid, int session) async {
    // Persist the choice before waiting on an offline write at the queue head.
    // Otherwise restarting the app could restore a previous opted-in value.
    final prefs = await SharedPreferences.getInstance();
    if (!_isCurrent(uid, session) || _wantsAlerts) return;
    if (!await prefs.setBool('push_enabled_$uid', false)) {
      throw StateError('Could not save notification settings on this device.');
    }
  }

  Future<void> _removeCurrentDevice(String uid) =>
      _deviceMutations.run(() async {
        final prefs = await SharedPreferences.getInstance();
        // A restart must not restore alerts after a failed/offline disable.
        if (!await prefs.setBool('push_enabled_$uid', false)) {
          throw StateError(
              'Could not save notification settings on this device.');
        }
        final tokens = _knownTokens(uid, prefs);
        for (final token in tokens.toList()) {
          await _deviceRef(uid, token).delete();
          tokens.remove(token);
          await _saveTokens(prefs, uid, tokens);
        }
        await prefs.remove('push_token_$uid');
        await prefs.remove('push_tokens_$uid');
        if (_uid == uid && !_wantsAlerts) {
          _enabled = false;
          notifyListeners();
        }
      });

  Future<void> signOut() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      await FirebaseAuth.instance.signOut();
      return;
    }
    // Invalidate pending permission/getToken work immediately. Already-started
    // Firestore writes remain ahead of removal in the mutation queue.
    _uid = uid;
    final session = ++_session;
    _wantsAlerts = false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      // The timeout only bounds the caller's wait, never the queue itself.
      // On timeout the user stays signed in; cleanup may finish, but logout
      // only proceeds when this call observed confirmed cleanup completion.
      await _recordStoppedChoice(uid, session).timeout(_networkWait);
      await _removeCurrentDevice(uid).timeout(_networkWait);
      if (!_isCurrent(uid, session)) {
        throw StateError('The account changed. Please try logging out again.');
      }
      _enabled = false;
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      if (_isCurrent(uid, session)) {
        _error =
            'Could not finish logging out. Check your connection and try again.';
      }
      rethrow;
    } finally {
      if (_isCurrent(uid, session)) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  void _queueOpen(RemoteMessage message) {
    final id = message.messageId;
    if (id != null && id == _lastOpenedMessage) return;
    _lastOpenedMessage = id;
    _pendingOpen = Map<String, dynamic>.from(message.data);
    openPending();
  }

  void openPending() {
    final context = notificationNavigatorKey.currentContext;
    if (FirebaseAuth.instance.currentUser == null ||
        context == null ||
        _pendingOpen == null) {return;}
    final data = _pendingOpen!;
    _pendingOpen = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && FirebaseAuth.instance.currentUser != null) {
        openAppNotification(context, data);
      }
    });
  }
}
