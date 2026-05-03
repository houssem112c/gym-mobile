import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/colors.dart';
import '../services/api_service.dart'; // assuming this handles HTTP

class AvatarCreatorScreen extends StatefulWidget {
  final Map<String, dynamic>? initialConfig;

  const AvatarCreatorScreen({
    super.key,
    this.initialConfig,
  });

  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  // --- State ---
  late String _bodyShape;
  late String _skinTone;
  late String _hairStyle;
  late String _hairColor;
  late String _eyeStyle;
  late String _mouthStyle;
  late String _outfit;
  int _selectedTab = 0;
  bool _isSaving = false;

  // --- Category Tabs ---
  final List<String> _categories = [
    'Body', 'Skin', 'Hair', 'Hair Color', 'Eyes', 'Mouth', 'Outfit',
  ];

  // --- Options ---
  final List<String> bodyShapes = ['Ectomorph', 'Mesomorph', 'Endomorph', 'Athletic', 'Slim'];
  final List<String> outfits = ['Gym Wear', 'Casual', 'Sporty', 'Smart'];

  // DiceBear valid skin tones
  final List<String> skinTones = ['ffdbb4', 'edb98a', 'f8d25c', 'fd9841', 'd08b5b', 'ae5d29', '614335'];

  // DiceBear valid hair colors
  final List<String> hairColors = ['2c1b18', '4a312c', '724133', 'a55728', 'b58143', 'c93305', 'd6b370', 'e8e1e1', 'ecdcbf', 'f59797'];

  // Avataaars real API options
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

  // Clothing mapping from outfit name
  final Map<String, String> clothingMap = {
    'Gym Wear': 'shirtCrewNeck',
    'Casual': 'hoodie',
    'Sporty': 'shirtScoopNeck',
    'Smart': 'blazerAndShirt',
  };

  @override
  void initState() {
    super.initState();
    _bodyShape = widget.initialConfig?['bodyShape'] ?? bodyShapes.first;
    _skinTone = widget.initialConfig?['skinTone'] ?? skinTones.first;
    _hairStyle = widget.initialConfig?['hairStyle'] ?? hairStyleMap.keys.first;
    _hairColor = widget.initialConfig?['hairColor'] ?? hairColors.first;
    _eyeStyle = widget.initialConfig?['eyeStyle'] ?? eyeStyleMap.keys.first;
    _mouthStyle = widget.initialConfig?['mouthStyle'] ?? mouthStyleMap.keys.first;
    _outfit = widget.initialConfig?['outfit'] ?? outfits.first;
  }

