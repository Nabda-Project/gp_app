import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';
import '../../services/notification_api_service.dart';
import '../../services/presence_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';

/// Doctor → Patient live chat screen.
/// Uses [ChatService] for real-time STOMP messaging and REST-loaded history.
/// Polls patient presence every 15 s to show online/offline/last-seen status.
class PatientChatScreen extends StatefulWidget {
  const PatientChatScreen({super.key});

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];

  late int _myId;
  late int _patientId;
  late String _patientName;
  ChatService? _chatService;
  StreamSubscription<ChatMessageModel>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;
  bool _isLoading = true;

  // Presence state
  bool _isOnline = false;
  DateTime? _lastSeen;
  Timer? _presenceTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only init once
    if (_chatService == null) {
      _extractArgsAndInit();
    }
  }

  Future<void> _extractArgsAndInit() async {
    // Get patient data from route arguments
    final patient =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    _patientName = (patient['name'] as String?)?.trim() ?? '';
    if (_patientName.isEmpty) {
      _patientName = (patient['email'] as String?)?.trim() ?? 'Patient';
    }

    // backendId can come as int or String depending on the navigation source
    final rawId = patient['backendId'];
    if (rawId is int) {
      _patientId = rawId;
    } else if (rawId is String) {
      _patientId = int.tryParse(rawId) ?? 0;
    } else {
      _patientId = 0;
    }

    debugPrint('PatientChatScreen: patientName=$_patientName, patientId=$_patientId');

    final user = StorageService.getUser();
    debugPrint('PatientChatScreen: currentUser=${user?.fullName}, backendId=${user?.backendId}');

    if (user == null || user.backendId == null || _patientId == 0) {
      debugPrint('PatientChatScreen: Cannot init chat — user or patientId missing');
      setState(() => _isLoading = false);
      return;
    }

    _myId = user.backendId!;

    // Use the global singleton — do NOT create a new instance
    _chatService = ChatService.instance;

    // If not initialized yet (edge case), initialize now
    if (_chatService == null) {
      await ChatService.initialize(_myId);
      _chatService = ChatService.instance;
    }

    if (_chatService == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Show the chat UI immediately (empty state) while history loads
    if (mounted) setState(() => _isLoading = false);

    // Load history in background and update UI when ready
    debugPrint('PatientChatScreen: Loading history between $_myId and $_patientId...');
    _chatService!.fetchHistory(_patientId).then((history) {
      debugPrint('PatientChatScreen: Loaded ${history.length} messages');
      if (mounted) {
        setState(() => _messages.addAll(history));
        _scrollToBottom();
      }
    });

    // Fire-and-forget — don't block UI
    _chatService!.markAsRead(_patientId);
    NotificationApiService.deleteChatNotifications(_myId, _patientId);
    _fetchPresence();

    // Poll presence every 15 seconds
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchPresence(),
    );

    // Listen for real-time messages (singleton is already connected)
    _messageSubscription = _chatService!.messages.listen((msg) {
      if ((msg.senderId == _patientId && msg.receiverId == _myId) ||
          (msg.senderId == _myId && msg.receiverId == _patientId)) {
        // Skip echo of own messages — already added optimistically
        if (msg.senderId == _myId) return;

        // Dedup incoming messages from the other party
        final isDuplicate = _messages.any((m) =>
            m.content == msg.content &&
            m.senderId == msg.senderId &&
            m.timestamp != null &&
            msg.timestamp != null &&
            m.timestamp!.difference(msg.timestamp!).inSeconds.abs() < 5);
        if (!isDuplicate && mounted) {
          setState(() => _messages.add(msg));
          _scrollToBottom();
          // Message received while chat is open -> read immediately
          _chatService!.markAsRead(_patientId);
        }
      }
    });

    _statusSubscription = _chatService!.statuses.listen((statusUpdate) {
      final type = statusUpdate['type'];
      final status = statusUpdate['status'];
      final receiverId = statusUpdate['receiverId'];

      if (type == 'status' && receiverId == _patientId) {
        if (mounted) {
          setState(() {
            for (var msg in _messages) {
              if (msg.senderId == _myId) {
                if (status == 'read') {
                  msg.isRead = true;
                  msg.isDelivered = true;
                } else if (status == 'delivered') {
                  msg.isDelivered = true;
                }
              }
            }
          });
        }
      }
    });
  }

  Future<void> _fetchPresence() async {
    if (_patientId == 0) return;
    final presence = await PresenceService.fetchPresence(_patientId);
    if (mounted) {
      setState(() {
        _isOnline = presence.online;
        _lastSeen = presence.lastSeen;
      });
    }
  }

  String _statusText() {
    if (_isOnline) return 'Online';
    if (_lastSeen == null) return 'Offline';
    final diff = DateTime.now().difference(_lastSeen!);
    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    return 'Last seen ${DateFormat('MMM d').format(_lastSeen!)}';
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatService == null) return;

    // Optimistic: add message to local list immediately
    final optimisticMsg = ChatMessageModel(
      senderId: _myId,
      receiverId: _patientId,
      content: text,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(optimisticMsg));
    _scrollToBottom();

    _chatService!.sendMessage(receiverId: _patientId, content: text);
    _messageController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Returns a human-readable date label for message grouping.
  String _dateLabelFor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);

    if (msgDay == today) return 'Today';
    if (msgDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // e.g. "Monday"
    }
    return DateFormat('MMM d, yyyy').format(date); // e.g. "Apr 3, 2026"
  }

  /// Whether we should show a date separator before message at [index].
  bool _showDateSeparator(int index) {
    if (_messages[index].timestamp == null) return false;
    if (index == 0) return true;
    final prev = _messages[index - 1].timestamp;
    final curr = _messages[index].timestamp!;
    if (prev == null) return true;
    return DateTime(prev.year, prev.month, prev.day) !=
        DateTime(curr.year, curr.month, curr.day);
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    // Do NOT dispose the global ChatService singleton — it must stay alive
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                    child: Text(
                      _isLoading
                          ? '…'
                          : _patientName.isNotEmpty
                              ? _patientName[0].toUpperCase()
                              : 'P',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _isOnline ? AppColors.accentTeal : AppColors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLoading ? '…' : _patientName,
                    style: const TextStyle(
                      color: AppColors.darkBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusText(),
                    style: TextStyle(
                      color: _isOnline ? AppColors.accentTeal : AppColors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Color
          Container(color: const Color(0xFFF4F7FA)),
          
          // Decorative background shapes
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentTeal.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.5,
            left: 20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.02),
              ),
            ),
          ),

          // Main Chat Content
          Column(
            children: [
              // Add spacing for the extended app bar
              SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top),
              // Messages List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryBlue))
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.mark_chat_unread_rounded,
                                      size: 64,
                                      color: AppColors.primaryBlue.withValues(alpha: 0.5)),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  AppLocalizations.of(context)?.get('noMessages') ??
                                      'No messages yet',
                                  style: const TextStyle(
                                    color: AppColors.darkBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Send a message to start the conversation!',
                                  style: TextStyle(
                                    color: AppColors.grey.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding:
                                const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMe = msg.isSentBy(_myId);
                              return Column(
                                children: [
                                  if (_showDateSeparator(index))
                                    _buildDateSeparator(
                                      _dateLabelFor(msg.timestamp!),
                                    ),
                                  _buildMessageBubble(msg, isMe),
                                ],
                              );
                            },
                          ),
              ),

              // Floating Message Input
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            border: Border.all(
                              color: AppColors.lightGrey.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16), // Padding instead of emoji icon
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendMessage(),
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)
                                            ?.get('typePatientMessage') ??
                                        'Type a message…',
                                    hintStyle: TextStyle(
                                        color: AppColors.grey.withValues(alpha: 0.6),
                                        fontSize: 15),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: _sendMessage,
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  /// Date separator widget shown between messages from different days.
  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.grey.withValues(alpha: 0.25),
              thickness: 0.8,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColors.grey.withValues(alpha: 0.25),
              thickness: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    final timeStr = msg.timestamp != null
        ? DateFormat('h:mm a').format(msg.timestamp!)
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: Text(
                _patientName.isNotEmpty ? _patientName[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: isMe ? AppColors.primaryGradient : null,
                color: isMe ? null : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? AppColors.primaryBlue : Colors.black)
                        .withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: !isMe
                    ? Border.all(
                        color: AppColors.grey.withValues(alpha: 0.1),
                        width: 1,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.darkBlue,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  if (timeStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppColors.grey.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          if (msg.isRead)
                            Icon(Icons.remove_red_eye_rounded,
                                size: 14,
                                color: Colors.white)
                          else if (msg.isDelivered)
                            Icon(Icons.done_all_rounded,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.9))
                          else
                            Icon(Icons.check_rounded,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.7)),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
