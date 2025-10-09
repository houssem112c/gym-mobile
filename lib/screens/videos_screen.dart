import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';
import '../models/video.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final ApiService _apiService = ApiService();
  List<VideoCategory> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await _apiService.get(ApiConfig.videos);
      
      // Check if response data is valid
      if (response.data == null) {
        throw Exception('No video data received from server');
      }
      
      final List<dynamic> data = response.data is List ? response.data : [];
      
      if (data.isEmpty) {
        setState(() {
          _categories = [];
          _isLoading = false;
        });
        return;
      }
      
      // Group videos by category with better error handling
      Map<String, List<Video>> videosByCategory = {};
      for (var videoData in data) {
        try {
          if (videoData is! Map<String, dynamic>) {
            print('Invalid video data format: $videoData');
            continue;
          }
          
          final video = Video.fromJson(videoData);
          
          // Skip videos with empty URLs
          if (video.url.isEmpty) {
            print('Skipping video with empty URL: ${video.title}');
            continue;
          }
          
          final categoryName = video.category?.name ?? 'Uncategorized';
          
          if (!videosByCategory.containsKey(categoryName)) {
            videosByCategory[categoryName] = [];
          }
          videosByCategory[categoryName]!.add(video);
        } catch (e) {
          print('Error parsing video data: $e');
          continue; // Skip this video and continue with others
        }
      }
      
      // Create category objects
      final categories = videosByCategory.entries.map((entry) {
        return VideoCategory(
          id: entry.key.toLowerCase().replaceAll(' ', '-'),
          name: entry.key,
          slug: entry.key.toLowerCase().replaceAll(' ', '-'),
          order: 0,
          videos: entry.value,
        );
      }).toList();
      
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Video loading error: $e');
      setState(() {
        _error = 'Failed to load videos. Please check your internet connection.';
        _isLoading = false;
      });
    }
  }

  List<Video> get _filteredVideos {
    if (_selectedCategory == null) {
      return _categories.expand((cat) => cat.videos ?? <Video>[]).toList();
    }
    return _categories
        .firstWhere((cat) => cat.slug == _selectedCategory,
            orElse: () => VideoCategory(id: '', name: '', slug: '', order: 0, videos: []))
        .videos ?? [];
  }

  String _getFullImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath; // Already a full URL
    }
    
    // Convert relative path to absolute URL
    if (imagePath.startsWith('/uploads/')) {
      return 'http://localhost:3001$imagePath';
    }
    
    return imagePath; // Return as-is if format is unknown
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;
    
    // Responsive padding and font sizes
    final horizontalPadding = isDesktop ? 40.0 : isTablet ? 30.0 : 20.0;
    final titleFontSize = isDesktop ? 40.0 : isTablet ? 36.0 : 32.0;
    final subtitleFontSize = isDesktop ? 18.0 : 16.0;
    
    // Responsive grid columns
    final crossAxisCount = isDesktop ? 4 : isTablet ? 3 : 2;
    
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video Library',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Watch workout tutorials and fitness tips',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Category filter
                if (_categories.isNotEmpty)
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      children: [
                        _buildCategoryChip('All', null),
                        ..._categories.map((cat) => 
                          _buildCategoryChip(cat.name, cat.slug)
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Videos grid
                _isLoading
                    ? Container(
                        height: 300,
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : _error.isNotEmpty
                        ? Container(
                            height: 300,
                              child: Padding(
                                padding: EdgeInsets.all(horizontalPadding),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: AppColors.gray600,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _error,
                                      style: TextStyle(color: AppColors.gray400),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadVideos,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                        : _filteredVideos.isEmpty
                            ? Container(
                                height: 200,
                                child: Center(
                                  child: Text(
                                    'No videos available',
                                    style: TextStyle(color: AppColors.gray400),
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadVideos,
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.all(horizontalPadding),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: isTablet ? 0.8 : 0.75,
                                  ),
                                  itemCount: _filteredVideos.length,
                                  itemBuilder: (context, index) {
                                    final video = _filteredVideos[index];
                                    return _buildVideoCard(video);
                                  },
                                ),
                              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? slug) {
    final isSelected = _selectedCategory == slug;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? slug : null;
          });
        },
        backgroundColor: AppColors.gray800,
        selectedColor: AppColors.primary500,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.gray300,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary500 : AppColors.gray700,
        ),
      ),
    );
  }

  Widget _buildVideoCard(Video video) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _playVideo(video);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        color: AppColors.gray700,
                        image: video.thumbnail != null
                            ? DecorationImage(
                                image: NetworkImage(_getFullImageUrl(video.thumbnail!)),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  // Handle image loading errors gracefully
                                  print('Failed to load thumbnail: ${video.thumbnail}');
                                },
                              )
                            : null,
                      ),
                      child: video.thumbnail == null
                          ? Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 48,
                                color: AppColors.gray500,
                              ),
                            )
                          : null,
                    ),
                    // Play button overlay
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    // Duration badge
                    if (video.duration != null)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            video.formattedDuration,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Video info
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (video.category != null)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary500.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primary500.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              video.category?.name ?? 'Uncategorized',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.primary300,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playVideo(Video video) {
    // Check if video URL is valid
    if (video.url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video URL is not available'),
        ),
      );
      return;
    }
    
    // Check if it's a YouTube video
    if (video.url.contains('youtube.com') || video.url.contains('youtu.be')) {
      String? videoId = YoutubePlayer.convertUrlToId(video.url);
      
      if (videoId != null && videoId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YoutubeVideoPlayerScreen(
              videoId: videoId,
              title: video.title,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid YouTube video URL')),
        );
      }
    } else {
      // Handle local video files
      String videoUrl = video.url;
      
      // Convert relative path to absolute URL
      if (videoUrl.startsWith('/uploads/')) {
        videoUrl = 'http://localhost:3001$videoUrl';
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocalVideoPlayerScreen(
            videoUrl: videoUrl,
            title: video.title,
          ),
        ),
      );
    }
  }
}

class YoutubeVideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  const YoutubeVideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<YoutubeVideoPlayerScreen> createState() => _YoutubeVideoPlayerScreenState();
}

class _YoutubeVideoPlayerScreenState extends State<YoutubeVideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.primary500,
        ),
        builder: (context, player) {
          return Column(
            children: [
              player,
              Expanded(
                child: Container(
                  color: AppColors.gray900,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Playing from Video Library',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LocalVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const LocalVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<LocalVideoPlayerScreen> createState() => _LocalVideoPlayerScreenState();
}

class _LocalVideoPlayerScreenState extends State<LocalVideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      
      setState(() {
        _isLoading = false;
      });
      
      // Auto-play the video
      _controller.play();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load video: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Video Player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.gray400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: AppColors.gray400,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                    _error = null;
                                  });
                                  _initializeVideo();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary500,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_controller),
                            // Play/Pause overlay
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_controller.value.isPlaying) {
                                    _controller.pause();
                                  } else {
                                    _controller.play();
                                  }
                                });
                              },
                              child: AnimatedOpacity(
                                opacity: _controller.value.isPlaying ? 0.0 : 0.8,
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                            // Video controls
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black87, Colors.transparent],
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Progress bar
                                    VideoProgressIndicator(
                                      _controller,
                                      allowScrubbing: true,
                                      colors: VideoProgressColors(
                                        playedColor: AppColors.primary500,
                                        bufferedColor: Colors.white30,
                                        backgroundColor: Colors.white12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Time and controls
                                    Row(
                                      children: [
                                        // Current time / Total time
                                        ValueListenableBuilder(
                                          valueListenable: _controller,
                                          builder: (context, value, child) {
                                            final position = value.position;
                                            final duration = value.duration;
                                            return Text(
                                              '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            );
                                          },
                                        ),
                                        const Spacer(),
                                        // Fullscreen toggle
                                        IconButton(
                                          onPressed: () {
                                            // Toggle fullscreen (placeholder)
                                          },
                                          icon: const Icon(
                                            Icons.fullscreen,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          
          // Video info
          Expanded(
            child: Container(
              color: AppColors.gray900,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Playing from Video Library',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray400,
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }
}
