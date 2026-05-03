import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/story.dart';
import '../../services/story_service.dart';
import '../../widgets/story_viewer.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({Key? key}) : super(key: key);

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final StoryService _storyService = StoryService();
  List<StoryGroup> _storyGroups = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final storyGroups = await _storyService.getStoriesGroupedByCategory();
      
      setState(() {
        _storyGroups = storyGroups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load stories: $e';
        _isLoading = false;
      });
    }
  }

  void _openStory(StoryGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoryViewer(
          stories: group.stories,
          categoryName: group.category.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('stories_title'.tr()),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStories,
              child: Text('common_retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_storyGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('stories_no_stories'.tr(), style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStories,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: _storyGroups.length,
          itemBuilder: (context, index) {
            final group = _storyGroups[index];
            return _buildStoryItem(group);
          },
        ),
      ),
    );
  }

  Widget _buildStoryItem(StoryGroup group) {
    final firstStory = group.stories.first;
    final categoryColor = group.category.color != null
        ? Color(int.parse(group.category.color!.replaceFirst('#', '0xff')))
        : Colors.primaries[group.category.name.hashCode % Colors.primaries.length];

    return GestureDetector(
      onTap: () => _openStory(group),
      child: Column(
        children: [
          // Story thumbnail with gradient ring
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [categoryColor, categoryColor.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: EdgeInsets.all(3),
              child: ClipOval(
                child: firstStory.mediaType == 'IMAGE'
                    ? Image.network(
                        firstStory.mediaUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: categoryColor.withOpacity(0.2),
                            child: Icon(Icons.photo, color: categoryColor),
                          );
                        },
                      )
                    : Container(
                        color: categoryColor.withOpacity(0.2),
                        child: Icon(Icons.play_circle_outline, color: categoryColor, size: 32),
                      ),
              ),
            ),
          ),
          SizedBox(height: 8),
          // Category name
          Text(
            group.category.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
