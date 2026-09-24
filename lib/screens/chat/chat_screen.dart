import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/core/backend_service_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  /// Longest message the input accepts.
  static const int maxMessageLength = 2000;

  static const List<String> suggestedQuestions = [
    'What foods should I avoid with my condition?',
    'How have I been feeling lately?',
    'How can I manage pain during a flare-up?',
    'What supplements are recommended for gut health?',
    'Can stress trigger digestive symptoms?',
  ];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  bool _isLoadingHistory = true;
  bool _isSending = false;
  bool _hasText = false;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  bool get _canSend => _hasText && !_isSending;

  Future<void> _loadChatHistory() async {
    setState(() => _isLoadingHistory = true);

    try {
      final backend = BackendServiceProvider.instance;
      final userId = backend.auth.currentUser?.id ?? '';
      final history = await backend.chat.getChatHistory(userId);

      if (!mounted) return;
      setState(() {
        _messages = history;
        _isLoadingHistory = false;
      });
      _scrollToBottom(animate: false);
    } catch (e) {
      debugPrint('ChatScreen: failed to load chat history: $e');
      if (!mounted) return;
      setState(() => _isLoadingHistory = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load your conversation. Tap reload to try again."),
        ),
      );
    }
  }

  Future<void> _sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isSending) return;

    final message = <String, dynamic>{
      'text': text,
      'isUser': true,
      'timestamp': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages = [..._messages, message];
      _messageController.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final backend = BackendServiceProvider.instance;
      final userId = backend.auth.currentUser?.id ?? '';
      final response = await backend.chat.sendMessage(userId, text);

      if (!mounted) return;
      setState(() {
        _messages = [
          ..._messages,
          {
            'text': response,
            'isUser': false,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ];
        _isSending = false;
      });
      _scrollToBottom();
      SemanticsService.sendAnnouncement(
        View.of(context),
        'GutMD Assistant: $response',
        TextDirection.ltr,
      );
    } catch (e) {
      debugPrint('ChatScreen: failed to send message: $e');
      if (!mounted) return;
      setState(() {
        _messages = _messages.where((m) => !identical(m, message)).toList();
        _isSending = false;
        if (_messageController.text.isEmpty) {
          _messageController.text = text;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message not sent. Check your connection and try again.'),
        ),
      );
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: _buildBody(),
              ),
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 16, 20),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat Assistant',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ask questions about your gut health',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Reload conversation',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isSending || _isLoadingHistory ? null : _loadChatHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingHistory && _messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading conversation'),
      );
    }
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _messages.length) {
          return _buildTypingIndicator();
        }
        final message = _messages[index];
        return _buildMessage(
          text: message['text']?.toString() ?? '',
          isUser: message['isUser'] == true,
        );
      },
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isUser ? AppTheme.secondaryColor : AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person_outline : Icons.smart_toy_outlined,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMessage({required String text, required bool isUser}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(isUser: false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppTheme.primaryColor : AppTheme.deepPurple,
                  borderRadius: BorderRadius.circular(16),
                  border: isUser
                      ? null
                      : Border.all(color: AppTheme.lightIndigo.withValues(alpha: 0.35)),
                ),
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(isUser: true),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(isUser: false),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.deepPurple,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.lightIndigo.withValues(alpha: 0.35)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: ExcludeSemantics(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.lightIndigo,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'GutMD Assistant is typing…',
                      style: TextStyle(color: AppTheme.lightTextColor, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 56,
            color: AppTheme.lightTextColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start a conversation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Ask about your symptoms, food triggers, supplements or how you've been feeling. "
            'Answers take into account what you track in GutMD.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.lightTextColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Suggested Questions',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: suggestedQuestions.map(_buildSuggestion).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestion(String question) {
    return Material(
      color: AppTheme.deepPurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.lightIndigo.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _isSending ? null : () => _sendMessage(question),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            question,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.darkNavy,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _inputFocus,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(maxMessageLength),
                      ],
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: AppTheme.lightTextColor.withValues(alpha: 0.7)),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(Radius.circular(24)),
                          borderSide: BorderSide(color: AppTheme.lightIndigo.withValues(alpha: 0.4)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                          borderSide: BorderSide(color: AppTheme.lightIndigo, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      // Send on Enter from onEditingComplete rather than onSubmitted:
                      // with onSubmitted set, EditableText restarts the text input
                      // connection after a submit, which on web (semantics on)
                      // leaves the field ignoring typing. A non-null
                      // onEditingComplete also keeps focus for the next message.
                      onEditingComplete: () => _sendMessage(_messageController.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _canSend ? AppTheme.accentIndigo : AppTheme.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      tooltip: 'Send message',
                      icon: const Icon(Icons.send),
                      color: Colors.white,
                      disabledColor: Colors.white.withValues(alpha: 0.45),
                      onPressed: _canSend ? () => _sendMessage(_messageController.text) : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'General information only, not medical advice. '
                'For urgent or worsening symptoms, contact your doctor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.lightTextColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
