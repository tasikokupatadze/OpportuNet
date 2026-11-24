import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as httpai;
import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_ui.dart';

typedef _Msg = QueryDocumentSnapshot<Map<String, dynamic>>;

/// Messages written before chats existed have no chatId; they form one chat
/// under this id.
const _earlierChatId = '';

String _chatIdOf(_Msg doc) =>
    (doc.data()['chatId'] as String?) ?? _earlierChatId;

bool _isErrorReply(String reply) =>
    reply.startsWith('Error') || reply.startsWith('API Error');

/// Groups messages (newest first) into chats, most recently active chat first.
// shortcut: chats are derived from every message the user has, fine for
// hundreds of messages; move to a `chats` collection if users reach thousands.
Map<String, List<_Msg>> _groupChats(List<_Msg> newestFirst) {
  final chats = <String, List<_Msg>>{};
  for (final doc in newestFirst) {
    chats.putIfAbsent(_chatIdOf(doc), () => []).add(doc);
  }
  return chats;
}

String _chatTitle(List<_Msg> newestFirst) {
  final first = (newestFirst.last.data()['text'] as String? ?? '').trim();
  return first.isEmpty ? 'New chat' : first.replaceAll(RegExp(r'\s+'), ' ');
}

class AiChat extends StatefulWidget {
  final String uid;
  const AiChat({super.key, required this.uid});

  @override
  State<AiChat> createState() => _AiChatState();
}

class _AiChatState extends State<AiChat> {
  final _input = TextEditingController();
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  late String _chatId = _newChatId();

  CollectionReference<Map<String, dynamic>> get _messages =>
      FirebaseFirestore.instance.collection('messages');

  String _newChatId() => _messages.doc().id;

  void _connect() {
    _stream = _messages
        .where('userId', isEqualTo: widget.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// All of this user's messages in [chatId], oldest first.
  Future<List<_Msg>> _fetchChat(String chatId) async {
    final snapshot =
        await _messages.where('userId', isEqualTo: widget.uid).get();
    final docs = snapshot.docs.where((d) => _chatIdOf(d) == chatId).toList();
    docs.sort((a, b) {
      final aTime = a.data()['timestamp'];
      final bTime = b.data()['timestamp'];
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return (aTime as Timestamp).compareTo(bTime as Timestamp);
    });
    return docs;
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    final chatId = _chatId; // the user may switch chats while we wait
    _input.clear();

    DocumentReference? docRef;
    try {
      docRef = await _messages.add({
        'text': text,
        'userId': widget.uid,
        'chatId': chatId,
        'timestamp': FieldValue.serverTimestamp(),
        'aiResponse': null,
      });

      final chat = await _fetchChat(chatId);
      final recent = chat.length > 10 ? chat.sublist(chat.length - 10) : chat;

      final history = <Map<String, dynamic>>[
        {
          'role': 'system',
          'content': 'You are a helpful admissions assistant for Georgian students who want to study abroad. Give clear, practical, supportive answers. '
              'Today is ${DateTime.now().toIso8601String().substring(0, 10)}. '
              'Your replies are read on a phone screen, so never use tables. '
              'Use short headings, bullet points and short paragraphs instead. '
              'Reply in the same language the user writes in.',
        },
      ];
      for (final doc in recent) {
        // The new message may not have its server timestamp yet; it is
        // appended last below instead.
        if (doc.id == docRef.id) continue;
        history.add({'role': 'user', 'content': doc['text'] ?? ''});
        final reply = doc['aiResponse']?.toString() ?? '';
        if (reply.isNotEmpty && !_isErrorReply(reply)) {
          history.add({'role': 'assistant', 'content': reply});
        }
      }
      history.add({'role': 'user', 'content': text});

      // The AI endpoint checks this token so only signed-in users can use it.
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await httpai.post(
        Uri.parse('https://callai-docslpktsq-uc.a.run.app'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'messages': history, 'temperature': 0.7}),
      );

      if (response.statusCode != 200) {
        await docRef.update({'aiResponse': 'API Error ${response.statusCode}'});
        return;
      }

      final data = jsonDecode(response.body);
      final aiText = data['choices'][0]['message']['content'].toString().trim();
      await docRef.update({'aiResponse': aiText});
    } catch (e) {
      if (docRef != null) {
        await docRef.update({'aiResponse': 'Error: $e'});
      }
    }
  }

  Future<void> _deleteChat(String chatId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteChatTitle),
        content: Text(context.l10n.deleteChatBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final docs = await _fetchChat(chatId);
      for (var i = 0; i < docs.length; i += 450) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in docs.skip(i).take(450)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      if (!mounted) return;
      if (chatId == _chatId) setState(() => _chatId = _newChatId());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.chatDeleted)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.chatDeleteFailed)),
      );
    }
  }

  void _openChat(String chatId) => setState(() => _chatId = chatId);

  void _showHistorySheet(Map<String, List<_Msg>> chats) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
          ),
          child: _ChatList(
            chats: chats,
            selected: _chatId,
            onNew: () {
              Navigator.pop(sheetContext);
              _openChat(_newChatId());
            },
            onOpen: (id) {
              Navigator.pop(sheetContext);
              _openChat(id);
            },
            onDelete: (id) {
              Navigator.pop(sheetContext);
              _deleteChat(id);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ContentWidth(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return LoadError(
              message: context.l10n.loadMessagesFailed,
              onRetry: () => setState(_connect),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = _groupChats(snapshot.data!.docs);
          final messages = chats[_chatId] ?? const <_Msg>[];

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;

              final conversation = Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(
                        bottom: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (!wide)
                          IconButton(
                            tooltip: context.l10n.chatHistory,
                            icon: const Icon(Icons.history_rounded),
                            onPressed: () => _showHistorySheet(chats),
                          )
                        else
                          const SizedBox(width: 8),
                        const Icon(Icons.auto_awesome, color: brandBlueDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            messages.isEmpty
                                ? context.l10n.navAskAi
                                : _chatTitle(messages),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (messages.isNotEmpty)
                          IconButton(
                            tooltip: context.l10n.deleteThisChat,
                            icon:
                                Icon(Icons.delete_outline, color: colors.error),
                            onPressed: () => _deleteChat(_chatId),
                          ),
                        IconButton(
                          tooltip: context.l10n.newChat,
                          icon: const Icon(Icons.add_comment_outlined),
                          onPressed: messages.isEmpty
                              ? null
                              : () => _openChat(_newChatId()),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: messages.isEmpty
                        ? _AiEmptyState(onPick: _send)
                        : ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: messages.length,
                            itemBuilder: (context, index) =>
                                _MessagePair(doc: messages[index]),
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border:
                          Border(top: BorderSide(color: colors.outlineVariant)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _input,
                              keyboardType: TextInputType.multiline,
                              minLines: 1,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: context.l10n.askSomething,
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            color: brandBlue,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            tooltip: context.l10n.send,
                            icon: const Icon(Icons.send, color: brandInk),
                            onPressed: () => _send(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (!wide) return conversation;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 260,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: colors.outlineVariant),
                        ),
                      ),
                      child: _ChatList(
                        chats: chats,
                        selected: _chatId,
                        onNew: () => _openChat(_newChatId()),
                        onOpen: _openChat,
                        onDelete: _deleteChat,
                      ),
                    ),
                  ),
                  Expanded(child: conversation),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({
    required this.chats,
    required this.selected,
    required this.onNew,
    required this.onOpen,
    required this.onDelete,
  });

  final Map<String, List<_Msg>> chats;
  final String selected;
  final VoidCallback onNew;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: OutlinedButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add_rounded),
            label: Text(context.l10n.newChat),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            context.l10n.recentChats,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
        ),
        Flexible(
          child: chats.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    context.l10n.chatsEmpty,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    for (final entry in chats.entries)
                      ListTile(
                        dense: true,
                        selected: entry.key == selected,
                        selectedTileColor: brandBlue.withValues(alpha: 0.18),
                        selectedColor: colors.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                            const EdgeInsets.only(left: 16, right: 4),
                        title: Text(
                          _chatTitle(entry.value),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onOpen(entry.key),
                        trailing: IconButton(
                          tooltip: context.l10n.deleteChat,
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => onDelete(entry.key),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MessagePair extends StatelessWidget {
  const _MessagePair({required this.doc});

  final _Msg doc;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = (doc['text'] ?? '').toString();
    final aiResponse = doc['aiResponse']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: brandBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(text, style: const TextStyle(color: brandInk)),
          ),
        ),
        if (aiResponse.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(context.l10n.thinking),
                ],
              ),
            ),
          )
        else if (_isErrorReply(aiResponse))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              context.l10n.noAnswer,
              style: TextStyle(color: colors.error),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: _AiReply(key: ValueKey(doc.id), text: aiResponse),
          ),
      ],
    );
  }
}

