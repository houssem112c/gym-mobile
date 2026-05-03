import 'dart:convert';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'avatar_creator_screen.dart';
import '../models/user.dart';
import 'package:easy_localization/easy_localization.dart';
import 'insights_screen.dart';
import 'progress_photos_screen.dart';
import 'measurements_screen.dart';
import 'personal_records_screen.dart';
import 'training_settings_screen.dart';
import 'gamification_screen.dart';
import '../providers/gamification_provider.dart';
import '../widgets/premium_card.dart';
import '../widgets/premium_input.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_section_header.dart';
import '../widgets/animated_gradient_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _imagePicker = ImagePicker();
  
  // Controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _dobController = TextEditingController();

  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isSaving3dAvatar = false;
  bool _isLoading3dAvatar = false;
  String _error = '';
  User? _user;
  Map<String, dynamic>? _avatar2dConfig;
  File? _selectedImage;
  XFile? _selectedImageFile;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isAuthenticated || authService.accessToken == null) {
        throw Exception('error_login_required'.tr());
      }

      final profile = await _profileService.getProfile(authService.accessToken!);
      setState(() {
        _user = profile;
        _nameController.text = profile.name;
        _bioController.text = profile.bio ?? '';
        _phoneController.text = profile.phone ?? '';
        _addressController.text = profile.address ?? '';
        _cityController.text = profile.city ?? '';
        _countryController.text = profile.country ?? '';
        _selectedDate = profile.dateOfBirth;
        if (_selectedDate != null) {
          _dobController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
        }
      });

      await _loadMy2dAvatar(authService.accessToken!);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMy2dAvatar(String token) async {
    setState(() {
      _isLoading3dAvatar = true;
    });

    try {
      final data = await _profileService.getMy2dAvatar(token: token);
      
      setState(() {
        _avatar2dConfig = data;
      });
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Avatar not found') || msg.contains('404')) {
        setState(() {
          _avatar2dConfig = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading3dAvatar = false;
        });
      }
    }
  }

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      // Store XFile for web, convert to File for mobile
      if (kIsWeb) {
        setState(() {
          _selectedImageFile = image;
          _selectedImage = null;
        });
        return;
      } else {
        setState(() {
          _selectedImage = File(image.path);
          _selectedImageFile = null;
        });
      }

      // Only crop on mobile platforms
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Image',
            toolbarColor: AppColors.primary500,
            toolbarWidgetColor: Colors.white,
            backgroundColor: AppColors.gray900,
            activeControlsWidgetColor: AppColors.primary500,
          ),
          IOSUiSettings(
            title: 'Crop Profile Image',
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImage = File(croppedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary500,
              surface: AppColors.gray800,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUpdating = true;
      _error = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isAuthenticated || authService.accessToken == null || _user == null) {
        throw Exception('error_login_required'.tr());
      }

      File? imageFile;
      Uint8List? webImageBytes;
      String? webImageFileName;

      if (kIsWeb) {
        if (_selectedImageFile != null) {
          webImageBytes = await _selectedImageFile!.readAsBytes();
          webImageFileName = _selectedImageFile!.name;
        }
        imageFile = null;
      } else {
        imageFile = _selectedImage;
        webImageBytes = null;
        webImageFileName = null;
      }

      final updatedUser = await _profileService.updateProfileWithImage(
        token: authService.accessToken!,
        userId: _user!.id,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        dateOfBirth: _selectedDate,
        imageFile: imageFile,
        imageBytes: webImageBytes,
        imageFileName: webImageFileName,
      );

      setState(() {
        _user = updatedUser;
        _selectedImage = null;
        _selectedImageFile = null;
      });

      final currentUser = authService.user;
      if (currentUser != null) {
        authService.updateUserInfo({
          ...currentUser,
          'name': updatedUser.name,
          'avatar': updatedUser.avatar,
          'bio': updatedUser.bio,
          'phone': updatedUser.phone,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile_updated'.tr()),
          backgroundColor: AppColors.primary500,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });

      if (!mounted) return;
      String errorMessage = 'Failed to update profile: $e';
      Color errorColor = AppColors.red500;

      if (e.toString().contains('Supabase not configured')) {
        errorMessage = 'Image upload requires Supabase setup. Check SUPABASE_SETUP.md for instructions.';
        errorColor = AppColors.orange500;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _open2dAvatarCreator() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isAuthenticated || authService.accessToken == null || _user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_login_required'.tr()),
          backgroundColor: AppColors.red500,
        ),
      );
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AvatarCreatorScreen(initialConfig: _avatar2dConfig),
      ),
    );

    if (result == null) return;

    setState(() => _isSaving3dAvatar = true);
    try {
      await _profileService.save2dAvatar(
        token: authService.accessToken!,
        config: result,
      );

      await _loadProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('2D avatar saved successfully'),
          backgroundColor: AppColors.primary500,
        ),
      );
    } catch (e) {
      String errorMessage = e.toString();
      if (e is String) errorMessage = e;
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save 2D avatar: $errorMessage'),
          backgroundColor: AppColors.red500,
          duration: const Duration(seconds: 5),
        ),
      );
    }
 finally {
      if (mounted) setState(() => _isSaving3dAvatar = false);
    }
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (mounted) {
      // AuthWrapper will handle the redirection
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.surface950,
      body: AnimatedGradientBackground(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(size),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 32 : 16,
                      24,
                      isTablet ? 32 : 16,
                      MediaQuery.of(context).padding.bottom + 100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildProfileHeroCard(),
                        const SizedBox(height: 24),
                        
                        PremiumSectionHeader(
                          title: 'gamification_title'.tr(),
                          action: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GamificationScreen()),
                            ),
                            child: const Text('View All', style: TextStyle(color: AppColors.primary500)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildGamificationTile(),
                        const SizedBox(height: 32),

                        PremiumSectionHeader(title: 'profile_progress_tracking'.tr()),
                        const SizedBox(height: 12),
                        _buildProgressTrackingTiles(),
                        const SizedBox(height: 32),

                        const PremiumSectionHeader(title: "Settings"),
                        const SizedBox(height: 12),
                        _buildLanguageSelector(),
                        const SizedBox(height: 16),
                        _buildLogoutButton(),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSliverAppBar(Size size) {
    return SliverAppBar(
      expandedHeight: 240,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary700.withOpacity(0.4),
                      AppColors.surface950.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            _buildProfileImage(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeroCard() {
    return PremiumCard(
      child: Column(
        children: [
          Text(
            _user?.name ?? 'Loading...',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray400,
            ),
          ),
          if (_user?.bio != null && _user!.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _user!.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray300,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          if (_isLoading3dAvatar) ...[
            const SizedBox(height: 16),
            const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else if (_avatar2dConfig != null) ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                if (_avatar2dConfig == null) {
                  return Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface800,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary500, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.person_outline, color: Colors.white24, size: 40),
                    ),
                  );
                }

                final Map<String, String> hairStyleMap = {
                  'Short Flat': 'shortFlat',
                  'Short Waved': 'shortWaved',
                  'Short Round': 'shortRound',
                  'Short Curly': 'shortCurly',
                  'Caesar': 'theCaesarAndSidePart',
                  'Sides': 'sides',
                  'Frizzle': 'frizzle',
                  'Shaggy Mullet': 'shaggyMullet',
                };
                final Map<String, String> eyeStyleMap = {
                  'Default': 'default',
                  'Happy': 'happy',
                  'Squint': 'squint',
                  'Side': 'side',
                  'Wink': 'wink',
                  'Surprised': 'surprised',
                };
                final Map<String, String> mouthStyleMap = {
                  'Smile': 'smile',
                  'Twinkle': 'twinkle',
                  'Serious': 'serious',
                  'Default': 'default',
                };
                final Map<String, String> clothingMap = {
                  'Gym Wear': 'shirtCrewNeck',
                  'Casual': 'hoodie',
                  'Sporty': 'shirtScoopNeck',
                  'Smart': 'blazerAndShirt',
                };

                String _bodyShape = _avatar2dConfig!['bodyShape']?.toString() ?? 'Ectomorph';
                String _skinTone = _avatar2dConfig!['skinTone']?.toString() ?? 'ffdbb4';
                String _hairStyle = _avatar2dConfig!['hairStyle']?.toString() ?? 'Short Flat';
                String _hairColor = _avatar2dConfig!['hairColor']?.toString() ?? '2c1b18';
                String _eyeStyle = _avatar2dConfig!['eyeStyle']?.toString() ?? 'Default';
                String _mouthStyle = _avatar2dConfig!['mouthStyle']?.toString() ?? 'Smile';
                String _outfit = _avatar2dConfig!['outfit']?.toString() ?? 'Gym Wear';

                final skinVal = _skinTone;
                final hairVal = hairStyleMap[_hairStyle] ?? 'shortFlat';
                final eyeVal = eyeStyleMap[_eyeStyle] ?? 'default';
                final mouthVal = mouthStyleMap[_mouthStyle] ?? 'smile';
                final hairColorVal = _hairColor;
                final clothingVal = clothingMap[_outfit] ?? 'shirtCrewNeck';

                final url = 'https://api.dicebear.com/9.x/avataaars/svg'
                    '?scale=90'
                    '&backgroundColor=transparent'
                    '&style=default'
                    '&top=$hairVal'
                    '&eyes=$eyeVal'
                    '&mouth=$mouthVal'
                    '&skinColor=$skinVal'
                    '&hairColor=$hairColorVal'
                    '&clothing=$clothingVal'
                    '&clothesColor=262e33'
                    '&accessoriesProbability=0'
                    '&facialHairProbability=0'
                    '&eyebrows=defaultNatural';

                String bodyAsset;
                String shape = _bodyShape.toLowerCase();
                String outfitSuffix = '';
                
                if (_outfit.toLowerCase() == 'casual') {
                  outfitSuffix = '_outfit2';
                } else if (_outfit.toLowerCase() == 'sporty') {
                  outfitSuffix = '_outfit3';
                } else if (_outfit.toLowerCase() == 'smart') {
                  outfitSuffix = '_outfit4';
                } else {
                  outfitSuffix = '';
                }
                
                bodyAsset = 'assets/avatars/$shape$outfitSuffix.png';

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Face in a circle
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.surface800,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary500, width: 2),
                      ),
                      child: ClipOval(
                        child: Transform.scale(
                          scale: 1.2, // slight zoom for the face
                          child: SvgPicture.network(
                            url,
                            key: ValueKey('face_svg_$url'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 32), // Spacing between face and body
                    // Realistic Body
                    SizedBox(
                      height: 180,
                      child: Image.asset(
                        bodyAsset,
                        key: ValueKey('body_$bodyAsset'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                );
              }
            ),


            const SizedBox(height: 8),
            Text(
              '2D Avatar Setup',
              style: TextStyle(color: AppColors.gray400, fontSize: 12),
            ),
          ],

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: PremiumButton(
                  text: 'profile_update'.tr(),
                  onPressed: _showEditProfileModal,
                  variant: ButtonVariant.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PremiumButton(
                  text: '2D Avatar',
                  loading: _isSaving3dAvatar,
                  onPressed: _open2dAvatarCreator,
                  variant: ButtonVariant.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: AppColors.surface900,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: AppColors.surface800.withOpacity(0.5)),
            ),
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'profile_update'.tr(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PremiumInput(
                      label: 'profile_full_name'.tr(),
                      controller: _nameController,
                      icon: Icons.person_outline,
                      validator: (v) => v?.trim().isEmpty ?? true ? 'error_name_required'.tr() : null,
                    ),
                    const SizedBox(height: 16),
                    PremiumInput(
                      label: 'profile_bio'.tr(),
                      controller: _bioController,
                      icon: Icons.info_outline,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    PremiumInput(
                      label: 'profile_phone'.tr(),
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        await _selectDate();
                        setModalState(() {});
                      },
                      child: AbsorbPointer(
                        child: PremiumInput(
                          label: 'profile_dob'.tr(),
                          controller: _dobController,
                          icon: Icons.calendar_today_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PremiumInput(
                      label: 'profile_address'.tr(),
                      controller: _addressController,
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: PremiumInput(
                            label: 'profile_city'.tr(),
                            controller: _cityController,
                            icon: Icons.location_city_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: PremiumInput(
                            label: 'profile_country'.tr(),
                            controller: _countryController,
                            icon: Icons.flag_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (_error.isNotEmpty) ...[
                      Text(
                        _error,
                        style: TextStyle(color: AppColors.red500, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                    ],
                    PremiumButton(
                      text: 'profile_update'.tr(),
                      loading: _isUpdating,
                      onPressed: () async {
                        setModalState(() => _isUpdating = true);
                        try {
                          await _updateProfile();
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          setModalState(() => _isUpdating = false);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary500,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: (_selectedImage != null || _selectedImageFile != null)
                  ? _buildSelectedImageWidget()
                  : _user?.avatar != null
                      ? Image.network(
                          _user!.avatar!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _selectImage,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary500,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImageWidget() {
    if (kIsWeb && _selectedImageFile != null) {
      return FutureBuilder<Uint8List>(
        future: _selectedImageFile!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            );
          } else {
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.gray700,
                shape: BoxShape.circle,
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
        },
      );
    } else if (!kIsWeb && _selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    }
    return Container();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary500, AppColors.primary600],
        ),
      ),
      child: Center(
        child: Text(
          (_user?.name ?? 'U').substring(0, 1).toUpperCase(),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTrackingTiles() {
    return Column(
      children: [
        _buildProgressTile(
          'profile_training_insights'.tr(),
          'profile_insights_desc'.tr(),
          Icons.auto_graph_rounded,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => InsightsScreen())),
        ),
        _buildProgressTile(
          'profile_transformation_photos'.tr(),
          'profile_photos_desc'.tr(),
          Icons.photo_library_rounded,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProgressPhotosScreen())),
        ),
        _buildProgressTile(
          'profile_measurements'.tr(),
          'profile_measurements_desc'.tr(),
          Icons.straighten_rounded,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => MeasurementsScreen())),
        ),
        _buildProgressTile(
          'profile_personal_records'.tr(),
          'profile_records_desc'.tr(),
          Icons.emoji_events_rounded,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalRecordsScreen())),
        ),
        _buildProgressTile(
          'profile_training_config'.tr(),
          'profile_config_desc'.tr(),
          Icons.settings_suggest_rounded,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => TrainingSettingsScreen())),
        ),
      ],
    );
  }

  Widget _buildGamificationTile() {
    return Consumer<GamificationProvider>(
      builder: (context, provider, child) {
        final gamification = provider.userGamification;
        if (gamification == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GamificationScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary500.withOpacity(0.2), AppColors.accent500.withOpacity(0.2)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary500.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${gamification.level}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'gamification_title'.tr(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'xp_label'.tr(args: [gamification.totalXp.toString()]),
                            style: TextStyle(color: AppColors.gray400, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: gamification.progress,
                    minHeight: 8,
                    backgroundColor: AppColors.gray800,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.gray800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.gray700.withOpacity(0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary500.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary500, size: 24),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.gray400, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.gray700, size: 16),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.gray800,
              title: Text('logout'.tr(), style: const TextStyle(color: Colors.white)),
              content: Text(
                'logout_confirmation'.tr(),
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('cancel'.tr()),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'logout'.tr(),
                    style: TextStyle(color: AppColors.red500),
                  ),
                ),
              ],
            ),
          );

          if (result == true) {
            await _logout();
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: AppColors.red500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'logout'.tr(),
          style: TextStyle(
            color: AppColors.red500,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray700.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: AppColors.primary500),
              const SizedBox(width: 8),
              Text(
                'language'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLanguageOption('English', const Locale('en')),
              const SizedBox(width: 12),
              _buildLanguageOption('Français', const Locale('fr')),
              const SizedBox(width: 12),
              _buildLanguageOption('العربية', const Locale('ar')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String label, Locale locale) {
    final isSelected = context.locale == locale;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.setLocale(locale);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary500 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary500 : AppColors.gray600,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.gray400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}