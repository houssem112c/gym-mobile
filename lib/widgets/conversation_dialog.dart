import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../models/contact.dart';
import '../services/auth_service.dart';
import '../services/contact_service.dart';

class ConversationDialog extends StatefulWidget {
  final ContactMessage message;

  const ConversationDialog({
    super.key,
    required this.message,
  });

  @override
  State<ConversationDialog> createState() => _ConversationDialogState();
}

class _ConversationDialogState extends State<ConversationDialog> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _contactService = ContactService();
  bool _isSending = false;
  String _selectedPriority = 'NORMAL';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }



  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await _contactService.sendUserMessage(
        token: authService.accessToken ?? '',
        subject: 'Re: ${widget.message.subject}',
        message: _messageController.text.trim(),
        priority: _selectedPriority,
      );

      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message sent successfully!'),
            backgroundColor: AppColors.primary500,
          ),
        );
        
        // Close dialog and refresh parent
        Navigator.of(context).pop(true); // Return true to indicate message was sent
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final dialogWidth = isTablet ? size.width * 0.7 : size.width * 0.95;
    final dialogHeight = size.height * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gray900,
              AppColors.gray800,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gray700),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                color: AppColors.gray800.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.gray700),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.message.subject,
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Conversation Thread',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: AppColors.gray400,
                      size: isTablet ? 28 : 24,
                    ),
                  ),
                ],
              ),
            ),

            // Messages list
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: Column(
                  children: [
                    // Original message from user
                    _buildMessageBubble(
                      message: widget.message.message,
                      isFromUser: true,
                      timestamp: widget.message.createdAt,
                      isTablet: isTablet,
                    ),
                    
                    // Admin response (if exists)
                    if (widget.message.hasResponse) ...[
                      const SizedBox(height: 16),
                      _buildMessageBubble(
                        message: widget.message.adminResponse!,
                        isFromUser: false,
                        timestamp: widget.message.respondedAt!,
                        isTablet: isTablet,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Message input section
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: AppColors.gray800.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(color: AppColors.gray700),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority selector
                  Row(
                    children: [
                      Text(
                        'Priority:',
                        style: TextStyle(
                          color: AppColors.gray400,
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _selectedPriority,
                        style: TextStyle(color: Colors.white, fontSize: isTablet ? 14 : 12),
                        dropdownColor: AppColors.gray800,
                        underline: Container(),
                        items: [
                          DropdownMenuItem(
                            value: 'LOW',
                            child: Text('Low'),
                          ),
                          DropdownMenuItem(
                            value: 'NORMAL',
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem(
                            value: 'HIGH',
                            child: Text('High'),
                          ),
                          DropdownMenuItem(
                            value: 'URGENT',
                            child: Text('Urgent'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPriority = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Message input
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: AppColors.gray500),
                      filled: true,
                      fillColor: AppColors.gray900,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.gray700),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.gray700),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary500, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Send button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        disabledBackgroundColor: AppColors.gray700,
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 20,
                          vertical: isTablet ? 16 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSending
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.send, size: isTablet ? 20 : 18),
                      label: Text(
                        _isSending ? 'Sending...' : 'Send Message',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildMessageBubble({
    required String message,
    required bool isFromUser,
    required DateTime timestamp,
    required bool isTablet,
  }) {
    return Row(
      mainAxisAlignment: isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFromUser) ...[
          CircleAvatar(
            radius: isTablet ? 20 : 16,
            backgroundColor: AppColors.primary500,
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: isTablet ? 20 : 16,
            ),
          ),
          const SizedBox(width: 12),
        ],
        
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: isFromUser 
                  ? AppColors.primary500.withOpacity(0.2)
                  : AppColors.gray700.withOpacity(0.5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isTablet ? 16 : 12),
                topRight: Radius.circular(isTablet ? 16 : 12),
                bottomLeft: Radius.circular(isFromUser ? (isTablet ? 16 : 12) : 4),
                bottomRight: Radius.circular(isFromUser ? 4 : (isTablet ? 16 : 12)),
              ),
              border: Border.all(
                color: isFromUser 
                    ? AppColors.primary500.withOpacity(0.3)
                    : AppColors.gray600,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isFromUser ? 'You' : 'Admin',
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 10,
                        fontWeight: FontWeight.bold,
                        color: isFromUser ? AppColors.primary400 : AppColors.gray300,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: isTablet ? 10 : 8,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        if (isFromUser) ...[
          const SizedBox(width: 12),
          CircleAvatar(
            radius: isTablet ? 20 : 16,
            backgroundColor: AppColors.primary500,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: isTablet ? 20 : 16,
            ),
          ),
        ],
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'Just now';
        }
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}