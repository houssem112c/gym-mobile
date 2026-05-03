import 'package:flutter/material.dart';
import '../../models/story.dart';

class StoryViewer extends StatefulWidget {
  final List<Story> stories;
  final String categoryName;

  const StoryViewer({
    Key? key,
    required this.stories,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _progressController;
  
  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.stories[_currentIndex].duration),
    );
    _startProgress();
  }

  void _startProgress() {
    _progressController.forward().then((_) {
      if (_currentIndex < widget.stories.length - 1) {
        setState(() {
          _currentIndex++;
          _progressController.duration = Duration(seconds: widget.stories[_currentIndex].duration);
          _progressController.reset();
          _startProgress();
        });
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  void _onTapLeft() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _progressController.duration = Duration(seconds: widget.stories[_currentIndex].duration);
        _progressController.reset();
        _startProgress();
      });
    }
  }

  void _onTapRight() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _progressController.duration = Duration(seconds: widget.stories[_currentIndex].duration);
        _progressController.reset();
        _startProgress();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStory = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _onTapLeft();
          } else {
            _onTapRight();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story Media
            if (currentStory.mediaType == 'IMAGE')
              Image.network(
                currentStory.mediaUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 48),
                        SizedBox(height: 8),
                        Text('Failed to load image', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                },
              )
            else
              Center(
                child: Icon(Icons.play_circle_outline, color: Colors.white, size: 64),
              ),

            // Progress bars at top
            Positioned(
              top: 50,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(
                  widget.stories.length,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: index == _currentIndex
                                ? _progressController.value
                                : index < _currentIndex
                                    ? 1.0
                                    : 0.0,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top header with category name
            Positioned(
              top: 70,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.primaries[widget.categoryName.hashCode % Colors.primaries.length],
                    ),
                    child: Center(
                      child: Text(
                        widget.categoryName[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    widget.categoryName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Caption at bottom
            if (currentStory.caption != null && currentStory.caption!.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentStory.caption!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
