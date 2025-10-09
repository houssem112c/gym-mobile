import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';
import '../widgets/conversation_dialog.dart';
import '../services/auth_service.dart';
import '../services/contact_service.dart';
import '../models/contact.dart';

class MessageHistoryScreen extends StatefulWidget {
  const MessageHistoryScreen({super.key});

  @override
  State<MessageHistoryScreen> createState() => _MessageHistoryScreenState();
}

class _MessageHistoryScreenState extends State<MessageHistoryScreen> {
  List<ContactMessage> _messages = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isAuthenticated) {
        throw Exception('Please log in to view your messages');
      }

      // Import and use ContactService
      final contactService = ContactService();
      final messages = await contactService.getUserMessages(authService.accessToken ?? '');
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.gray900,
        elevation: 0,
        title: Text(
          'My Messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary400),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? _buildErrorState()
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(isTablet),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.red500,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load messages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              style: TextStyle(
                color: AppColors.gray400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadMessages,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.gray600,
            ),
            const SizedBox(height: 16),
            Text(
              'No Messages Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t sent any messages to the admin yet. Use the contact form to get in touch!',
              style: TextStyle(
                color: AppColors.gray400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Send Message'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(bool isTablet) {
    return ListView.builder(
      padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageCard(message, isTablet);
      },
    );
  }

  Widget _buildMessageCard(ContactMessage message, bool isTablet) {
    return GestureDetector(
      onTap: () => _showConversationDialog(message),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gray800,
              AppColors.gray900,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray700),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary500.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message header
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: AppColors.gray800.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.subject,
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sent ${_formatDate(message.createdAt)}',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(message.status),
                ],
              ),
            ),
            
            // Original message
            Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Message:',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: AppColors.gray300,
                      height: 1.4,
                    ),
                  ),
                  
                  // Admin response
                  if (message.adminResponse != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary500.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 16,
                                color: AppColors.primary400,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Admin Response',
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary400,
                                ),
                              ),
                              const Spacer(),
                              if (message.respondedAt != null)
                                Text(
                                  _formatDate(message.respondedAt!),
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 10,
                                    color: AppColors.gray500,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            message.adminResponse!,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConversationDialog(ContactMessage message) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ConversationDialog(message: message),
    );
    
    // If message was sent (result == true), refresh the messages list
    if (result == true) {
      _loadMessages();
    }
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'open':
        backgroundColor = AppColors.blue400.withOpacity(0.2);
        textColor = AppColors.blue400;
        displayText = 'Open';
        break;
      case 'in_progress':
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        displayText = 'In Progress';
        break;
      case 'responded':
        backgroundColor = AppColors.primary500.withOpacity(0.2);
        textColor = AppColors.primary400;
        displayText = 'Responded';
        break;
      case 'closed':
        backgroundColor = AppColors.gray600.withOpacity(0.2);
        textColor = AppColors.gray400;
        displayText = 'Closed';
        break;
      default:
        backgroundColor = AppColors.gray600.withOpacity(0.2);
        textColor = AppColors.gray400;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}