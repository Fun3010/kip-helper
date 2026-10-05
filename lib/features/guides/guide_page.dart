import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../services/open_source.dart';
import '../../services/quick_access.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/quick_access_notice.dart';
import '../../widgets/su1s_contacts.dart';
import '../../widgets/guide_illustration.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key, required this.guide, this.quickAccess});
  final InstrumentGuide guide;
  final QuickAccessController? quickAccess;
  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final _search = TextEditingController();
  bool _expandAll = false;
  String get _query => _search.text.trim().toLowerCase();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _evidenceStateLabel(GuideEvidenceState state) => switch (state) {
    GuideEvidenceState.verified => 'Проверено по источнику',
    GuideEvidenceState.locatorPending =>
      'Источник подтверждён · страницу уточнить',
    GuideEvidenceState.workingChecklist =>
      'Рабочий чек-лист · не дословная процедура',
    GuideEvidenceState.needsVisualCheck => 'Скан · нужна визуальная сверка',
  };

  IconData _evidenceStateIcon(GuideEvidenceState state) => switch (state) {
    GuideEvidenceState.verified => Icons.verified_outlined,
    GuideEvidenceState.locatorPending => Icons.manage_search_outlined,
    GuideEvidenceState.workingChecklist => Icons.fact_check_outlined,
    GuideEvidenceState.needsVisualCheck => Icons.visibility_outlined,
  };

  Widget _evidenceRow(
    BuildContext context,
    InstrumentGuide guide,
    GuideEvidence evidence,
  ) {
    final source = guide.sourceByKey(evidence.sourceKey);
    final colors = Theme.of(context).colorScheme;
    final canOpen = source?.url != null;
    final sourceTitle = source?.title ?? evidence.sourceKey;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canOpen ? () => openSource(context, source!.url!) : null,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _evidenceStateIcon(evidence.state),
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _evidenceStateLabel(evidence.state),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$sourceTitle · ${evidence.locator}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      if (evidence.note != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          evidence.note!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (canOpen) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
        title: Text(guide.title),
        actions: [
          if (widget.quickAccess != null)
            FavoriteButton(guide: guide, controller: widget.quickAccess!),
          IconButton(
            tooltip: _expandAll ? 'Свернуть всё' : 'Развернуть всё',
            onPressed: () => setState(() => _expandAll = !_expandAll),
            icon: Icon(_expandAll ? Icons.unfold_less : Icons.unfold_more),
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
                        for (
                          var paragraphIndex = 0;
                          paragraphIndex < section.paragraphs.length;
                          paragraphIndex++
                        )
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText(
                                  section.paragraphs[paragraphIndex],
                                  style: const TextStyle(height: 1.55),
                                ),
                                for (final evidence in section.evidenceFor(
                                  paragraphIndex,
                                ))
                                  _evidenceRow(context, guide, evidence),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Источники',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  guide.sources.isEmpty
                      ? 'Для точной инструкции требуется руководство установленного исполнения.'
                      : 'Текст и иллюстрации доступны без сети. Для локальных документов указаны файл и страницы. Веб-ссылки открываются в браузере; полные PDF в приложение не включены.',
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
                            onPressed: () => openSource(context, source.url!),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(source.title),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
