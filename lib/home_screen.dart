import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPermission = false;
  bool _denied = false;
  List<AssetEntity> _images = [];
  bool _loading = true;
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final PermissionState result = await PhotoManager.requestPermissionExtend();
    if (result.hasAccess) {
      setState(() {
        _hasPermission = true;
        _denied = false;
      });
      await _loadImages();
    } else {
      setState(() {
        _hasPermission = false;
        _denied = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final PermissionState result = await PhotoManager.requestPermissionExtend();
    if (result.hasAccess) {
      setState(() {
        _hasPermission = true;
        _denied = false;
      });
      await _loadImages();
    } else {
      setState(() {
        _hasPermission = false;
        _denied = true;
      });
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

  bool _onSwipe(
      int prevIndex, int? currentIndex, CardSwiperDirection direction) {
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  'We need your permission',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Icon(
                  Icons.photo_library_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const Spacer(),
                Text(
                  'Sweep needs to read your photos to show them to you inside the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        // ignore: deprecated_member_use
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'None of your files ever leave your device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        // ignore: deprecated_member_use
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 40),
                if (_denied)
                  Column(
                    children: [
                      Text(
                        'Permission was denied. Please enable it in Settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => PhotoManager.openSetting(),
                          child: const Text('Open Settings'),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _requestPermission,
                      child: const Text('Request permission'),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
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