import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPermission = false;  
  List<AssetEntity> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _requestPermission();
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
      end: 100
    );

    setState(() {
      _images = images;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sweep needs acess to your photos.'),
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
        body: Center(child: Text('No photos found')),
      );
    }

    return Scaffold(
      body: Center(
        child: Text('${_images.length} photos found.'),
      ),
    );
  }
}