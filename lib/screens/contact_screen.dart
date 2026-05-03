import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';
import '../services/auth_service.dart';
import '../services/contact_service.dart';
import 'message_history_screen.dart';
import 'login_screen.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactService = ContactService();
  
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _selectedPriority = 'NORMAL';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitAuthenticatedMessage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await _contactService.sendUserMessage(
        token: authService.accessToken ?? '',
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        priority: _selectedPriority,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message sent successfully!'),
            backgroundColor: AppColors.primary500,
          ),
        );
        
        // Clear form
        _formKey.currentState!.reset();
        _subjectController.clear();
        _messageController.clear();
        setState(() {
          _selectedPriority = 'NORMAL';
        });
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
          _isSubmitting = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.gray900,
            elevation: 0,
            title: Text(
              'contact_title'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (authService.isAuthenticated)
                IconButton(
                  icon: Icon(Icons.history, color: AppColors.primary400),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MessageHistoryScreen(),
                      ),
                    );
                  },
                  tooltip: 'contact_history'.tr(),
                ),
            ],
          ),
          body: GradientBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with auth status
                    if (authService.isAuthenticated) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary500.withOpacity(0.2),
                              AppColors.primary500.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary500.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: AppColors.primary400,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${'contact_logged_in_as'.tr()} ${authService.user?['email']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'contact_messages_saved'.tr(),
                                    style: TextStyle(
                                      color: AppColors.gray300,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Contact info cards
                    _buildContactInfoCard(
                      Icons.email,
                      'contact_email'.tr(),
                      'contact_email_value'.tr(),
                    ),
                    const SizedBox(height: 16),
                    _buildContactInfoCard(
                      Icons.access_time,
                      'contact_response_time'.tr(),
                      'contact_response_value'.tr(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Message form
                    Container(
                      padding: EdgeInsets.all(isTablet ? 32 : 24),
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
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authService.isAuthenticated 
                                  ? 'contact_send_message'.tr()
                                  : 'contact_login_required'.tr(),
                              style: TextStyle(
                                fontSize: isTablet ? 24 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!authService.isAuthenticated)
                              Text(
                                'contact_login_prompt'.tr(),
                                style: TextStyle(
                                  color: AppColors.gray400,
                                  fontSize: isTablet ? 16 : 14,
                                ),
                              ),
                            const SizedBox(height: 24),
                            
                            if (authService.isAuthenticated) ...[
                              // Subject field
                              TextFormField(
                                controller: _subjectController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'contact_subject'.tr(),
                                  labelStyle: TextStyle(color: AppColors.gray400),
                                  prefixIcon: Icon(Icons.subject, color: AppColors.primary400),
                                  filled: true,
                                  fillColor: AppColors.gray800,
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
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'error_subject_required'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Priority dropdown
                              DropdownButtonFormField<String>(
                                value: _selectedPriority,
                                style: const TextStyle(color: Colors.white),
                                dropdownColor: AppColors.gray800,
                                decoration: InputDecoration(
                                  labelText: 'contact_priority'.tr(),
                                  labelStyle: TextStyle(color: AppColors.gray400),
                                  prefixIcon: Icon(Icons.flag, color: AppColors.primary400),
                                  filled: true,
                                  fillColor: AppColors.gray800,
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
                                items: [
                                  DropdownMenuItem(
                                    value: 'LOW',
                                    child: Text('priority_low'.tr()),
                                  ),
                                  DropdownMenuItem(
                                    value: 'NORMAL',
                                    child: Text('priority_normal'.tr()),
                                  ),
                                  DropdownMenuItem(
                                    value: 'HIGH',
                                    child: Text('priority_high'.tr()),
                                  ),
                                  DropdownMenuItem(
                                    value: 'URGENT',
                                    child: Text('priority_urgent'.tr()),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPriority = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Message field
                              TextFormField(
                                controller: _messageController,
                                maxLines: 6,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'contact_message'.tr(),
                                  labelStyle: TextStyle(color: AppColors.gray400),
                                  alignLabelWithHint: true,
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(bottom: 120),
                                    child: Icon(Icons.message, color: AppColors.primary400),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.gray800,
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
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'error_message_required'.tr();
                                  }
                                  if (value.trim().length < 10) {
                                    return 'error_message_short'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              
                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitAuthenticatedMessage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary500,
                                    disabledBackgroundColor: AppColors.gray700,
                                    padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'contact_send_button'.tr(),
                                          style: TextStyle(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ] else ...[
                              // Login prompt for guests
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.gray700.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.gray600),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      size: 48,
                                      color: AppColors.gray500,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'contact_auth_required_title'.tr(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'contact_auth_required_desc'.tr(),
                                      style: TextStyle(
                                        color: AppColors.gray300,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const LoginScreen(),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary500,
                                          padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        icon: const Icon(Icons.login),
                                        label: Text(
                                          'contact_login_button'.tr(),
                                          style: TextStyle(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactInfoCard(IconData icon, String title, String content) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
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
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: AppColors.primary500.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary400,
              size: isTablet ? 32 : 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: AppColors.gray400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