  // --- Save ---
  Future<void> _saveAvatar() async {
    setState(() => _isSaving = true);
    try {
      final config = {
        'bodyShape': _bodyShape,
        'skinTone': _skinTone,
        'hairStyle': _hairStyle,
        'hairColor': _hairColor,
        'eyeStyle': _eyeStyle,
        'mouthStyle': _mouthStyle,
        'outfit': _outfit,
      };
      Navigator.of(context).pop(config);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save avatar: $e'), backgroundColor: AppColors.red500),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- DiceBear Avataaars SVG URL Builder ---
  // Uses SVG format (free tier, high quality, sharp rendering)
  String _getAvatarUrl({String? hair, String? eyes, String? mouth, String? skin, String? hColor, String? clothing}) {
    final skinVal = skin ?? _skinTone;
    final hairVal = hairStyleMap[hair ?? _hairStyle] ?? 'shortFlat';
    final eyeVal = eyeStyleMap[eyes ?? _eyeStyle] ?? 'default';
    final mouthVal = mouthStyleMap[mouth ?? _mouthStyle] ?? 'smile';
    final hairColorVal = hColor ?? _hairColor;
    final clothingVal = clothingMap[clothing ?? _outfit] ?? 'shirtCrewNeck';

    return 'https://api.dicebear.com/9.x/avataaars/svg'
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
  }

  // --- Body Image Path ---
  String _getBodyImage() {
    String shape = _bodyShape.toLowerCase();
    String outfitSuffix = '';
    switch (_outfit.toLowerCase()) {
      case 'gym wear': outfitSuffix = ''; break;
      case 'casual':   outfitSuffix = '_outfit2'; break;
      case 'sporty':   outfitSuffix = '_outfit3'; break;
      case 'smart':    outfitSuffix = '_outfit4'; break;
      default:         outfitSuffix = '';
    }
    return 'assets/avatars/$shape$outfitSuffix.png';
  }

  // ===================== UI =====================

  Widget _buildPreview() {
    final bool isFaceMode = (_selectedTab >= 1 && _selectedTab <= 5);

    return Container(
      height: 340,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface900,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.surface700, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Body (local asset)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              transform: Matrix4.identity()
                ..scale(isFaceMode ? 3.0 : 1.0),
              transformAlignment: Alignment.topCenter,
              child: Image.asset(
                _getBodyImage(),
                key: ValueKey('body_${_getBodyImage()}'),
                fit: BoxFit.contain,
              ),
            ),

            // Face overlay (DiceBear SVG - sharp, high quality)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()
                  ..scale(isFaceMode ? 3.0 : 1.0),
                transformAlignment: Alignment.topCenter,
                child: SizedBox(
                  height: 80,
                  child: SvgPicture.network(
                    _getAvatarUrl(),
                    key: ValueKey('face_svg_${_getAvatarUrl()}'),
                    fit: BoxFit.contain,
                    placeholderBuilder: (context) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary500),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Category Selector ---
  Widget _buildCategorySelector() {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary500 : AppColors.surface800,
                borderRadius: BorderRadius.circular(23),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Visual Option List (with SVG thumbnail previews) ---
  Widget _buildVisualOptionList(List<String> options, String current, Function(String) onSelected, String Function(String) urlBuilder) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (context, index) {
          final opt = options[index];
          final isSelected = current == opt;

          return GestureDetector(
            onTap: () => onSelected(opt),
            child: Container(
              width: 85,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary500.withOpacity(0.15) : AppColors.surface800,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary500 : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: SvgPicture.network(
                      urlBuilder(opt),
                      fit: BoxFit.contain,
                      placeholderBuilder: (c) => const Center(
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Simple Text Option List ---
  Widget _buildTextOptionList(List<String> options, String current, Function(String) onSelected) {
    return ListView.builder(
      itemCount: options.length,
      itemBuilder: (context, index) {
        final opt = options[index];
        final isSelected = opt == current;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surface800 : AppColors.surface900,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary500 : AppColors.surface800,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    opt,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.primary500, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Color Grid ---
  Widget _buildColorGrid(List<String> hexCodes, String selected, Function(String) onSelect) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: hexCodes.length,
      itemBuilder: (context, index) {
        final hex = hexCodes[index];
        final isSelected = hex == selected;
        Color color;
        try {
          color = Color(int.parse('0xFF$hex'));
        } catch (_) {
          color = Colors.grey;
        }

        return GestureDetector(
          onTap: () => onSelect(hex),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary500 : Colors.white10,
                width: isSelected ? 3.5 : 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppColors.primary500.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
                  : [],
            ),
          ),
        );
      },
    );
  }

  // --- Active Tab Content ---
  Widget _buildActiveTab() {
    switch (_selectedTab) {
      case 0: // Body
        return _buildTextOptionList(bodyShapes, _bodyShape, (v) => setState(() => _bodyShape = v));
      case 1: // Skin
        return _buildColorGrid(skinTones, _skinTone, (v) => setState(() => _skinTone = v));
      case 2: // Hair Style
        return _buildVisualOptionList(
          hairStyleMap.keys.toList(),
          _hairStyle,
          (v) => setState(() => _hairStyle = v),
          (opt) => _getAvatarUrl(hair: opt),
        );
      case 3: // Hair Color
        return _buildColorGrid(hairColors, _hairColor, (v) => setState(() => _hairColor = v));
      case 4: // Eyes
        return _buildVisualOptionList(
          eyeStyleMap.keys.toList(),
          _eyeStyle,
          (v) => setState(() => _eyeStyle = v),
          (opt) => _getAvatarUrl(eyes: opt),
        );
      case 5: // Mouth
        return _buildVisualOptionList(
          mouthStyleMap.keys.toList(),
          _mouthStyle,
          (v) => setState(() => _mouthStyle = v),
          (opt) => _getAvatarUrl(mouth: opt),
        );
      case 6: // Outfit
        return _buildTextOptionList(outfits, _outfit, (v) => setState(() => _outfit = v));
      default:
        return const SizedBox();
    }
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface950,
      appBar: AppBar(
        backgroundColor: AppColors.surface950,
        elevation: 0,
        title: const Text('Customize Avatar', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveAvatar,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary500))
                : const Text('Save', style: TextStyle(color: AppColors.primary500, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreview(),
              const SizedBox(height: 20),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              Expanded(child: _buildActiveTab()),
            ],
          ),
        ),
      ),
    );
  }
}