class _AiEmptyState extends StatelessWidget {
  const _AiEmptyState({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Asked in the app's language, so the AI answers in it too.
    final questions = [
      context.l10n.starterSummer,
      context.l10n.starterScholarships,
      context.l10n.starterSat,
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 36, color: brandBlueDark),
              const SizedBox(height: 10),
              Text(
                context.l10n.aiEmptyTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.aiEmptyBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              for (final question in questions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => onPick(question),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(question),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiReply extends StatelessWidget {
  const _AiReply({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth <= 480;
        final bodyStyle = TextStyle(
          color: colors.onSurface,
          fontSize: compact ? 13 : 14,
          height: compact ? 1.35 : 1.5,
          letterSpacing: compact ? 0 : null,
        );

        TextStyle heading(double size) => TextStyle(
              color: colors.onSurface,
              fontSize: size,
              fontWeight: FontWeight.bold,
            );

        return MarkdownBody(
          data: text,
          styleSheet: MarkdownStyleSheet(
            p: bodyStyle,
            h1: heading(compact ? 18 : 22),
            h2: heading(compact ? 16 : 19),
            h3: heading(compact ? 14 : 16),
            listBullet: bodyStyle,
            code: TextStyle(
              color: colors.onSurface,
              backgroundColor: colors.surfaceContainerHighest,
              fontSize: compact ? 12 : 13,
            ),
            codeblockDecoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            // Fixed widths make flutter_markdown scroll wide tables sideways
            // instead of squeezing every column to a few characters.
            tableColumnWidth: const FixedColumnWidth(170),
            tableHead: bodyStyle.copyWith(fontWeight: FontWeight.bold),
            tableBody: bodyStyle,
            tableCellsPadding: const EdgeInsets.all(8),
          ),
        );
      },
    );
  }
}
