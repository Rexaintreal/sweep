import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPermission = false;
  List<AssetEntity> _images = [];
  bool _loading = true;
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    final PermissionState result = await PhotoManager.requestPermissionExtend();
    setState(() {
      _hasPermission = result.hasAccess;
    });
    if (_hasPermission) {
      await _loadImages();
    }
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
    if (!_hasPermission) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sweep needs access to your photos.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _requestPermission,
                child: const Text('Grant Access'),
              ),
            ],
          ),
        ),
      );
    }

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