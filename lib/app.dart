import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/guides.dart';
import 'features/calculators/rtd_calculator.dart';
import 'features/calculators/signal_calculator.dart';
import 'features/calculators/unit_converter.dart';
import 'features/guides/guide_page.dart';
import 'services/open_source.dart';

class KipHelperApp extends StatelessWidget {
  const KipHelperApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'КИП · Справочник',
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    debugShowCheckedModeBanner: false,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    home: const HomePage(),
  );

  ThemeData _theme(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF006B62),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant.withValues(alpha: .5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLow,
        indicatorColor: colors.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: colors.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(alpha: .65),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: .55)),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selected = 0;
  String? _category;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'КИП / помощник',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 20),
          child: Tooltip(
            message: 'Справочник и расчёты работают без интернета',
            child: Icon(Icons.offline_bolt_outlined),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: switch (_selected) {
            0 => _library(context),
            1 => _calculators(context),
            _ => _about(context),
          },
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selected,
      onDestinationSelected: (value) => setState(() => _selected = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Справочник',
        ),
        NavigationDestination(
          icon: Icon(Icons.calculate_outlined),
          selectedIcon: Icon(Icons.calculate),
          label: 'Расчёты',
        ),
        NavigationDestination(
          icon: Icon(Icons.info_outline),
          selectedIcon: Icon(Icons.info),
          label: 'О приложении',
        ),
      ],
    ),
  );

  Widget _library(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = guides
        .where(
          (guide) =>
              guide.matches(query) &&
              (_category == null || guide.category == _category),
        )
        .toList();
    final categories = guides.map((guide) => guide.category).toSet().toList();
    return ListView(
      key: const PageStorageKey('library'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Ваш рабочий справочник',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '${guides.length} приборов · инструкции, схемы и диагностика',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Прибор или код ошибки',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Очистить поиск',
                    onPressed: () => setState(_search.clear),
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Все'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
              ),
              for (final category in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (selected) =>
                        setState(() => _category = selected ? category : null),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                query.isEmpty && _category == null
                    ? 'Каталог приборов'
                    : 'Найдено: ${filtered.length}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${filtered.length}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Ничего не найдено. Попробуйте «СОКРАТ», «А01» или «уровень».',
            ),
          ),
        for (final guide in filtered)
          _featureCard(
            context,
            title: guide.title,
            eyebrow: guide.category,
            subtitle: guide.subtitle,
            imageAsset:
                guide.thumbnailAsset ??
                (guide.illustrations.isEmpty
                    ? null
                    : guide.illustrations.first.asset),
            icon: switch (guide.category) {
              'Позиционеры' => Icons.tune,
              'Уровень' => Icons.water_drop_outlined,
              'Газоанализ' => Icons.air,
              'Влажность' => Icons.grain,
              _ => Icons.settings_input_component,
            },
            onTap: () => _open(GuidePage(guide: guide)),
          ),
      ],
    );
  }

  Widget _calculators(BuildContext context) => ListView(
    key: const PageStorageKey('calculators'),
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
    children: [
      _hero(
        context,
        'Инженерные расчёты',
        'Единицы, характеристики датчиков и токовая петля',
      ),
      const SizedBox(height: 24),
      _featureCard(
        context,
        title: 'Термосопротивление',
        subtitle: 'Pt, П, М · °C / Ом / 4–20 мА',
        icon: Icons.sensors,
        onTap: () => _open(const RtdCalculator()),
      ),
      _featureCard(
        context,
        title: 'Сигнал 4–20 мА',
        subtitle: 'Ток и физическая величина',
        icon: Icons.electrical_services,
        onTap: () => _open(const SignalCalculator()),
      ),
      _featureCard(
        context,
        title: 'Температура',
        subtitle: '°C · °F · K',
        icon: Icons.thermostat_outlined,
        onTap: () => _open(const UnitConverter(pressure: false)),
      ),
      _featureCard(
        context,
        title: 'Давление',
        subtitle: 'Па · бар · атм · кгс/см² и другие',
        icon: Icons.speed,
        onTap: () => _open(const UnitConverter(pressure: true)),
      ),
    ],
  );

  Widget _about(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _hero(
        context,
        'КИП / помощник',
        'Версия 1.2.1\nОфлайн-справочник для работы с приборами',
      ),
      const SizedBox(height: 24),
      Text(
        'Что работает без сети',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      const Text(
        'Все карточки, поиск и калькуляторы хранятся в приложении. Ссылки на полные руководства открываются отдельно в браузере.',
        style: TextStyle(height: 1.6),
      ),
      const SizedBox(height: 24),
      Text(
        'Применимость данных',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      const Text(
        'У каждой карточки указано исполнение и источник. Перед подключением и изменением настроек сверяйте модель, редакцию паспорта и схему конкретного прибора. Подтверждённые для одного исполнения данные не переносятся автоматически на другое.',
        style: TextStyle(height: 1.6),
      ),
      const SizedBox(height: 24),
      Text(
        'Расчётные характеристики',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      const Text(
        'Pt: α = 0,00385; П: α = 0,00391; М: α = 0,00428. Используется номинальная характеристика, без погрешности датчика и сопротивления проводов. Выход 4–20 мА рассчитан для линейного преобразователя.',
        style: TextStyle(height: 1.6),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => openSource(
          context,
          'https://temperatures.ru/pdf/GOST/gost6651-2009.pdf',
        ),
        icon: const Icon(Icons.open_in_new),
        label: const Text('ГОСТ 6651–2009 · текст стандарта'),
      ),
      const SizedBox(height: 20),
      const Text(
        'Приложение не требует регистрации и не отправляет измерения на сервер.',
      ),
    ],
  );

  Widget _hero(BuildContext context, String title, String subtitle) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(color: colors.onPrimaryContainer, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    String? imageAsset,
    String? eyebrow,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (imageAsset == null)
              Container(
                width: 52,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 26,
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Colors.white,
                  width: 52,
                  height: 60,
                  child: Image.asset(imageAsset, fit: BoxFit.contain),
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow != null) ...[
                    Text(
                      eyebrow,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    ),
  );
  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
