import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class MuscleBodyDiagram extends StatelessWidget {
  final String? selectedMuscle;
  final Color highlightColor;
  final double width;
  final double height;
  final bool showLabels;

  const MuscleBodyDiagram({
    super.key,
    this.selectedMuscle,
    this.highlightColor = const Color(0xFFFF4081),
    this.width = 180,
    this.height = 350,
    this.showLabels = false,
  });

  bool _isHighlighted(String muscle) {
    if (selectedMuscle == null) return false;
    if (selectedMuscle == muscle || selectedMuscle == 'fullbody') return true;

    // Legacy support - old muscle names highlight all related subdivisions
    final muscleGroups = {
      'chest': ['upper-chest', 'lower-chest'],
      'back': ['upper-back', 'mid-back', 'lower-back'],
      'shoulders': ['front-delts', 'side-delts', 'rear-delts'],
      'abs': ['upper-abs', 'lower-abs', 'obliques']
    };

    if (muscleGroups.containsKey(selectedMuscle)) {
      return muscleGroups[selectedMuscle]!.contains(muscle);
    }

    return false;
  }

  bool _isBackMuscle(String? muscle) {
    if (muscle == null) return false;
    const backMuscles = {
      'upper-back', 'mid-back', 'lower-back', 'rear-delts',
      'triceps', 'glutes', 'hamstrings', 'back'
    };
    return backMuscles.contains(muscle);
  }

  Color _getMuscleColor(String muscle) {
    return _isHighlighted(muscle) ? highlightColor : const Color(0xFF1a1a1a);
  }

  double _getMuscleOpacity(String muscle) {
    return _isHighlighted(muscle) ? 1.0 : 0.25;
  }

  @override
  Widget build(BuildContext context) {
    final showBackView = _isBackMuscle(selectedMuscle);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              showBackView ? 'BACK VIEW' : 'FRONT VIEW',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFd1d5db),
                letterSpacing: 1.5,
              ),
            ),
          ),
        CustomPaint(
          size: Size(width, height),
          painter: showBackView
              ? _BackBodyPainter(
                  getMuscleColor: _getMuscleColor,
                  getMuscleOpacity: _getMuscleOpacity,
                )
              : _FrontBodyPainter(
                  getMuscleColor: _getMuscleColor,
                  getMuscleOpacity: _getMuscleOpacity,
                ),
        ),
      ],
    );
  }
}

class _FrontBodyPainter extends CustomPainter {
  final Color Function(String) getMuscleColor;
  final double Function(String) getMuscleOpacity;

