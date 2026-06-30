import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'swipe_screen.dart';

class MonthGroup {
  final String label;
  final String key;
  final List<AssetEntity> assets;
  int swipedCount;

  MonthGroup({
    required this.label,
    required this.key,
    required this.assets,
    this.swipedCount = 0,
  });
}

class MonthSelectScreen extends StatefulWidget {
  const MonthSelectScreen({super.key});

  @override
  State<MonthSelectScreen> createState() => _MonthSelectScreenState();
}

class _MonthSelectScreenState extends State<MonthSelectScreen> {
  bool _loading = true;
  List<MonthGroup> _months = [];
  bool _hideCompleted = false;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _loadMonths();
  }

  Future<void> _loadMonths() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final int total = await albums[0].assetCountAsync;
    final List<AssetEntity> allAssets = await albums[0].getAssetListRange(
      start: 0,
      end: total,
    );

    final Map<String, List<AssetEntity>> grouped = {};
    for (final asset in allAssets) {
      final date = asset.createDateTime;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(asset);
    }

    final prefs = await SharedPreferences.getInstance();

    final List<MonthGroup> months = grouped.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final label = '${_monthNames[month - 1]} $year';
      final swiped = prefs.getInt('swiped_${entry.key}') ?? 0;
      return MonthGroup(
        label: label,
        key: entry.key,
        assets: entry.value,
        swipedCount: swiped,
      );
    }).toList();

    months.sort((a, b) => b.key.compareTo(a.key));

    setState(() {
      _months = months;
      _loading = false;
    });
  }

  List<MonthGroup> get _visibleMonths {
    if (!_hideCompleted) return _months;
    return _months.where((m) => m.swipedCount < m.assets.length).toList();
  }

  Future<void> _showFiltersDialog() async {
    bool tempHideCompleted = _hideCompleted;
    final result = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    value: tempHideCompleted,
                    onChanged: (val) {
                      setModalState(() => tempHideCompleted = val ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Hide completed'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(context).pop(tempHideCompleted),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _hideCompleted = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'SELECT MODE',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              // ignore: deprecated_member_use
                              .withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Month',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _showFiltersDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  // ignore: deprecated_member_use
                                  .withOpacity(0.4),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.tune, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Filters',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _visibleMonths.isEmpty
                      ? const Center(child: Text('No months to show.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _visibleMonths.length,
                          itemBuilder: (context, index) {
                            final group = _visibleMonths[index];
                            return _MonthTile(
                              group: group,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SwipeScreen(
                                      images: group.assets,
                                      monthKey: group.key,
                                      startIndex: group.swipedCount,
                                    ),
                                  ),
                                );
                                _loadMonths();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  final MonthGroup group;
  final VoidCallback onTap;

  const _MonthTile({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = group.assets.length;
    final swiped = group.swipedCount.clamp(0, total);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        // ignore: deprecated_member_use
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: AssetEntityImage(
                      group.assets.first,
                      isOriginal: false,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.label,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$swiped/$total',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              // ignore: deprecated_member_use
                              .withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : swiped / total,
                          minHeight: 4,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .outline
                              // ignore: deprecated_member_use
                              .withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward,
                  size: 18,
                  // ignore: deprecated_member_use
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}