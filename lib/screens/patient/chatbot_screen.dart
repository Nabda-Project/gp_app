import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../widgets/animations/animated_list_item.dart';
import '../../widgets/animations/scale_on_tap.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  late List<Message>
  _messages; // Make late to initialize in initState with context

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize messages here to access context for localization
    _messages = [
      Message(
        text: AppLocalizations.of(context)!.get('welcomeMessage'),
        isUser: false,
      ),
    ];
  }

  bool _showEmergencyBanner = false;

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add(Message(text: _controller.text, isUser: true));

      // Simple logic to trigger emergency banner for demo purposes
      if (_controller.text.toLowerCase().contains("chest pain") ||
          _controller.text.toLowerCase().contains("shortness of breath")) {
        _showEmergencyBanner = true;
        _messages.add(
          Message(
            text: AppLocalizations.of(context)!.get('emergencyResponse'),
            isUser: false,
          ),
        );
      } else {
        _messages.add(
          Message(
            text: AppLocalizations.of(context)!.get('generalResponse'),
            isUser: false,
          ),
        );
      }

      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.get('assistantTitle'),
          style: const TextStyle(color: AppColors.darkBlue),
        ),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      body: DecoratedBackground(
        child: Column(
          children: [
            if (_showEmergencyBanner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingL,
                  vertical: 12,
                ),
                color: AppColors.error,
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: AppDimensions.paddingM),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.get('urgentWarning'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return AnimatedListItem(
                    index: index,
                    staggerDelay: const Duration(milliseconds: 50),
                    beginOffset:
                        msg.isUser
                            ? const Offset(0.2, 0)
                            : const Offset(-0.2, 0),
                    child: Align(
                      alignment:
                          msg.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color:
                              msg.isUser
                                  ? AppColors.primaryBlue
                                  : AppColors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft:
                                msg.isUser
                                    ? const Radius.circular(16)
                                    : Radius.zero,
                            bottomRight:
                                msg.isUser
                                    ? Radius.zero
                                    : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color:
                                msg.isUser ? Colors.white : AppColors.darkBlue,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              color: AppColors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        )!.get('typeMessage'),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingS),
                  ScaleOnTap(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}