  _FrontBodyPainter({
    required this.getMuscleColor,
    required this.getMuscleOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 180;
    final scaleY = size.height / 350;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    const skinColor = Color(0xFFd4a574);
    const strokeColor = Color(0xFF444444);

    // Draw complete body with colored muscle regions
    _drawBodyWithMuscles(canvas);

    canvas.restore();
  }

  void _drawBodyWithMuscles(Canvas canvas) {
    const skinColor = Color(0xFFd4a574);
    const strokeColor = Color(0xFF444444);

    // Head
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(90, 28), width: 40, height: 48),
      Paint()..color = skinColor
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(90, 28), width: 40, height: 48),
      Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 2.0
    );

    // Facial features
    canvas.drawOval(Rect.fromCenter(center: const Offset(84, 26), width: 4, height: 6), Paint()..color = const Color(0xFF0a0a0a).withOpacity(0.6));
    canvas.drawOval(Rect.fromCenter(center: const Offset(96, 26), width: 4, height: 6), Paint()..color = const Color(0xFF0a0a0a).withOpacity(0.6));

    // Neck
    final neckPath = Path()
      ..moveTo(82, 50)..lineTo(78, 62)..lineTo(102, 62)..lineTo(98, 50)..close();
    canvas.drawPath(neckPath, Paint()..color = skinColor);
    canvas.drawPath(neckPath, Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Draw muscle regions as colored parts of body
    _drawShoulderRegion(canvas, 'front-delts', 'side-delts');
    _drawChestRegion(canvas, 'upper-chest', 'lower-chest');
    _drawArmRegion(canvas, 'biceps', 'forearms');
    _drawAbsRegion(canvas, 'upper-abs', 'lower-abs', 'obliques');
    _drawLegRegion(canvas, 'quads', 'calves');

    // Draw body outlines
    _drawBodyOutlines(canvas);

    // Hands
    canvas.drawOval(Rect.fromCenter(center: const Offset(40, 170), width: 14, height: 20), Paint()..color = skinColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(40, 170), width: 14, height: 20), Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawOval(Rect.fromCenter(center: const Offset(140, 170), width: 14, height: 20), Paint()..color = skinColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(140, 170), width: 14, height: 20), Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Feet
    canvas.drawOval(Rect.fromCenter(center: const Offset(78, 330), width: 18, height: 24), Paint()..color = skinColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(78, 330), width: 18, height: 24), Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawOval(Rect.fromCenter(center: const Offset(102, 330), width: 18, height: 24), Paint()..color = skinColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(102, 330), width: 18, height: 24), Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _drawShoulderRegion(Canvas canvas, String frontDeltMuscle, String sideDeltMuscle) {
    const skinColor = Color(0xFFd4a574);
    final frontDeltColor = getMuscleColor(frontDeltMuscle).withOpacity(getMuscleOpacity(frontDeltMuscle));
    final sideDeltColor = getMuscleColor(sideDeltMuscle).withOpacity(getMuscleOpacity(sideDeltMuscle));
    
    // Left shoulder (front delt region)
    final leftFrontDeltPath = Path()
      ..moveTo(58, 68)..quadraticBezierTo(52, 64, 50, 72)
      ..quadraticBezierTo(48, 80, 54, 84)..lineTo(62, 80)..close();
    canvas.drawPath(leftFrontDeltPath, Paint()..color = frontDeltColor);
    
    // Right shoulder (front delt region)
    final rightFrontDeltPath = Path()
      ..moveTo(122, 68)..quadraticBezierTo(128, 64, 130, 72)
      ..quadraticBezierTo(132, 80, 126, 84)..lineTo(118, 80)..close();
    canvas.drawPath(rightFrontDeltPath, Paint()..color = frontDeltColor);
    
    // Left side delt
    final leftSideDeltPath = Path()
      ..moveTo(42, 62)..quadraticBezierTo(35, 68, 35, 78)
      ..quadraticBezierTo(35, 88, 42, 92)..lineTo(52, 85)..lineTo(50, 70)..close();
    canvas.drawPath(leftSideDeltPath, Paint()..color = sideDeltColor);
    
    // Right side delt
    final rightSideDeltPath = Path()
      ..moveTo(138, 62)..quadraticBezierTo(145, 68, 145, 78)
      ..quadraticBezierTo(145, 88, 138, 92)..lineTo(128, 85)..lineTo(130, 70)..close();
    canvas.drawPath(rightSideDeltPath, Paint()..color = sideDeltColor);
  }

  void _drawChestRegion(Canvas canvas, String upperChestMuscle, String lowerChestMuscle) {
    final upperColor = getMuscleColor(upperChestMuscle).withOpacity(getMuscleOpacity(upperChestMuscle));
    final lowerColor = getMuscleColor(lowerChestMuscle).withOpacity(getMuscleOpacity(lowerChestMuscle));
    
    // Left upper chest
    final leftUpperChestPath = Path()
      ..moveTo(62, 68)..lineTo(58, 85)..lineTo(72, 90)..lineTo(82, 85)..lineTo(88, 72)..lineTo(80, 68)..close();
    canvas.drawPath(leftUpperChestPath, Paint()..color = upperColor);
    
    // Right upper chest
    final rightUpperChestPath = Path()
      ..moveTo(118, 68)..lineTo(122, 85)..lineTo(108, 90)..lineTo(98, 85)..lineTo(92, 72)..lineTo(100, 68)..close();
    canvas.drawPath(rightUpperChestPath, Paint()..color = upperColor);
    
    // Left lower chest
    final leftLowerChestPath = Path()
      ..moveTo(72, 90)..lineTo(68, 105)..lineTo(75, 115)..lineTo(88, 108)..lineTo(88, 90)..close();
    canvas.drawPath(leftLowerChestPath, Paint()..color = lowerColor);
    
    // Right lower chest
    final rightLowerChestPath = Path()
      ..moveTo(108, 90)..lineTo(112, 105)..lineTo(105, 115)..lineTo(92, 108)..lineTo(92, 90)..close();
    canvas.drawPath(rightLowerChestPath, Paint()..color = lowerColor);
  }

  void _drawArmRegion(Canvas canvas, String bicepsMuscle, String forearmsMuscle) {
    final bicepsColor = getMuscleColor(bicepsMuscle).withOpacity(getMuscleOpacity(bicepsMuscle));
    final forearmsColor = getMuscleColor(forearmsMuscle).withOpacity(getMuscleOpacity(forearmsMuscle));
    
    // Left bicep
    final leftBicepPath = Path()
      ..moveTo(42, 85)..lineTo(35, 95)..lineTo(32, 115)..lineTo(38, 120)..lineTo(50, 115)..lineTo(52, 90)..close();
    canvas.drawPath(leftBicepPath, Paint()..color = bicepsColor);
    
    // Right bicep
    final rightBicepPath = Path()
      ..moveTo(138, 85)..lineTo(145, 95)..lineTo(148, 115)..lineTo(142, 120)..lineTo(130, 115)..lineTo(128, 90)..close();
    canvas.drawPath(rightBicepPath, Paint()..color = bicepsColor);
    
    // Left forearm
    final leftForearmPath = Path()
      ..moveTo(36, 120)..lineTo(30, 158)..lineTo(33, 168)..lineTo(42, 168)..lineTo(45, 158)..lineTo(40, 120)..close();
    canvas.drawPath(leftForearmPath, Paint()..color = forearmsColor);
    
    // Right forearm
    final rightForearmPath = Path()
      ..moveTo(144, 120)..lineTo(150, 158)..lineTo(147, 168)..lineTo(138, 168)..lineTo(135, 158)..lineTo(140, 120)..close();
    canvas.drawPath(rightForearmPath, Paint()..color = forearmsColor);
  }

  void _drawAbsRegion(Canvas canvas, String upperAbsMuscle, String lowerAbsMuscle, String obliquesMuscle) {
    final upperAbsColor = getMuscleColor(upperAbsMuscle).withOpacity(getMuscleOpacity(upperAbsMuscle));
    final lowerAbsColor = getMuscleColor(lowerAbsMuscle).withOpacity(getMuscleOpacity(lowerAbsMuscle));
    final obliquesColor = getMuscleColor(obliquesMuscle).withOpacity(getMuscleOpacity(obliquesMuscle));
    
    // Upper abs (4 packs)
    final upperAbsPath = Path()
      ..moveTo(78, 105)..lineTo(78, 130)..lineTo(90, 132)..lineTo(102, 130)..lineTo(102, 105)..lineTo(90, 103)..close();
    canvas.drawPath(upperAbsPath, Paint()..color = upperAbsColor);
    
    // Lower abs (2 packs)
    final lowerAbsPath = Path()
      ..moveTo(80, 132)..lineTo(80, 150)..lineTo(90, 152)..lineTo(100, 150)..lineTo(100, 132)..close();
    canvas.drawPath(lowerAbsPath, Paint()..color = lowerAbsColor);
    
    // Left oblique
    final leftObliquePath = Path()
      ..moveTo(68, 105)..lineTo(58, 145)..lineTo(65, 155)..lineTo(75, 150)..lineTo(78, 110)..close();
    canvas.drawPath(leftObliquePath, Paint()..color = obliquesColor);
    
    // Right oblique
    final rightObliquePath = Path()
      ..moveTo(112, 105)..lineTo(122, 145)..lineTo(115, 155)..lineTo(105, 150)..lineTo(102, 110)..close();
    canvas.drawPath(rightObliquePath, Paint()..color = obliquesColor);
  }

  void _drawLegRegion(Canvas canvas, String quadsMuscle, String calvesMuscle) {
    final quadsColor = getMuscleColor(quadsMuscle).withOpacity(getMuscleOpacity(quadsMuscle));
    final calvesColor = getMuscleColor(calvesMuscle).withOpacity(getMuscleOpacity(calvesMuscle));
    
    // Left quad
    final leftQuadPath = Path()
      ..moveTo(72, 160)..lineTo(65, 250)..lineTo(72, 265)..lineTo(88, 265)..lineTo(92, 250)..lineTo(88, 160)..close();
    canvas.drawPath(leftQuadPath, Paint()..color = quadsColor);
    
    // Right quad
    final rightQuadPath = Path()
      ..moveTo(108, 160)..lineTo(115, 250)..lineTo(108, 265)..lineTo(92, 265)..lineTo(88, 250)..lineTo(92, 160)..close();
    canvas.drawPath(rightQuadPath, Paint()..color = quadsColor);
    
    // Left calf
    final leftCalfPath = Path()
      ..moveTo(72, 268)..lineTo(68, 305)..lineTo(75, 315)..lineTo(82, 310)..lineTo(82, 268)..close();
    canvas.drawPath(leftCalfPath, Paint()..color = calvesColor);
    
    // Right calf
    final rightCalfPath = Path()
      ..moveTo(108, 268)..lineTo(112, 305)..lineTo(105, 315)..lineTo(98, 310)..lineTo(98, 268)..close();
    canvas.drawPath(rightCalfPath, Paint()..color = calvesColor);
  }

  void _drawBodyOutlines(Canvas canvas) {
    const strokeColor = Color(0xFF8b6f47);
    final outlinePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Torso outline
    final torsoPath = Path()
      ..moveTo(78, 62)..quadraticBezierTo(65, 70, 58, 85)
      ..lineTo(55, 145)..quadraticBezierTo(50, 155, 60, 165)
      ..lineTo(72, 180)..lineTo(90, 180)..lineTo(108, 180)..lineTo(120, 165)
      ..quadraticBezierTo(130, 155, 125, 145)..lineTo(122, 85)
      ..quadraticBezierTo(115, 70, 102, 62);
    canvas.drawPath(torsoPath, outlinePaint);
  }

  @override
  bool shouldRepaint(_FrontBodyPainter oldDelegate) => true;
}

