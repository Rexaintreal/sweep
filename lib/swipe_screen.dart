import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  List<AssetEntity> _images = [];
  bool _loading = true;
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final List<AssetEntity> images = await albums[0].getAssetListRange(
      start: 0,
      end: 100,
    );
    setState(() {
      _images = images;
      _loading = false;
    });
  }

  bool _onSwipe(int prevIndex, int? currentIndex, CardSwiperDirection direction) {
    if (direction == CardSwiperDirection.left) {
      debugPrint('Deleted: ${_images[prevIndex].id}');
    } else if (direction == CardSwiperDirection.right) {
      debugPrint('Kept: ${_images[prevIndex].id}');
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_images.isEmpty) {
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
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5),
        ),
      ),
      body: SafeArea(
        child: CardSwiper(
          controller: _swiperController,
          cardsCount: _images.length,
          onSwipe: _onSwipe,
          padding: const EdgeInsets.all(24),
          cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AssetEntityImage(
                _images[index],
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