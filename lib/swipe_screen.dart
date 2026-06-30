import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwipeScreen extends StatefulWidget {
  final List<AssetEntity> images;
  final String monthKey;
  final int startIndex;

  const SwipeScreen({
    super.key,
    required this.images,
    required this.monthKey,
    this.startIndex = 0,
  });

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  late int _swipedCount;

  @override
  void initState() {
    super.initState();
    _swipedCount = widget.startIndex;
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('swiped_${widget.monthKey}', _swipedCount);
  }

  bool _onSwipe(
      int prevIndex, int? currentIndex, CardSwiperDirection direction) {
    if (direction == CardSwiperDirection.left) {
      debugPrint('Deleted: ${widget.images[prevIndex].id}');
    } else if (direction == CardSwiperDirection.right) {
      debugPrint('Kept: ${widget.images[prevIndex].id}');
    }
    _swipedCount++;
    _saveProgress();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No photos found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'SWEEP',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5),
        ),
      ),
      body: SafeArea(
        child: CardSwiper(
          controller: _swiperController,
          cardsCount: widget.images.length,
          initialIndex: widget.startIndex.clamp(0, widget.images.length - 1),
          onSwipe: _onSwipe,
          padding: const EdgeInsets.all(24),
          cardBuilder:
              (context, index, percentThresholdX, percentThresholdY) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AssetEntityImage(
                widget.images[index],
                isOriginal: false,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      ),
    );
  }
}