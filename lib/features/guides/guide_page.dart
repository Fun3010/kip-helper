import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../data/guide_procedures.dart';
import '../manuals/manual_library_page.dart';
import 'procedure_list_page.dart';
import '../notes/guide_notes_page.dart';
import '../../services/open_source.dart';
import '../../services/quick_access.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/quick_access_notice.dart';
import '../../widgets/su1s_contacts.dart';
import '../../widgets/guide_illustration.dart';
import '../../widgets/guide_evidence.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({
    super.key,
    required this.guide,
    this.quickAccess,
    this.initialQuery = '',
  });
  final InstrumentGuide guide;
  final QuickAccessController? quickAccess;
  final String initialQuery;
  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  late final _search = TextEditingController(text: widget.initialQuery);
  bool _expandAll = false;
  String get _query => _search.text.trim().toLowerCase();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<int> _paragraphOrder(GuideSection section) {
    final indices = List.generate(section.paragraphs.length, (i) => i);
    if (_query.isEmpty) return indices;
    final matched = indices
        .where(
          (i) =>
              section.fieldEntries[i]?.any((entry) => entry.matches(_query)) ??
              false,
        )
        .toList();
    // Bring the code to the top without hiding context, exclusions or warnings.
    return [...matched, ...indices.where((i) => !matched.contains(i))];
  }

  @override
  Widget build(BuildContext context) {
    final guide = widget.guide;
    final sections = guide.sections
        .where((section) => section.matches(_query))
        .toList();
    final colors = Theme.of(context).colorScheme;
    final illustrations = guide.illustrations
        .where((item) => item.matches(_query))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(guide.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.quickAccess != null)
            FavoriteButton(guide: guide, controller: widget.quickAccess!),
          IconButton(
            tooltip: _expandAll ? 'Свернуть всё' : 'Развернуть всё',
            onPressed: () => setState(() => _expandAll = !_expandAll),
            icon: Icon(_expandAll ? Icons.unfold_less : Icons.unfold_more),
          ),
          PopupMenuButton<String>(
            tooltip: 'Дополнительные действия',
            onSelected: (action) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => action == 'manuals'
                    ? ManualLibraryPage(
                        guideId: guide.id,
                        guideTitle: guide.title,
                      )
                    : GuideNotesPage(
                        guideId: guide.id,
                        guideTitle: guide.title,
                      ),
              ),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'notes', child: Text('Личные заметки')),
              PopupMenuItem(value: 'manuals', child: Text('PDF этого прибора')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (widget.quickAccess != null)
                  QuickAccessNotice(controller: widget.quickAccess!),
                Text(
                  guide.subtitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    guide.scope,
                    style: TextStyle(
                      color: colors.onSecondaryContainer,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (proceduresForGuide(guide.id).isNotEmpty) ...[
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.checklist_outlined),
                    label: const Text('Настройка по шагам'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProcedureListPage(guide: guide),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Найти настройку или код',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Очистить поиск',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(_search.clear),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                if (guide.id == 'su1s' && _query.isEmpty)
                  const Card(
                    child: ExpansionTile(
                      title: Text('Схема контактов · интерактивно'),
                      childrenPadding: EdgeInsets.all(16),
                      children: [Su1sContacts()],
                    ),
                  ),
                if (illustrations.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      key: ValueKey('illustrations-$_query-$_expandAll'),
                      initiallyExpanded: _query.isNotEmpty || _expandAll,
                      leading: const Icon(Icons.photo_library_outlined),
                      title: Text(
                        'Иллюстрации и схемы · ${illustrations.length}',
                      ),
                      subtitle: const Text(
                        'Внешний вид, управление, подключение',
                      ),
                      childrenPadding: const EdgeInsets.all(12),
                      children: [
                        for (final illustration in illustrations)
                          GuideIllustrationCard(illustration: illustration),
                      ],
                    ),
                  ),
                if (sections.isEmpty && illustrations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Ничего не найдено. Попробуйте название или часть кода.',
                    ),
                  ),
                for (final section in sections)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      key: ValueKey(
                        '${guide.id}-${section.title}-${_query.isNotEmpty}-$_expandAll',
                      ),
                      initiallyExpanded: _query.isNotEmpty || _expandAll,
                      title: Text(
                        section.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      children: [
                        if (section.notice != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              section.notice!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        for (final paragraphIndex in _paragraphOrder(section))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (section.fieldEntries[paragraphIndex]
                                    case final entries?) ...[
                                  for (final entry in entries.where(
                                    (entry) =>
                                        _query.isEmpty ||
                                        entry.matches(_query) ||
                                        !entries.any(
                                          (item) => item.matches(_query),
                                        ),
                                  ))
                                    GuideFieldEntryCard(entry: entry),
                                ] else
                                  SelectableText(
                                    section.paragraphs[paragraphIndex],
                                    style: const TextStyle(height: 1.55),
                                  ),
                                for (final evidence in section.evidenceFor(
                                  paragraphIndex,
                                ))
                                  GuideEvidenceCard(
                                    evidence: evidence,
                                    source: guide.sourceByKey(
                                      evidence.sourceKey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Все документы и источники'),
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      guide.sources.isEmpty
                          ? 'Для точной инструкции требуется руководство установленного исполнения.'
                          : 'Текст и иллюстрации доступны без сети. Для документов указаны файл и страницы. Веб-ссылки открываются в браузере. Свои PDF можно добавить через меню «PDF этого прибора»; выбранная вами связь не подтверждает модель и редакцию документа.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    for (final source in guide.sources)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: source.url == null
                            ? ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.description_outlined),
                                title: Text(source.title),
                                subtitle: Text(source.document ?? ''),
                              )
                            : OutlinedButton.icon(
                                onPressed: () =>
                                    openSource(context, source.url!),
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(source.title),
                                ),
                              ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
