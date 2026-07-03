import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
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
  late int _currentIndex;
  final List<int> _history = [];
  final Map<int, String> _decisions = {};
  bool _deleting = false;

  final GlobalKey<_SwipeableCardState> _cardKey = GlobalKey();

  List<String> get _pendingDeleteIds {
    return _decisions.entries
        .where((e) => e.value == 'delete')
        .map((e) => widget.images[e.key].id)
        .toList();
  }

  Future<List<String>> _performDelete() async {
    final ids = _pendingDeleteIds;
    if (ids.isEmpty) return [];
    setState(() => _deleting = true);
    List<String> result = [];
    try {
      result = await PhotoManager.editor.deleteWithIds(ids);
    } catch (e) {
      result = [];
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex.clamp(0, widget.images.length - 1);
  }

  void _commitDecision(String decision) {
    if (_currentIndex >= widget.images.length) return;
    setState(() {
      _decisions[_currentIndex] = decision;
      _history.add(_currentIndex);
      _currentIndex++;
    });
    _saveProgress();
    if (_currentIndex >= widget.images.length) {
      _showDoneDialog();
    }
  }

  void _decide(String decision) {
    _cardKey.currentState?.flyOff(decision);
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      final lastIndex = _history.removeLast();
      _decisions.remove(lastIndex);
      _currentIndex = lastIndex;
    });
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = _currentIndex.clamp(0, widget.images.length);
    await prefs.setInt('swiped_${widget.monthKey}', clamped);
  }

  void _showDoneDialog() {
    final pendingCount = _pendingDeleteIds.length;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('All done'),
        content: Text(
          pendingCount > 0
              ? 'You\'ve gone through all ${widget.images.length} photos. '
                  '$pendingCount marked for deletion. Delete them now?'
              : 'You\'ve gone through all ${widget.images.length} photos in this month.',
        ),
        actions: [
          if (pendingCount > 0)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Not now'),
            ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              if (pendingCount > 0) {
                final deleted = await _performDelete();
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      deleted.length == pendingCount
                          ? 'Deleted ${deleted.length} photos'
                          : 'Deleted ${deleted.length} of $pendingCount photos',
                    ),
                  ),
                );
              }
              if (!mounted) return;
              navigator.pop();
            },
            child: Text(
              pendingCount > 0 ? 'Delete $pendingCount photos' : 'Back to months',
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _handleExit() async {
    final pending = _pendingDeleteIds.length;
    if (pending == 0) return true;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pending deletions'),
        content: Text(
          '$pending photo(s) are marked for deletion. Delete them before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard marks'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete now'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _performDelete();
    }
    return true;
  }

  Future<void> _showFileDetail(AssetEntity asset) async {
    final file = await asset.file;
    final bytes = file != null ? await file.length() : 0;
    final sizeStr = bytes > 1024 * 1024
        ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(bytes / 1024).toStringAsFixed(0)} KB';
    final date = asset.createDateTime;
    final dateStr =
        '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('File details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _DetailRow(
                  icon: Icons.image_outlined,
                  label: 'Filename',
                  value: asset.title ?? '—'),
              _DetailRow(
                  icon: Icons.straighten,
                  label: 'Resolution',
                  value: '${asset.width} × ${asset.height}'),
              _DetailRow(
                  icon: Icons.data_usage_outlined,
                  label: 'Size',
                  value: sizeStr),
              _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Date taken',
                  value: dateStr),
              _DetailRow(
                  icon: Icons.photo_camera_outlined,
                  label: 'Type',
                  value: asset.mimeType?.split('/').last.toUpperCase() ?? '—'),
            ],
          ),
        ),
      ),
    );
  }

  AssetEntity get _currentAsset =>
      widget.images[_currentIndex.clamp(0, widget.images.length - 1)];

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

    if (_currentIndex >= widget.images.length) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canExit = await _handleExit();
        // ignore: use_build_context_synchronously
        if (canExit && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
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
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _ThumbnailStrip(
                    images: widget.images,
                    currentIndex: _currentIndex,
                    decisions: _decisions,
                  ),
                  _InfoRow(
                    asset: _currentAsset,
                    index: _currentIndex,
                    total: widget.images.length,
                    onInfo: () => _showFileDetail(_currentAsset),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SwipeableCard(
                        key: ValueKey(_currentIndex),
                        cardKey: _cardKey,
                        asset: _currentAsset,
                        onDecide: _commitDecision,
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
                          onTap: () => _decide('delete'),
                        ),
                        _ActionButton(
                          icon: Icons.undo,
                          color: Colors.grey,
                          label: 'Undo',
                          onTap: _undo,
                        ),
                        _ActionButton(
                          icon: Icons.fast_forward,
                          color: Colors.grey,
                          label: 'Skip',
                          onTap: () => _decide('skip'),
                        ),
                        _ActionButton(
                          icon: Icons.check,
                          color: Colors.green,
                          label: '',
                          onTap: () => _decide('keep'),
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
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Text('PROCEED'),
                          label: const Icon(Icons.arrow_forward, size: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_deleting)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailStrip extends StatefulWidget {
  final List<AssetEntity> images;
  final int currentIndex;
  final Map<int, String> decisions;

  const _ThumbnailStrip({
    required this.images,
    required this.currentIndex,
    required this.decisions,
  });

  @override
  State<_ThumbnailStrip> createState() => _ThumbnailStripState();
}

class _ThumbnailStripState extends State<_ThumbnailStrip> {
  final ScrollController _scrollController = ScrollController();

  static const double _itemWidth = 48;
  static const double _itemMargin = 8;
  static const double _horizontalPadding = 16;

  @override
  void didUpdateWidget(_ThumbnailStrip old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
    }
  }

  void _scrollToActive() {
    if (!_scrollController.hasClients) return;
    final itemStart =
        _horizontalPadding + widget.currentIndex * (_itemWidth + _itemMargin);
    final itemCenter = itemStart + _itemWidth / 2;
    final viewportCenter = _scrollController.position.viewportDimension / 2;
    final target = (itemCenter - viewportCenter)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding, vertical: 8),
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          final isActive = index == widget.currentIndex;
          final decision = widget.decisions[index];

          return Container(
            margin: const EdgeInsets.only(right: _itemMargin),
            width: _itemWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        blurRadius: 6,
                      )
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AssetEntityImage(
                    widget.images[index],
                    isOriginal: false,
                    fit: BoxFit.cover,
                  ),
                  if (decision != null)
                    Container(
                      color: switch (decision) {
                        // ignore: deprecated_member_use
                        'delete' => Colors.red.withOpacity(0.55),
                        // ignore: deprecated_member_use
                        'keep' => Colors.green.withOpacity(0.45),
                        // ignore: deprecated_member_use
                        'skip' => Colors.grey.withOpacity(0.5),
                        _ => Colors.transparent,
                      },
                      child: Center(
                        child: switch (decision) {
                          'delete' =>
                            const Icon(Icons.close, color: Colors.white, size: 16),
                          'keep' =>
                            const Icon(Icons.check, color: Colors.white, size: 16),
                          'skip' =>
                            const Icon(Icons.fast_forward, color: Colors.white, size: 14),
                          _ => null,
                        },
                      ),
                    ),
                ],
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
  final VoidCallback onInfo;

  const _InfoRow({
    required this.asset,
    required this.index,
    required this.total,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 18),
            onPressed: onInfo,
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

class _SwipeableCard extends StatefulWidget {
  final AssetEntity asset;
  final void Function(String decision) onDecide;
  final GlobalKey<_SwipeableCardState> cardKey;

  const _SwipeableCard({
    super.key,
    required this.cardKey,
    required this.asset,
    required this.onDecide,
  });

  @override
  State<_SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  bool _animatingOff = false;

  late final AnimationController _flyController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late Animation<Offset> _flyAnimation;

  @override
  void dispose() {
    _flyController.dispose();
    super.dispose();
  }

  void flyOff(String decision) {
    if (_animatingOff) return;
    _animatingOff = true;

    final screenWidth = MediaQuery.of(context).size.width;
    final isRight = decision == 'keep';
    final targetX = isRight ? screenWidth * 1.4 : -screenWidth * 1.4;

    _flyAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy - 60),
    ).animate(CurvedAnimation(
      parent: _flyController,
      curve: Curves.easeIn,
    ));

    _flyController.forward().then((_) {
      if (mounted) widget.onDecide(decision);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_animatingOff) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_animatingOff) return;
    final threshold = MediaQuery.of(context).size.width * 0.28;
    if (_dragOffset.dx > threshold) {
      flyOff('keep');
    } else if (_dragOffset.dx < -threshold) {
      flyOff('delete');
    } else {
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final offset = _animatingOff ? _flyAnimation.value : _dragOffset;
    final angle = offset.dx / 300;
    final showDelete = offset.dx < -20;
    final showKeep = offset.dx > 20;
    final stampOpacity = (offset.dx.abs() / 100).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _flyController,
      builder: (context, child) {
        return GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform(
            transform: Matrix4.identity()
              ..translate(offset.dx, offset.dy)
              ..rotateZ(angle),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AssetEntityImage(
              widget.asset,
              isOriginal: false,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          if (showDelete)
            Positioned(
              top: 24,
              left: 24,
              child: Opacity(
                opacity: stampOpacity,
                child: Transform.rotate(
                  angle: -0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'DELETE',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (showKeep)
            Positioned(
              top: 24,
              right: 24,
              child: Opacity(
                opacity: stampOpacity,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'KEEP',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _FullscreenViewer(asset: widget.asset),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenViewer extends StatelessWidget {
  final AssetEntity asset;
  const _FullscreenViewer({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: AssetEntityImage(
                asset,
                isOriginal: true,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              // ignore: deprecated_member_use
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}