import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/guides.dart';
import '../../services/guide_notes.dart';
import '../guides/guide_page.dart';

/// A user-authored sketch, not an authoritative plant diagram.
class PositionMapPage extends StatefulWidget {
  const PositionMapPage({super.key, this.store});
  final GuideNotesStore? store;
  @override
  State<PositionMapPage> createState() => _PositionMapPageState();
}

class _PositionMapPageState extends State<PositionMapPage> {
  late final GuideNotesStore store =
      widget.store ?? SharedPreferencesGuideNotesStore();
  static const storageId = 'user-positions-map-v1';
  static const sites = ['ГП', 'ДКС', 'УПМТ'];
  String site = sites.first;
  List<Map<String, dynamic>> points = [];
  bool loading = true;
  bool busy = false;
  bool blocked = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await store.read(storageId);
      if (raw != null) {
        if (raw is! String) throw const FormatException();
        final data = jsonDecode(raw);
        if (data is! Map || data['version'] != 1 || data['points'] is! List) {
          throw const FormatException();
        }
        final parsed = <Map<String, dynamic>>[];
        for (final entry in data['points'] as List) {
          if (entry is! Map ||
              entry['site'] is! String ||
              !sites.contains(entry['site']) ||
              entry['name'] is! String ||
              entry['x'] is! num ||
              entry['y'] is! num ||
              (entry['x'] as num) < 0 ||
              (entry['x'] as num) > 1 ||
              (entry['y'] as num) < 0 ||
              (entry['y'] as num) > 1 ||
              (entry['guide'] != null && entry['guide'] is! String)) {
            throw const FormatException();
          }
          parsed.add(Map<String, dynamic>.from(entry));
        }
        points = parsed;
      }
    } catch (_) {
      blocked = true;
      error = 'Не удалось прочитать карту. Сохранённые данные не изменены.';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _add([
    Offset where = const Offset(.5, .5),
    Map<String, dynamic>? existing,
  ]) async {
    var input = existing?['name'] as String? ?? '';
    String? guideId = existing?['guide'] as String?;
    if (!guides.any((g) => g.id == guideId)) guideId = null;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(
            '${existing == null ? 'Новая позиция' : 'Изменить позицию'} · $site',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('position-name'),
                  initialValue: input,
                  onChanged: (value) => input = value,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Позиция или обозначение',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: guideId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Прибор (необязательно)',
                  ),
                  items: [
                    for (final guide in guides)
                      DropdownMenuItem(
                        value: guide.id,
                        child: Text(
                          guide.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => update(() => guideId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final name = input.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx, {
                  'site': site,
                  'name': name,
                  'guide': guideId,
                  'x': where.dx,
                  'y': where.dy,
                });
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    await _save(
      existing == null
          ? [...points, result]
          : [
              for (final point in points)
                identical(point, existing) ? result : point,
            ],
    );
  }

  Future<void> _save(List<Map<String, dynamic>> next) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (!await store.write(
        storageId,
        jsonEncode({'version': 1, 'points': next}),
      )) {
        throw StateError('write failed');
      }
      if (mounted) setState(() => points = next);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Не удалось сохранить изменение. Повторите попытку.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _showPoint(Map<String, dynamic> point) async {
    final matches = guides.where((g) => g.id == point['guide']);
    final guide = matches.isEmpty ? null : matches.first;
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(point['name'] as String),
        content: Text(
          guide == null ? 'Прибор не привязан.' : 'Прибор: ${guide.title}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('Удалить'),
          ),
          if (guide != null)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'open'),
              child: const Text('Открыть прибор'),
            ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'open' && guide != null) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => GuidePage(guide: guide)),
      );
    } else if (action == 'edit') {
      await _add(
        Offset((point['x'] as num).toDouble(), (point['y'] as num).toDouble()),
        point,
      );
    } else if (action == 'delete') {
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удалить позицию?'),
          content: Text(point['name'] as String),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Удалить'),
            ),
          ],
        ),
      );
      if (yes == true && mounted) {
        await _save(points.where((p) => !identical(p, point)).toList());
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Карта позиций')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Пользовательская схема. Позиции и их размещение добавляются вручную и требуют сверки с документацией объекта.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final value in sites)
                    ChoiceChip(
                      label: Text(value),
                      selected: site == value,
                      onSelected: busy
                          ? null
                          : (_) => setState(() => site = value),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (!blocked) ...[
                const Text(
                  'Нажмите на поле, чтобы выбрать место позиции; расположение условное.',
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    const height = 320.0;
                    return Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapUp: busy || blocked
                                    ? null
                                    : (d) => _add(
                                        Offset(
                                          (d.localPosition.dx / width).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                          (d.localPosition.dy / height).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            for (final point in points.where(
                              (p) => p['site'] == site,
                            ))
                              Positioned(
                                left:
                                    ((point['x'] as num).toDouble() * width -
                                            60)
                                        .clamp(0.0, width - 120),
                                top:
                                    ((point['y'] as num).toDouble() * height -
                                            24)
                                        .clamp(0.0, height - 48),
                                width: 120,
                                height: 48,
                                child: ActionChip(
                                  label: Text(
                                    point['name'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  avatar: const Icon(Icons.place, size: 18),
                                  onPressed: busy
                                      ? null
                                      : () => _showPoint(point),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('add-position'),
                  onPressed: busy || blocked ? null : () => _add(),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Добавить позицию'),
                ),
                if (points.any((p) => p['site'] == site)) ...[
                  const SizedBox(height: 12),
                  const Text('Позиции площадки'),
                  for (final point in points.where((p) => p['site'] == site))
                    ListTile(
                      title: Text(point['name'] as String),
                      leading: const Icon(Icons.place_outlined),
                      onTap: busy ? null : () => _showPoint(point),
                    ),
                ],
              ],
            ],
          ),
  );
}
