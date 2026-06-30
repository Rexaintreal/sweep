import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

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
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex.clamp(0, widget.images.length - 1);
  }


  AssetEntity get _currentAsset => widget.images[_currentIndex];

  String get _monthLabel {
    final parts = widget.monthKey.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);
    const names = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return '${names[month - 1]} $year';
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
        title: Text(
          _monthLabel,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ThumbnailStrip(
              images: widget.images,
              currentIndex: _currentIndex,
            ),
            _InfoRow(
              asset: _currentAsset,
              index: _currentIndex,
              total: widget.images.length,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AssetEntityImage(
                        _currentAsset,
                        isOriginal: false,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ActionButton(
                    icon: Icons.delete,
                    color: Colors.red,
                    label: 'Delete',
                    onTap: () {},
                  ),
                  _ActionButton(
                    icon: Icons.undo,
                    color: Colors.grey,
                    label: 'Undo',
                    onTap: () {},
                  ),
                  _ActionButton(
                    icon: Icons.fast_forward,
                    color: Colors.grey,
                    label: 'Skip',
                    onTap: () {},
                  ),
                  _ActionButton(
                    icon: Icons.check,
                    color: Colors.green,
                    label: '',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Text('PROCEED'),
                    label: const Icon(Icons.arrow_forward, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailStrip extends StatelessWidget {
  final List<AssetEntity> images;
  final int currentIndex;

  const _ThumbnailStrip({required this.images, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final isActive = index == currentIndex;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AssetEntityImage(
                images[index],
                isOriginal: false,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final AssetEntity asset;
  final int index;
  final int total;

  const _InfoRow({
    required this.asset,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 18),
            onPressed: () {},
          ),
          Expanded(
            child: Center(
              child: Text(
                asset.mimeType?.split('/').last.toUpperCase() ?? 'JPEG',
                style: TextStyle(
                  fontSize: 12,
                  // ignore: deprecated_member_use
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ),
          Text(
            '${index + 1}/$total',
            style: TextStyle(
              fontSize: 12,
              // ignore: deprecated_member_use
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // ignore: deprecated_member_use
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ],
    );
  }
}