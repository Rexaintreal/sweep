import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'clarification_screen.dart';
import 'swipe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPermission = false;
  bool _denied = false;
  int _photoCount = 0;
  bool _loading = true;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final PermissionState result = await PhotoManager.requestPermissionExtend();
    if (result.hasAccess) {
      setState(() {
        _hasPermission = true;
        _denied = false;
      });
      await _loadCount();
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
      await _loadCount();
    } else {
      setState(() {
        _hasPermission = false;
        _denied = true;
      });
    }
  }

  Future<void> _loadCount() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final count = await albums[0].assetCountAsync;
    setState(() {
      _photoCount = count;
      _loading = false;
    });
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
                    // ignore: deprecated_member_use
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'None of your files ever leave your device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    // ignore: deprecated_member_use
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text(
          'SWEEP',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5),
        ),
      ),
      body: Column(
        children: [
          if (!_bannerDismissed)
            Container(
              width: double.infinity,
              // ignore: deprecated_member_use
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.tertiary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The app can only delete pictures from your local device and not from cloud backups like Google Photos.',
                          style: TextStyle(
                            fontSize: 13,
                            // ignore: deprecated_member_use
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ClarificationScreen()),
                            );
                            setState(() => _bannerDismissed = true);
                          },
                          child: Text(
                            'Learn more',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sd_card_outlined,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Discovered',
                  style: TextStyle(
                    fontSize: 16,
                    // ignore: deprecated_member_use
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_photoCount',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'photos',
                  style: TextStyle(
                    fontSize: 15,
                    // ignore: deprecated_member_use
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SwipeScreen()),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Start cleaning'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}