class _BackBodyPainter extends CustomPainter {
  final Color Function(String) getMuscleColor;
  final double Function(String) getMuscleOpacity;

  _BackBodyPainter({
    required this.getMuscleColor,
    required this.getMuscleOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 180;
    final scaleY = size.height / 350;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    const skinColor = Color(0xFFd4a574);
    const strokeColor = Color(0xFF444444);

    // Draw complete body with colored muscle regions
    _drawBodyWithMuscles(canvas);

    canvas.restore();
  }

  void _drawBodyWithMuscles(Canvas canvas) {
    const skinColor = Color(0xFFd4a574);
    const strokeColor = Color(0xFF444444);

    // Head - back view
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(90, 28), width: 40, height: 48),
      Paint()..color = skinColor
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(90, 28), width: 40, height: 48),
      Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 2.0
    );

    // Neck
    final neckPath = Path()
      ..moveTo(82, 50)..lineTo(74, 62)..lineTo(106, 62)..lineTo(98, 50)..close();
    canvas.drawPath(neckPath, Paint()..color = skinColor);
    canvas.drawPath(neckPath, Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Draw muscle regions as colored parts of body  
    _drawBackShoulderRegion(canvas, 'rear-delts', 'side-delts');
    _drawBackRegion(canvas, 'upper-back', 'mid-back', 'lower-back');
    _drawTricepsRegion(canvas, 'triceps', 'forearms');
    _drawGluteRegion(canvas, 'glutes', 'hamstrings');
    _drawCalfRegion(canvas, 'calves');

    // Draw body outlines
    _drawBackBodyOutlines(canvas);

    // Hands
    canvas.drawOval(Rect.fromCenter(center: const Offset(40, 170), width: 14, height: 20), Paint()..color = skinColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(40, 170), width: 14, height: 20), Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawOval(Rect.fromCenter(center: const Offset(140, 170), width: 14, height: 20), Paint()..color = skinColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(140, 170), width: 14, height: 20), Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Feet
    canvas.drawOval(Rect.fromCenter(center: const Offset(78, 330), width: 18, height: 24), Paint()..color = skinColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(78, 330), width: 18, height: 24), Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawOval(Rect.fromCenter(center: const Offset(102, 330), width: 18, height: 24), Paint()..color = skinColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(102, 330), width: 18, height: 24), Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _drawBackShoulderRegion(Canvas canvas, String rearDeltMuscle, String sideDeltMuscle) {
    final rearDeltColor = getMuscleColor(rearDeltMuscle).withOpacity(getMuscleOpacity(rearDeltMuscle));
    final sideDeltColor = getMuscleColor(sideDeltMuscle).withOpacity(getMuscleOpacity(sideDeltMuscle));
    
    // Left rear delt
    final leftRearDeltPath = Path()
      ..moveTo(58, 68)..quadraticBezierTo(52, 64, 50, 72)
      ..quadraticBezierTo(48, 80, 54, 84)..lineTo(62, 80)..close();
    canvas.drawPath(leftRearDeltPath, Paint()..color = rearDeltColor);
    
    // Right rear delt
    final rightRearDeltPath = Path()
      ..moveTo(122, 68)..quadraticBezierTo(128, 64, 130, 72)
      ..quadraticBezierTo(132, 80, 126, 84)..lineTo(118, 80)..close();
    canvas.drawPath(rightRearDeltPath, Paint()..color = rearDeltColor);
    
    // Left side delt
    final leftSideDeltPath = Path()
      ..moveTo(42, 62)..quadraticBezierTo(35, 68, 35, 78)
      ..quadraticBezierTo(35, 88, 42, 92)..lineTo(52, 85)..lineTo(50, 70)..close();
    canvas.drawPath(leftSideDeltPath, Paint()..color = sideDeltColor);
    
    // Right side delt
    final rightSideDeltPath = Path()
      ..moveTo(138, 62)..quadraticBezierTo(145, 68, 145, 78)
      ..quadraticBezierTo(145, 88, 138, 92)..lineTo(128, 85)..lineTo(130, 70)..close();
    canvas.drawPath(rightSideDeltPath, Paint()..color = sideDeltColor);
  }

  void _drawBackRegion(Canvas canvas, String upperBackMuscle, String midBackMuscle, String lowerBackMuscle) {
    final upperColor = getMuscleColor(upperBackMuscle).withOpacity(getMuscleOpacity(upperBackMuscle));
    final midColor = getMuscleColor(midBackMuscle).withOpacity(getMuscleOpacity(midBackMuscle));
    final lowerColor = getMuscleColor(lowerBackMuscle).withOpacity(getMuscleOpacity(lowerBackMuscle));
    
    // Upper back (traps) - diamond shape
    final upperBackPath = Path()
      ..moveTo(70, 64)..lineTo(90, 62)..lineTo(110, 64)
      ..lineTo(108, 90)..lineTo(90, 94)..lineTo(72, 90)..close();
    canvas.drawPath(upperBackPath, Paint()..color = upperColor);
    
    // Mid back (lats) - wings
    final leftLatPath = Path()
      ..moveTo(72, 90)..lineTo(64, 138)..quadraticBezierTo(58, 148, 66, 154)
      ..lineTo(76, 150)..lineTo(76, 90)..close();
    canvas.drawPath(leftLatPath, Paint()..color = midColor);
    
    final rightLatPath = Path()
      ..moveTo(108, 90)..lineTo(116, 138)..quadraticBezierTo(122, 148, 114, 154)
      ..lineTo(104, 150)..lineTo(104, 90)..close();
    canvas.drawPath(rightLatPath, Paint()..color = midColor);
    
    // Lower back (erector spinae) - Christmas tree
    final leftLowerBackPath = Path()
      ..moveTo(76, 150)..lineTo(72, 175)..quadraticBezierTo(70, 182, 76, 185)
      ..lineTo(85, 180)..lineTo(85, 150)..close();
    canvas.drawPath(leftLowerBackPath, Paint()..color = lowerColor);
    
    final rightLowerBackPath = Path()
      ..moveTo(104, 150)..lineTo(108, 175)..quadraticBezierTo(110, 182, 104, 185)
      ..lineTo(95, 180)..lineTo(95, 150)..close();
    canvas.drawPath(rightLowerBackPath, Paint()..color = lowerColor);
  }

  void _drawTricepsRegion(Canvas canvas, String tricepsMuscle, String forearmsMuscle) {
    final tricepsColor = getMuscleColor(tricepsMuscle).withOpacity(getMuscleOpacity(tricepsMuscle));
    final forearmsColor = getMuscleColor(forearmsMuscle).withOpacity(getMuscleOpacity(forearmsMuscle));
    
    // Left tricep
    final leftTricepPath = Path()
      ..moveTo(42, 85)..lineTo(35, 95)..lineTo(32, 115)..lineTo(38, 120)..lineTo(50, 115)..lineTo(52, 90)..close();
    canvas.drawPath(leftTricepPath, Paint()..color = tricepsColor);
    
    // Right tricep
    final rightTricepPath = Path()
      ..moveTo(138, 85)..lineTo(145, 95)..lineTo(148, 115)..lineTo(142, 120)..lineTo(130, 115)..lineTo(128, 90)..close();
    canvas.drawPath(rightTricepPath, Paint()..color = tricepsColor);
    
    // Left forearm
    final leftForearmPath = Path()
      ..moveTo(36, 120)..lineTo(30, 158)..lineTo(33, 168)..lineTo(42, 168)..lineTo(45, 158)..lineTo(40, 120)..close();
    canvas.drawPath(leftForearmPath, Paint()..color = forearmsColor);
    
    // Right forearm
    final rightForearmPath = Path()
      ..moveTo(144, 120)..lineTo(150, 158)..lineTo(147, 168)..lineTo(138, 168)..lineTo(135, 158)..lineTo(140, 120)..close();
    canvas.drawPath(rightForearmPath, Paint()..color = forearmsColor);
  }

  void _drawGluteRegion(Canvas canvas, String glutesMuscle, String hamstringsMuscle) {
    final glutesColor = getMuscleColor(glutesMuscle).withOpacity(getMuscleOpacity(glutesMuscle));
    final hamstringsColor = getMuscleColor(hamstringsMuscle).withOpacity(getMuscleOpacity(hamstringsMuscle));
    
    // Left glute
    final leftGlutePath = Path()
      ..moveTo(72, 178)..lineTo(65, 210)..lineTo(72, 218)..lineTo(88, 215)..lineTo(90, 185)..close();
    canvas.drawPath(leftGlutePath, Paint()..color = glutesColor);
    
    // Right glute
    final rightGlutePath = Path()
      ..moveTo(108, 178)..lineTo(115, 210)..lineTo(108, 218)..lineTo(92, 215)..lineTo(90, 185)..close();
    canvas.drawPath(rightGlutePath, Paint()..color = glutesColor);
    
    // Left hamstring
    final leftHamstringPath = Path()
      ..moveTo(72, 220)..lineTo(66, 260)..lineTo(70, 268)..lineTo(85, 265)..lineTo(88, 220)..close();
    canvas.drawPath(leftHamstringPath, Paint()..color = hamstringsColor);
    
    // Right hamstring
    final rightHamstringPath = Path()
      ..moveTo(108, 220)..lineTo(114, 260)..lineTo(110, 268)..lineTo(95, 265)..lineTo(92, 220)..close();
    canvas.drawPath(rightHamstringPath, Paint()..color = hamstringsColor);
  }

  void _drawCalfRegion(Canvas canvas, String calvesMuscle) {
    final calvesColor = getMuscleColor(calvesMuscle).withOpacity(getMuscleOpacity(calvesMuscle));
    
    // Left calf
    final leftCalfPath = Path()
      ..moveTo(72, 268)..lineTo(68, 305)..lineTo(75, 315)..lineTo(82, 310)..lineTo(82, 268)..close();
    canvas.drawPath(leftCalfPath, Paint()..color = calvesColor);
    
    // Right calf
    final rightCalfPath = Path()
      ..moveTo(108, 268)..lineTo(112, 305)..lineTo(105, 315)..lineTo(98, 310)..lineTo(98, 268)..close();
    canvas.drawPath(rightCalfPath, Paint()..color = calvesColor);
  }

  void _drawBackBodyOutlines(Canvas canvas) {
    const strokeColor = Color(0xFF8b6f47);
    final outlinePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Torso outline
    final torsoPath = Path()
      ..moveTo(78, 62)..quadraticBezierTo(65, 70, 58, 85)
      ..lineTo(55, 145)..quadraticBezierTo(50, 160, 60, 175)
      ..lineTo(72, 185)..lineTo(90, 185)..lineTo(108, 185)..lineTo(120, 175)
      ..quadraticBezierTo(130, 160, 125, 145)..lineTo(122, 85)
      ..quadraticBezierTo(115, 70, 102, 62);
    canvas.drawPath(torsoPath, outlinePaint);
  }

  @override
  bool shouldRepaint(_BackBodyPainter oldDelegate) => true;
}
