import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const KipHelperApp());
}

class KipHelperApp extends StatelessWidget {
  const KipHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KIP Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent, brightness: Brightness.light),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent, brightness: Brightness.dark),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[900],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KIP Helper'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.calculate), text: 'Калькуляторы'),
            Tab(icon: Icon(Icons.book), text: 'Siemens SIPART'),
            Tab(icon: Icon(Icons.bolt), text: 'РЭМТЭК'),
            Tab(icon: Icon(Icons.shield), text: 'СОКРАТ'),  // НОВАЯ ВКЛАДКА
            Tab(icon: Icon(Icons.water_drop_outlined), text: 'СУ-1С'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CalculatorsGroup(),
          SiemensGuide(),
          RemTekGuide(),
          SokratGuide(),  // НОВЫЙ ВИДЖЕТ
          Su1sGuide(),
        ],
      ),
    );
  }
}

// ================= ГРУППА КАЛЬКУЛЯТОРОВ (ИСПРАВЛЕНО ПЕРЕПОЛНЕНИЕ) =================
class CalculatorsGroup extends StatelessWidget {
  const CalculatorsGroup({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        const TabBar(labelColor: Colors.blue, unselectedLabelColor: Colors.grey, tabs: [
          Tab(text: 'Температура'), Tab(text: 'Давление'), Tab(text: 'Сопротивление'),
        ]),
        const Expanded(child: TabBarView(children: [
          TemperatureConverter(), PressureConverter(), ResistanceConverter(),
        ])),
      ]),
    );
  }
}

// --- Конвертер Температуры (Адаптивный) ---
class TemperatureConverter extends StatefulWidget {
  const TemperatureConverter({super.key});
  @override State<TemperatureConverter> createState() => _TemperatureConverterState();
}
class _TemperatureConverterState extends State<TemperatureConverter> {
  final TextEditingController _controller = TextEditingController();
  String _fromUnit = 'C'; String _toUnit = 'F'; String _result = '0';
  final List<Map<String, String>> units = [
    {'code': 'C', 'name': '°C'}, {'code': 'F', 'name': '°F'}, {'code': 'K', 'name': 'K'},
  ];
  void _calculate() {
    if (_controller.text.isEmpty) { setState(() => _result = '---'); return; }
    double input = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;
    double tempInC = switch (_fromUnit) { 'C' => input, 'F' => (input - 32) * 5 / 9, 'K' => input - 273.15, _ => input };
    double output = switch (_toUnit) { 'C' => tempInC, 'F' => (tempInC * 9 / 5) + 32, 'K' => tempInC + 273.15, _ => tempInC };
    setState(() => _result = output.toStringAsFixed(2));
  }
  @override Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Конвертер температуры', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(controller: _controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Значение', prefixIcon: Icon(Icons.numbers)), onChanged: (_) => _calculate()),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(initialValue: _fromUnit, decoration: const InputDecoration(labelText: 'Из'), items: units.map((u) => DropdownMenuItem(value: u['code'], child: Text(u['name']!))).toList(), onChanged: (v) { if(v!=null){setState((){_fromUnit=v;_calculate();});} })),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward)),
          Expanded(child: DropdownButtonFormField<String>(initialValue: _toUnit, decoration: const InputDecoration(labelText: 'В'), items: units.map((u) => DropdownMenuItem(value: u['code'], child: Text(u['name']!))).toList(), onChanged: (v) { if(v!=null){setState((){_toUnit=v;_calculate();});} })),
        ]),
        const SizedBox(height: 24),
        _ResultCard(result: _result, unit: _toUnit == 'C' ? '°C' : (_toUnit == 'F' ? '°F' : 'K'), context: context),
      ]),
    );
  }
}

// --- Конвертер Давления (Адаптивный) ---
class PressureConverter extends StatefulWidget {
  const PressureConverter({super.key});
  @override State<PressureConverter> createState() => _PressureConverterState();
}
class _PressureConverterState extends State<PressureConverter> {
  final TextEditingController _controller = TextEditingController();
  String _fromUnit = 'bar'; String _toUnit = 'kgf_cm2'; String _result = '0';
  final Map<String, double> toPa = {'Pa': 1, 'kPa': 1000, 'MPa': 1000000, 'bar': 100000, 'atm': 101325, 'mmHg': 133.322, 'mmH2O': 9.80665, 'kgf_cm2': 98066.5};
  final List<Map<String, String>> units = [
    {'code': 'Pa', 'name': 'Па'}, {'code': 'kPa', 'name': 'кПа'}, {'code': 'MPa', 'name': 'МПа'},
    {'code': 'bar', 'name': 'бар'}, {'code': 'atm', 'name': 'атм'}, {'code': 'mmHg', 'name': 'мм рт. ст.'}, {'code': 'mmH2O', 'name': 'мм вод. ст.'}, {'code': 'kgf_cm2', 'name': 'кгс/см²'},
  ];
  void _calculate() {
    if (_controller.text.isEmpty) { setState(() => _result = '---'); return; }
    double input = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;
    double output = (input * toPa[_fromUnit]!) / toPa[_toUnit]!;
    setState(() => _result = output.abs() > 1000 ? output.toStringAsFixed(1) : output.toStringAsFixed(4));
  }
  @override Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Конвертер давления', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(controller: _controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Значение', prefixIcon: Icon(Icons.speed)), onChanged: (_) => _calculate()),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(initialValue: _fromUnit, decoration: const InputDecoration(labelText: 'Из'), items: units.map((u) => DropdownMenuItem(value: u['code'], child: Text(u['name']!, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) { if(v!=null){setState((){_fromUnit=v;_calculate();});} })),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward)),
          Expanded(child: DropdownButtonFormField<String>(initialValue: _toUnit, decoration: const InputDecoration(labelText: 'В'), items: units.map((u) => DropdownMenuItem(value: u['code'], child: Text(u['name']!, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) { if(v!=null){setState((){_toUnit=v;_calculate();});} })),
        ]),
        const SizedBox(height: 24),
        _ResultCard(result: _result, unit: units.firstWhere((u) => u['code'] == _toUnit)['name'] ?? '', context: context),
      ]),
    );
  }
}

// --- Конвертер Сопротивления (Адаптивный) ---
class ResistanceConverter extends StatefulWidget {
  const ResistanceConverter({super.key});
  @override State<ResistanceConverter> createState() => _ResistanceConverterState();
}
class _ResistanceConverterState extends State<ResistanceConverter> {
  final TextEditingController _controller = TextEditingController();
  String _sensorType = '100П'; bool _modeTempToOhm = true; String _result = '0';
  final List<String> sensors = ['100П', '50П', '100М', '50М'];
  void _calculate() {
    if (_controller.text.isEmpty) { setState(() => _result = '---'); return; }
    double input = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;
    double r0, alpha;
    if (_sensorType.contains('П')) { alpha = 0.00385; r0 = _sensorType == '100П' ? 100.0 : 50.0; }
    else { alpha = 0.00428; r0 = _sensorType == '100М' ? 100.0 : 50.0; }
    double output = _modeTempToOhm ? r0 * (1 + alpha * input) : ((input / r0) - 1) / alpha;
    setState(() => _result = input == 0 && !_modeTempToOhm ? 'Ошибка' : output.toStringAsFixed(2));
  }
  @override Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Расчет ТС', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(color: Colors.blue[50], child: Padding(padding: const EdgeInsets.all(10.0), child: Column(children: [
          Text('Тип: $_sensorType', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(_modeTempToOhm ? "Режим: °C → Ом" : "Режим: Ом → °C", style: TextStyle(color: Colors.blue[800], fontStyle: FontStyle.italic)),
        ]))),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(initialValue: _sensorType, decoration: const InputDecoration(labelText: 'Тип датчика', prefixIcon: Icon(Icons.memory)), items: sensors.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(), onChanged: (v) { if(v!=null){setState((){_sensorType=v;_calculate();});} }),
        const SizedBox(height: 12),
        Card(child: SwitchListTile(title: Text(_modeTempToOhm ? "Ввод: Температура" : "Ввод: Сопротивление"), value: _modeTempToOhm, activeThumbColor: Colors.blue, onChanged: (v) { setState((){_modeTempToOhm=v;_calculate();}); }, secondary: const Icon(Icons.swap_horiz), contentPadding: const EdgeInsets.symmetric(horizontal: 8))),
        const SizedBox(height: 12),
        TextField(controller: _controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: _modeTempToOhm ? '°C' : 'Ом', prefixIcon: const Icon(Icons.edit)), onChanged: (_) => _calculate()),
        const SizedBox(height: 24),
        _ResultCard(result: _result, unit: _modeTempToOhm ? 'Ом' : '°C', context: context, subtitle: 'По линейной формуле ГОСТ'),
      ]),
    );
  }
}

// Общий виджет результата (Оптимизированный)
class _ResultCard extends StatelessWidget {
  final String result; final String unit; final BuildContext context; final String? subtitle;
  const _ResultCard({required this.result, required this.unit, required this.context, this.subtitle});
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Text('Результат:', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onPrimaryContainer)),
        const SizedBox(height: 6),
        Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(result, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(width: 6),
          Text(unit, style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary)),
        ]),
        if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey[600]))],
      ]),
    );
  }
}

// ================= SIEMENS SIPART PS2 (ПОЛНАЯ БАЗА + ПОДРОБНЫЕ ИНСТРУКЦИИ) =================
class SiemensGuide extends StatefulWidget {
  const SiemensGuide({super.key});
  @override State<SiemensGuide> createState() => _SiemensGuideState();
}

class _SiemensGuideState extends State<SiemensGuide> with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override void initState() {
    super.initState();
    _subTabController = TabController(length: 5, vsync: this); // Добавлена вкладка "Режимы"
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text.toLowerCase()));
  }

  @override void dispose() {
    _subTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // === ПОЛНАЯ БАЗА ПАРАМЕТРОВ (Раздел 9.3 мануала) ===
  final List<Map<String, dynamic>> _allParams = [
    // Группа инициализации (1-5)
    {'group': '1-5 Инициализация', 'code': '1.YFCT', 'name': 'Тип привода', 'desc': 'Настройка типа привода и направления действия.', 'values': 'turn (поворотный), -turn, WAY (поступательный), -WAY, FWAY, LWAY, ncSt, ncSL', 'default': 'WAY', 'warning': '⚠️ Важно! Неправильный выбор приведёт к некорректной работе.'},
    {'group': '1-5 Инициализация', 'code': '2.YAGL', 'name': 'Угол поворота', 'desc': 'Номинальный угол поворота вала позиционера.', 'values': '33° (ход ≤20мм), 90° (ход >25мм или поворотный)', 'default': '33°', 'warning': '⚠️ Должен соответствовать механической настройке.'},
    {'group': '1-5 Инициализация', 'code': '3.YWAY', 'name': 'Диапазон хода', 'desc': 'Диапазон хода поступательного привода в мм.', 'values': 'OFF, 5...130 мм', 'default': 'OFF', 'warning': 'Для поступательных приводов.'},
    {'group': '1-5 Инициализация', 'code': '4.INITA', 'name': 'Авто инициализация', 'desc': 'Запуск автоматической инициализации.', 'values': 'NOINI (нет), Strt (старт)', 'default': 'NOINI', 'warning': '⚠️ Запускает полный цикл настройки (RUN1-RUN5).'},
    {'group': '1-5 Инициализация', 'code': '5.INITM', 'name': 'Ручная инициализация', 'desc': 'Запуск ручной инициализации.', 'values': 'NOINI (нет), Strt (старт)', 'default': 'NOINI', 'warning': '⚠️ Использовать если автоматика не прошла.'},
    
    // Группа рабочих параметров (6-52)
    {'group': '6-52 Рабочие', 'code': '6.SCUR', 'name': 'Диапазон тока', 'desc': 'Диапазон тока заданного значения.', 'values': '0 MA (0-20мА), 4 MA (4-20мА)', 'default': '4 MA', 'warning': ''},
    {'group': '6-52 Рабочие', 'code': '7.SDIR', 'name': 'Направление сигнала', 'desc': 'Направление изменения заданного значения.', 'values': 'riSE (возрастание), FALL (убывание)', 'default': 'riSE', 'warning': ''},
    {'group': '6-52 Рабочие', 'code': '8.SPRA', 'name': 'Начало раздела диапазона', 'desc': 'Начало разделенного диапазона заданного значения.', 'values': '0.0 ... 100.0 %', 'default': '0.0', 'warning': ''},
    {'group': '6-52 Рабочие', 'code': '9.SPRE', 'name': 'Конец раздела диапазона', 'desc': 'Конец разделенного диапазона заданного значения.', 'values': '0.0 ... 100.0 %', 'default': '100.0', 'warning': ''},
    {'group': '6-52 Рабочие', 'code': '10.TSUP', 'name': 'Линейное нарастание', 'desc': 'Время линейного нарастания заданного значения.', 'values': 'Auto, 0...400 с', 'default': '0', 'warning': ''},
    {'group': '6-52 Рабочие', 'code': '11.TSDO', 'name': 'Линейное снижение', 'desc': 'Время линейного снижения заданного значения.', 'values': '0...400 с', 'default': '0', 'warning': ''},
    {'group': '6-52 Рабочие', 'code': '12.SFCT', 'name': 'Функция заданного значения', 'desc': 'Характеристика клапана (линеаризация).', 'values': 'Lin, 1-25, 1-33, 1-50, n1-25, n1-33, n1-50, FrEE', 'default': 'Lin', 'warning': ''},
    {'group': '6-52 Рабочие', 'code': '34.DEBA', 'name': 'Мертвая зона', 'desc': 'Мертвая зона контроллера с обратной связью.', 'values': 'Auto, 0.1...10.0 %', 'default': 'Auto', 'warning': '⚠️ Если клапан «рыщет» — увеличить.'},
    {'group': '6-52 Рабочие', 'code': '39.YCLS', 'name': 'Плотное закрытие', 'desc': 'Функция плотного закрытия клапана.', 'values': 'no, uP, do, uP do', 'default': 'no', 'warning': ''},
    {'group': '6-52 Рабочие', 'code': '40.YCDO', 'name': 'Плотное закрытие (низ)', 'desc': 'Нижнее значение функции плотного закрытия.', 'values': '0.0...100.0 %', 'default': '0.5', 'warning': ''},
    {'group': '6-52 Рабочие', 'code': '41.YCUP', 'name': 'Плотное закрытие (верх)', 'desc': 'Верхнее значение функции плотного закрытия.', 'values': '0.0...100.0 %', 'default': '99.5', 'warning': ''},
    {'group': '6-52 Рабочие', 'code': '50.PRST', 'name': 'Сброс параметров', 'desc': 'Сброс параметров в заводские настройки.', 'values': 'ALL (все), Init, PArA, diAg', 'default': 'ALL', 'warning': '⚠️ Осторожно! Сбрасывает все настройки.'},
    {'group': '6-52 Рабочие', 'code': '51.PNEUM', 'name': 'Режим пневматики', 'desc': 'Режим блокировки положения (FIP).', 'values': 'Std, FIP', 'default': 'Std', 'warning': ''},
    {'group': '6-52 Рабочие', 'code': '52.XDIAG', 'name': 'Расширенная диагностика', 'desc': 'Активация расширенной диагностики.', 'values': 'OFF, On1, On2, On3', 'default': 'OFF', 'warning': ''},
    
    // Группа диагностики (A-P)
    {'group': 'A-P Диагностика', 'code': 'A.PST', 'name': 'Испытание частичного хода', 'desc': 'Активация теста частичного хода.', 'values': 'OFF, On', 'default': 'OFF', 'warning': ''},
    {'group': 'A-P Диагностика', 'code': 'B.DEVI', 'name': 'Контроль динамического поведения', 'desc': 'Контроль отклонения от расчетной характеристики.', 'values': 'OFF, On', 'default': 'OFF', 'warning': ''},
    {'group': 'A-P Диагностика', 'code': 'C.LEAK', 'name': 'Контроль утечки', 'desc': 'Контроль утечки в пневматике.', 'values': 'OFF, On', 'default': 'OFF', 'warning': ''},
    {'group': 'A-P Диагностика', 'code': 'D.STIC', 'name': 'Контроль трения', 'desc': 'Контроль статического трения (скачков).', 'values': 'OFF, On', 'default': 'OFF', 'warning': ''},
    {'group': 'A-P Диагностика', 'code': 'L.STRK', 'name': 'Контроль ходов', 'desc': 'Контроль числа полных ходов.', 'values': 'OFF, On', 'default': 'OFF', 'warning': ''},
  ];

  // === ОШИБКИ И НЕИСПРАВНОСТИ (Раздел 10 мануала) ===
  final List<Map<String, String>> _errors = [
    {'code': 'RUN1/ERROR', 'msg': 'Ошибка на этапе RUN1', 'cause': 'Нет движения, нет воздуха, закрыты дроссели', 'action': '1. Проверить подачу воздуха PZ (>1.4 бар). 2. Открыть дроссели. 3. Проверить механику.'},
    {'code': 'RUN2', 'msg': 'Ошибка проверки хода', 'cause': 'Некорреляция хода и угла, рычаг криво', 'action': '1. Выставить рычаг перпендикулярно штоку. 2. Проверить параметр 2.YAGL.'},
    {'code': 'RANGE', 'msg': 'Выход за диапазон', 'cause': 'Конечное положение вне зоны измерений', 'action': 'Подвигать фрикционную муфту до появления OK на дисплее.'},
    {'code': 'MIDDL', 'msg': 'Нет середины', 'cause': 'Рычаг не горизонтален (для поступательных)', 'action': 'Выставить рычаг строго перпендикулярно штоку (горизонтально).'},
    {'code': 'NOINI', 'msg': 'Не инициализирован', 'cause': 'Первый пуск или сброс настроек', 'action': 'Запустить инициализацию (Param 4.INITA = Strt).'},
    {'code': 'd____U', 'msg': 'Нулевая точка вне диапазона', 'cause': 'Смещена фрикционная муфта', 'action': 'Выставить значение P4.0...P9.9 перемещением муфты.'},
    {'code': 'HW/ERROR', 'msg': 'Сбой аппаратного обеспечения', 'cause': 'Неисправность электроники', 'action': 'Заменить электронный блок или обратиться в сервис.'},
    {'code': 'ERR 1', 'msg': 'Рассогласование (Control Deviation)', 'cause': 'Сбой воздуха, неисправность привода/клапана', 'action': '1. Проверить пневматику. 2. Проверить механику клапана.'},
    {'code': 'ERR 2', 'msg': 'Не в авторежиме', 'cause': 'Ручной режим или конфигуратор', 'action': 'Переключить в AUT кнопкой MODE.'},
    {'code': 'LEAKG', 'msg': 'Проверка герметичности', 'cause': 'Идет тест утечки', 'action': 'Подождать 1 минуту, тест завершится автоматически.'},
    {'code': 'CPU START', 'msg': 'Старт процессора', 'cause': 'Подача питания (нормальное событие)', 'action': 'Ожидание, прибор загружается.'},
  ];

  // === ДИАГНОСТИКА (Раздел 10.2 мануала) ===
  final List<Map<String, String>> _diagnostics = [
    {'code': '1.STRKS', 'name': 'Число полных ходов', 'desc': 'Сумма полных перемещений (0-100% и обратно).', 'unit': '-', 'info': 'Для оценки ресурса клапана.'},
    {'code': '2.CHDIR', 'name': 'Изменения направления', 'desc': 'Число изменений направления движения.', 'unit': '-', 'info': ''},
    {'code': '11.LEAK', 'name': 'Проверка герметичности', 'desc': 'Величина утечки в %/мин.', 'unit': '%/мин', 'info': 'Норма: <5%/мин'},
    {'code': '12.PST', 'name': 'Контроль частичного хода', 'desc': 'Время последнего теста частичного хода.', 'unit': 'с', 'info': ''},
    {'code': '15.DEVI', 'name': 'Динамич. поведение', 'desc': 'Отклонение от расчетной характеристики.', 'unit': '%', 'info': ''},
    {'code': '16.ONLK', 'name': 'Утечка в пневматике', 'desc': 'Текущий статус индикатора утечки.', 'unit': '-', 'info': ''},
    {'code': '17.STIC', 'name': 'Статич. трение', 'desc': 'Значение скачкообразного проскальзывания.', 'unit': '%', 'info': 'Если >5% — проверить механику.'},
    {'code': '18.ZERO', 'name': 'Нижний предел хода', 'desc': 'Смещение нижнего предела от инициализации.', 'unit': '%', 'info': ''},
    {'code': '19.OPEN', 'name': 'Верхний предел хода', 'desc': 'Смещение верхнего предела от инициализации.', 'unit': '%', 'info': ''},
    {'code': '30.TEMP', 'name': 'Текущая температура', 'desc': 'Температура внутри корпуса.', 'unit': '°C/°F', 'info': ''},
    {'code': '42.VENT1', 'name': 'Циклы клапана 1', 'desc': 'Число переключений выходного вентиля 1.', 'unit': '-', 'info': 'Ресурс ~200 млн циклов.'},
    {'code': '43.VENT2', 'name': 'Циклы клапана 2', 'desc': 'Число переключений выходного вентиля 2.', 'unit': '-', 'info': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(8.0), child: TextField(
        controller: _searchController,
        decoration: InputDecoration(hintText: 'Поиск (параметр, ошибка, режим)...', prefixIcon: const Icon(Icons.search)),
      )),
      TabBar(controller: _subTabController, isScrollable: true, labelColor: Theme.of(context).colorScheme.primary, tabs: const [
        Tab(text: '🚀 Настройка'),
        Tab(text: '📖 Параметры'),
        Tab(text: '🆘 Ошибки'),
        Tab(text: '📊 Диагностика'),
        Tab(text: 'ℹ️ Режимы'),
      ]),
      Expanded(child: TabBarView(controller: _subTabController, children: [
        _buildStartupTab(),
        _buildParamsTab(),
        _buildErrorsTab(),
        _buildDiagnosticsTab(),
        _buildModesTab(),
      ])),
    ]);
  }

  // --- ВКЛАДКА 1: НАСТРОЙКА (АВТО И РУЧНАЯ) ---
  Widget _buildStartupTab() {
    if (_searchQuery.isNotEmpty) return const Center(child: Text("Поиск не активен на этой вкладке"));
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      
      _infoCard('⚠️ Подготовка перед настройкой', [
        '✅ Давление воздуха PZ: 1.4–7 бар (проверить манометром).',
        '✅ Рычаг установлен перпендикулярно штоку (для поступательных приводов).',
        '✅ Переключатель передаточного числа: 33° (ход 5-20мм) или 90° (ход >25мм).',
        '✅ Питание подано, на дисплее отображается положение или NOINI.',
        '✅ Механика свободна — проверить кнопками +/- в ручном режиме.',
      ]),

      const SizedBox(height: 24),
      _stepCard('🔹 АВТОМАТИЧЕСКАЯ ИНИЦИАЛИЗАЦИЯ', [
        'Использовать в 90% случаев — это основной способ настройки!',
        '',
        '📌 ПОШАГОВАЯ ИНСТРУКЦИЯ:',
        '1. Нажать и удерживать кнопку [MODE] > 5 секунд (вход в меню).',
        '2. Найти параметр **4.INITA** (листать кнопками +/-).',
        '3. Выбрать значение **Strt** кнопками +/-.',
        '4. Нажать и удерживать [MODE] > 5 секунд для подтверждения.',
        '5. Начнётся автоматический цикл RUN1–RUN5 (5–15 минут).',
        '6. Дождаться надписи **FINISH** — настройка завершена!',
      ], Icons.auto_fix_high, Colors.green),

      const SizedBox(height: 20),
      _runStep('RUN 1', 'Определение направления действия. Позиционер подаёт короткий импульс и проверяет, в какую сторону движется привод. ⚠️ Если нет движения — проверить воздух и дроссели.'),
      _runStep('RUN 2', 'Проверка перемещения и подстройка пределов хода (0% и 100%). Привод движется до упоров. ⚠️ Ошибка MIDDL — рычаг не перпендикулярен.'),
      _runStep('RUN 3', 'Определение времени хода + Тест герметичности (LEAKG). Замеряется время полного хода, затем 1 мин тест на утечку.'),
      _runStep('RUN 4', 'Минимизация значений приращения контроллера. Поиск минимального импульса, достаточного для сдвига привода (для точности).'),
      _runStep('RUN 5', 'Оптимизация переходного режима. Расчёт коэффициентов П-регулятора для плавного хода без колебаний.'),

      const SizedBox(height: 24),
      _stepCard('🔸 РУЧНАЯ ИНИЦИАЛИЗАЦИЯ', [
        'Использовать ТОЛЬКО если автоматика не прошла (ошибки RUN1, RANGE, MIDDL)!',
        '',
        '📌 КОГДА ИСПОЛЬЗОВАТЬ:',
        '• Приводы с фторопластовыми уплотнениями (большое трение).',
        '• Нестандартные рычаги или внешние датчики.',
        '• После замены механики без возможности авто-пуска.',
        '• Автоматика стабильно выдаёт ошибку на RUN1 или RUN2.',
        '',
        '📌 ПОШАГОВАЯ ИНСТРУКЦИЯ:',
        '1. Войти в меню (удерживать [MODE] > 5 сек).',
        '2. Найти параметр **5.INITM**.',
        '3. Выбрать **Strt**, удерживать [MODE] > 5 сек.',
        '4. Довести клапан в НИЖНИЙ предел кнопками +/- → Нажать [MODE] (ok).',
        '5. Довести клапан в ВЕРХНИЙ предел кнопками +/- → Нажать [MODE].',
        '6. Если запрос **Set Middl**: выставить рычаг горизонтально → [MODE].',
        '7. Далее прибор сам пройдёт RUN 3–RUN 5.',
      ], Icons.settings_suggest, Colors.orange),

      const SizedBox(height: 24),
      _stepCard('❗ ЧАСТЫЕ ПРОБЛЕМЫ И РЕШЕНИЯ', [
        '🔴 Ошибка RUN1/ERROR:',
        '  • Причина: Нет воздуха, закрыты дроссели, заклинило.',
        '  • Решение: Проверить PZ >1.4 бар, открыть дроссели, проверить механику вручную.',
        '',
        '🔴 Ошибка RANGE:',
        '  • Причина: Конечное положение вне зоны измерений.',
        '  • Решение: Подвигать фрикционную муфту до появления OK на дисплее.',
        '',
        '🔴 Ошибка MIDDL:',
        '  • Причина: Рычаг не перпендикулярен штоку.',
        '  • Решение: Выставить рычаг строго горизонтально, повторить инициализацию.',
        '',
        '🔴 Ошибка NOINI:',
        '  • Причина: Инициализация не проведена или сброшена.',
        '  • Решение: Запустить 4.INITA = Strt.',
      ], Icons.warning_amber, Colors.red),
    ]));
  }

  // --- ВКЛАДКА 2: ПАРАМЕТРЫ ---
  Widget _buildParamsTab() {
    final filtered = _allParams.where((p) => 
      p['code'].toString().toLowerCase().contains(_searchQuery) || 
      p['name'].toString().toLowerCase().contains(_searchQuery) ||
      p['group'].toString().toLowerCase().contains(_searchQuery)
    ).toList();
    if (filtered.isEmpty && _searchQuery.isNotEmpty) return const Center(child: Text("Ничего не найдено"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final p = filtered[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(backgroundColor: _getGroupColor(p['group']), child: Text(p['code'].toString().split('.')[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
            title: Text(p['code'], style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            subtitle: Text(p['name']),
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('📝 ${p['desc']}', style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                Text('⚙️ Варианты: ${p['values']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)), child: Text('🏭 Заводское: ${p['default']}', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold))),
                if (p['warning']!.isNotEmpty) ...[const SizedBox(height: 8), Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)), child: Text(p['warning'], style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold)))],
              ])),
            ],
          ),
        );
      },
    );
  }

  // --- ВКЛАДКА 3: ОШИБКИ ---
  Widget _buildErrorsTab() {
    final filtered = _errors.where((e) => e['code']!.toLowerCase().contains(_searchQuery) || e['msg']!.toLowerCase().contains(_searchQuery)).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.isEmpty ? _errors.length : filtered.length,
      itemBuilder: (ctx, i) {
        final e = filtered.isEmpty ? _errors[i] : filtered[i];
        return Card(
          color: Colors.red[50],
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.red),
            title: Text(e['code']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e['msg']!, style: const TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 6),
              Text('⚠️ Причина: ${e['cause']}', style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 4),
              Text('🛠 Решение: ${e['action']}', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w600)),
            ]),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // --- ВКЛАДКА 4: ДИАГНОСТИКА ---
  Widget _buildDiagnosticsTab() {
    final filtered = _diagnostics.where((d) => d['code']!.toLowerCase().contains(_searchQuery) || d['name']!.toLowerCase().contains(_searchQuery)).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.isEmpty ? _diagnostics.length : filtered.length,
      itemBuilder: (ctx, i) {
        final d = filtered.isEmpty ? _diagnostics[i] : filtered[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.purple[100], child: const Icon(Icons.analytics, color: Colors.purple)),
            title: Text(d['code']!, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['name']!, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(d['desc']!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 4),
              Text('Ед. изм.: ${d['unit']}', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
              if (d['info']!.isNotEmpty) ...[const SizedBox(height: 4), Text('💡 ${d['info']}', style: TextStyle(fontSize: 12, color: Colors.blue[700], fontStyle: FontStyle.italic))],
            ]),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // --- ВКЛАДКА 5: РЕЖИМЫ РАБОТЫ ---
  Widget _buildModesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _modeCard('🟢 AUT (Автоматический режим)', [
          'Стандартный рабочий режим позиционера.',
          '',
          '📌 Что делает:',
          '• Сравнивает заданное положение с текущим.',
          '• Перемещает привод пока рассогласование не войдёт в мёртвую зону.',
          '• Если мёртвая зона не достигается — выводит ошибку.',
          '',
          '📌 Как войти:',
          '• В режиме MAN нажать кнопку [MODE].',
          '• На дисплее отобразится AUT и заданное значение.',
        ], Colors.green),

        const SizedBox(height: 16),
        _modeCard('🟡 MAN (Ручной режим)', [
          'Режим для наладки и проверки без внешнего сигнала.',
          '',
          '📌 Что делает:',
          '• Положение задаётся кнопками +/- на позиционере.',
          '• Внешний сигнал управления игнорируется.',
          '• Удобно для проверки механики и калибровки.',
          '',
          '📌 Как войти:',
          '• Из режима AUT нажать кнопку [MODE].',
          '• На дисплее отобразится MAN и текущее положение.',
        ], Colors.orange),

        const SizedBox(height: 16),
        _modeCard('🔵 Configuration (Конфигурирование)', [
          'Режим программирования параметров.',
          '',
          '📌 Что делает:',
          '• Доступ ко всем параметрам (1-52, A-P).',
          '• Можно изменять настройки привода.',
          '• Требуется авторизация (удержание MODE >5 сек).',
          '',
          '📌 Как войти:',
          '• Удерживать [MODE] > 5 секунд из любого режима.',
          '• На дисплее появится первый параметр (1.YFCT).',
          '',
          '📌 Как выйти:',
          '• Удерживать [MODE] > 5 секунд.',
          '• Или не трогать кнопки 10 минут (авто-выход).',
        ], Colors.blue),

        const SizedBox(height: 16),
        _modeCard('🟣 Diagnostics (Диагностика)', [
          'Режим просмотра диагностических данных.',
          '',
          '📌 Что делает:',
          '• Показывает число ходов, утечки, трение и т.д.',
          '• Только просмотр — изменение параметров недоступно.',
          '• Не влияет на текущий режим работы (AUT/MAN).',
          '',
          '📌 Как войти:',
          '• Одновременно нажать все 3 кнопки и удерживать > 2 секунд.',
          '• Листать кнопкой [+].',
          '',
          '📌 Как выйти:',
          '• Нажать любую кнопку или подождать 1 минуту.',
        ], Colors.purple),

        const SizedBox(height: 24),
        Card(
          color: Colors.blue[50],
          child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💡 СОВЕТЫ ПО РЕЖИМАМ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Divider(),
            const SizedBox(height: 8),
            const Text('• Для повседневной работы использовать режим AUT.', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            const Text('• Для наладки и проверки — режим MAN.', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            const Text('• Для изменения настроек — Configuration (MODE >5 сек).', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            const Text('• Для проверки состояния — Diagnostics (3 кнопки >2 сек).', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            const Text('• После настройки всегда возвращаться в AUT!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ])),
        ),
      ]),
    );
  }

  // Вспомогательные виджеты
  Widget _infoCard(String title, List<String> items) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const Divider(),
      ...items.map((i) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(i, style: const TextStyle(fontSize: 14)))),
    ])));
  }

  Widget _stepCard(String title, List<String> steps, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color, size: 28), const SizedBox(width: 12), Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)))]),
        const Divider(),
        const SizedBox(height: 8),
        ...steps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(s, style: TextStyle(fontSize: 14, height: 1.4, color: s.isEmpty ? Colors.transparent : Colors.black87)))),
      ])),
    );
  }

  Widget _runStep(String title, String desc) {
    return Padding(padding: const EdgeInsets.only(bottom: 6, left: 28), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('• ', style: TextStyle(color: Colors.grey[700])),
      Expanded(child: RichText(text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 14), children: [
        TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: desc),
      ]))),
    ]));
  }

  Widget _modeCard(String title, List<String> content, Color color) {
    return Card(
      color: color.withValues(alpha:0.1),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const Divider(),
        const SizedBox(height: 8),
        ...content.map((c) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(c, style: const TextStyle(fontSize: 14)))),
      ])),
    );
  }

  Color _getGroupColor(String group) {
    if (group.contains('Инициализация')) return Colors.orange;
    if (group.contains('Рабочие')) return Colors.blue;
    if (group.contains('Диагностика')) return Colors.purple;
    return Colors.grey;
  }
}

// ================= РЭМТЭК (ПОЛНАЯ БАЗА ПАРАМЕТРОВ) =================
class RemTekGuide extends StatefulWidget {
  const RemTekGuide({super.key});
  @override State<RemTekGuide> createState() => _RemTekGuideState();
}

class _RemTekGuideState extends State<RemTekGuide> with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override void initState() {
    super.initState();
    _subTabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text.toLowerCase()));
  }

  @override void dispose() {
    _subTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _allParams = [
    {'group': 'B0 Движение', 'code': 'B0.0.0', 'name': 'Момент трогания Откр', 'desc': 'Момент ограничения в зоне трогания при открытии.', 'values': '0-100 %', 'default': 'Заводское'},
    {'group': 'B0 Движение', 'code': 'B0.0.1', 'name': 'Момент движения Откр', 'desc': 'Момент ограничения в зоне движения при открытии.', 'values': '0-100 %', 'default': '80%'},
    {'group': 'B0 Движение', 'code': 'B0.0.2', 'name': 'Момент трогания Закр', 'desc': 'Момент ограничения в зоне трогания при закрытии.', 'values': '0-100 %', 'default': 'Заводское'},
    {'group': 'B0 Движение', 'code': 'B0.0.3', 'name': 'Момент движения Закр', 'desc': 'Момент ограничения в зоне движения при закрытии.', 'values': '0-100 %', 'default': '90%'},
    {'group': 'B0 Движение', 'code': 'B0.0.18', 'name': 'Скорость движения', 'desc': 'Скорость перемещения выходного звена.', 'values': '0.1 - 100.0 %/с', 'default': 'Заводское'},
    {'group': 'B1 Конфиг', 'code': 'B1.0', 'name': 'Тип арматуры', 'desc': 'Выбор типа исполнительного механизма.', 'values': 'Линейный, Поворотный', 'default': 'Линейный'},
    {'group': 'B1 Конфиг', 'code': 'B1.1', 'name': 'Направление вращения', 'desc': 'Направление для открытия.', 'values': 'Прямое, Обратное', 'default': 'Прямое'},
    {'group': 'B2 Калибровка', 'code': 'B2.1', 'name': 'Калибровка 0%', 'desc': 'Запись текущего положения как 0%.', 'values': 'Старт', 'default': '-'},
    {'group': 'B2 Калибровка', 'code': 'B2.2', 'name': 'Калибровка 100%', 'desc': 'Запись текущего положения как 100%.', 'values': 'Старт', 'default': '-'},
    {'group': 'B2 Калибровка', 'code': 'B2.3', 'name': 'Мертвая зона', 'desc': 'Зона нечувствительности регулятора.', 'values': '0.1 - 10.0 %', 'default': '1.0%'},
    {'group': 'B3 Защита', 'code': 'B3.1', 'name': 'Момент ОТКРЫТИЯ', 'desc': 'Порог срабатывания защиты при открытии.', 'values': '10-100 %', 'default': '80%'},
    {'group': 'B3 Защита', 'code': 'B3.2', 'name': 'Момент ЗАКРЫТИЯ', 'desc': 'Порог срабатывания защиты при закрытии.', 'values': '10-100 %', 'default': '90%'},
    {'group': 'D Диагностика', 'code': 'D0', 'name': 'Активные дефекты', 'desc': 'Список текущих аварий.', 'values': 'Df1-Df46', 'default': '-'},
  ];

  final List<Map<String, String>> _errors = [
    {'code': 'Муфта (Мз/Мо)', 'msg': 'Сработала защита по моменту', 'cause': 'Заклинило арматуру или сбиты уставки', 'action': '1. Проверить вручную. 2. Если туго — смазать. 3. Если легко — увеличить уставку момента.'},
    {'code': 'Программирование (Пр)', 'msg': 'Режим настройки', 'cause': 'Активен режим программирования', 'action': 'Выйти из меню (не трогать кнопки 10 мин) или нажать СТОП.'},
    {'code': 'Авария (Красный)', 'msg': 'Активна авария', 'cause': 'Обрыв фазы, перегрев, ошибка ДП', 'action': 'Смотреть код дефекта в меню D0. Устранить причину и сделать сброс.'},
    {'code': 'Df12', 'msg': 'Обрыв фазы', 'cause': 'Пропала фаза питания', 'action': 'Проверить напряжение 380В и контакты.'},
    {'code': 'Df19', 'msg': 'Перегрев двигателя', 'cause': 'Частые пуски или нагрузка', 'action': 'Дать остыть 30 мин. Проверить ток.'},
  ];

  Future<void> _launchVideo(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw Exception('Не удалось открыть $url');
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(8.0), child: TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Поиск параметра (напр. B0.0.1)...', prefixIcon: const Icon(Icons.search)))),
      TabBar(controller: _subTabController, isScrollable: true, labelColor: Theme.of(context).colorScheme.primary, tabs: const [
        Tab(text: '🚀 Пуск (Инструкция)'),
        Tab(text: '⚙️ Параметры'),
        Tab(text: '🆘 Ошибки'),
        Tab(text: '🎥 Видео'),
      ]),
      Expanded(child: TabBarView(controller: _subTabController, children: [
        _buildStartupWizard(),
        _buildParamsList(),
        _buildErrorsList(),
        _buildVideoSection(),
      ])),
    ]);
  }

  Widget _buildStartupWizard() {
    if (_searchQuery.isNotEmpty) return const Center(child: Text("Поиск не активен на этой вкладке"));
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepCard('1️⃣ Вход в режим настройки', [
        '1. Убедитесь, что привод стоит неподвижно (режим СТОП).',
        '2. Найдите **ПРАВУЮ КРАСНУЮ РУЧКУ** (управление/стоп).',
        '3. Поверните её **ВПРАВО** (по часовой стрелке).',
        '4. **УДЕРЖИВАЙТЕ** её в этом положении **не менее 3 секунд**.',
        '5. Отпустите, когда на дисплее загорится значок **«Пр»** (Программирование).',
      ], Icons.lock_open, Colors.orange),
      const SizedBox(height: 16),
      _stepCard('2️⃣ Навигация к параметру', [
        'Меню имеет структуру: Раздел -> Параметр -> Значение.',
        '• Крутите **ЛЕВУЮ ЧЕРНУЮ РУЧКУ**:',
        '   - **ВЛЕВО (-)**: Список вверх / Уменьшение числа.',
        '   - **ВПРАВО (+)**: Список вниз / Увеличение числа.',
        '• Найдите нужный раздел (напр. «Пусконаладка» или «B0 Движение»).',
        '• Нажмите **ПРАВУЮ КРАСНУЮ РУЧКУ ВПРАВО** (коротко) для входа внутрь.',
      ], Icons.menu_book, Colors.blue),
      const SizedBox(height: 16),
      _stepCard('3️⃣ Калибровка положений (0% и 100%)', [
        'Это самый важный этап!',
        '1. Зайдите в меню: **Пусконаладка** -> **Калибровка положения**.',
        '2. Выберите пункт **«Текущее положение»** или **«Калибровка 0%**».',
        '3. **Действие:** Физически доведите задвижку вручную (ручным дублером) в положение **ПОЛНОСТЬЮ ЗАКРЫТО**.',
        '4. В меню установите значение **0%** (или нажмите подтверждение, если требуется запись).',
        '5. Нажмите **ПРАВУЮ КРАСНУЮ РУЧКУ ВПРАВО** для сохранения.',
        '6. Повторите для **100%**: доведите задвижку в положение **ПОЛНОСТЬЮ ОТКРЫТО**, установите 100% и сохраните.',
      ], Icons.settings_suggest, Colors.green),
      const SizedBox(height: 16),
      _stepCard('4️⃣ Настройка моментов (Защита)', [
        'Если привод часто встает по «Муфте»:',
        '1. Зайдите в меню: **B0 Движение** -> **Момент движения** (Открытие или Закрытие).',
        '2. Крутите **ЛЕВУЮ ЧЕРНУЮ РУЧКУ ВПРАВО**, чтобы увеличить значение (напр. с 70% до 80%).',
        '3. Нажмите **ПРАВУЮ КРАСНУЮ** для сохранения.',
        '⚠️ Не ставьте 100%, чтобы не сломать шток при заклинивании!',
      ], Icons.shield, Colors.red),
      const SizedBox(height: 16),
      _stepCard('5️⃣ Выход и сохранение', [
        '1. Чтобы выйти назад, крутите **ПРАВУЮ КРАСНУЮ РУЧКУ ВЛЕВО**.',
        '2. Выходите до главного экрана с большими цифрами процентов.',
        '3. Значок **«Пр»** должен погаснуть (или подождите 10 мин бездействия).',
        'Готово! Привод работает.',
      ], Icons.check_circle, Colors.teal),
    ]));
  }

  Widget _buildParamsList() {
    final filtered = _allParams.where((p) => 
      p['code'].toString().toLowerCase().contains(_searchQuery) || 
      p['name'].toString().toLowerCase().contains(_searchQuery) ||
      p['group'].toString().toLowerCase().contains(_searchQuery)
    ).toList();
    if (filtered.isEmpty && _searchQuery.isNotEmpty) return const Center(child: Text("Ничего не найдено"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final p = filtered[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(backgroundColor: Colors.blue[100], child: Text(p['code'].toString().split('.')[0], style: const TextStyle(fontWeight: FontWeight.bold))),
            title: Text(p['code'], style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            subtitle: Text(p['name']),
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('📝 ${p['desc']}', style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                Text('⚙️ Диапазон: ${p['values']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)), child: Text('🏭 По умолчанию: ${p['default']}', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold))),
              ])),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorsList() {
    final filtered = _errors.where((e) => e['code']!.toLowerCase().contains(_searchQuery) || e['msg']!.toLowerCase().contains(_searchQuery)).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.isEmpty ? _errors.length : filtered.length,
      itemBuilder: (ctx, i) {
        final e = filtered.isEmpty ? _errors[i] : filtered[i];
        return Card(
          color: Colors.red[50],
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.red),
            title: Text(e['code']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e['msg']!, style: const TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 6),
              Text('⚠️ Причина: ${e['cause']}', style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 4),
              Text('🛠 Решение: ${e['action']}', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w600)),
            ]),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildVideoSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _videoCard('Калибровка точек 0% и 100%', 'https://www.youtube.com/watch?v=mlZlgcLODEc', 'Показан вход в меню и запись положений.'),
        const SizedBox(height: 16),
        _videoCard('Настройка моментов и времени', 'https://www.youtube.com/watch?v=gx6hJQGNCvo&t=273s', 'Как настроить защиту от перегрузки.'),
      ]),
    );
  }

  Widget _stepCard(String title, List<String> steps, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color, size: 28), const SizedBox(width: 12), Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)))]),
        const Divider(),
        const SizedBox(height: 8),
        ...steps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(s, style: const TextStyle(fontSize: 15, height: 1.4)))),
      ])),
    );
  }

  Widget _videoCard(String title, String url, String desc) {
    return Card(
      color: Colors.blue[50],
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(fontStyle: FontStyle.italic)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _launchVideo(url),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Смотреть на YouTube'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
        ),
      ])),
    );
  }
}

// ================= СУ-1С =================
class Su1sGuide extends StatelessWidget {
  const Su1sGuide({super.key});
  @override Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Сигнализатор СУ-1С', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Диагностика мультиметром', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 20),
      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/su1s_scheme.png', height: 250, width: double.infinity, fit: BoxFit.contain, errorBuilder: (c,e,s) => Container(height: 100, color: Colors.grey[300], alignment: Alignment.center, child: Text('Нет изображения\nПоложи файл su1s_scheme.png\nв assets/images', textAlign: TextAlign.center)))),
      const SizedBox(height: 20),
      const Text('🗺️ Карта клемм', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        _terminalRow('1', 'Уровень (Общий)'), _terminalRow('2', 'Уровень (НО)'), _terminalRow('3', 'Уровень (НЗ)'),
        const Divider(), _terminalRow('4', 'Исправность (Общий)'), _terminalRow('5', 'Исправность (НО)'),
        const Divider(), _terminalRow('6', 'Питание (+)'), _terminalRow('7', 'Питание (-)'),
      ]))),
      const SizedBox(height: 20),
      _checkCard('1. Питание', ['Щупы на 6 и 7.', 'Норма: 24В.']),
      const SizedBox(height: 12),
      _checkCard('2. Реле уровня (1-2-3)', ['Пустой бак: 1-3 звонится, 1-2 нет.', 'Полный бак: 1-2 звонится, 1-3 нет.']),
      const SizedBox(height: 12),
      _checkCard('3. Реле исправности (4-5)', ['Норма: Разрыв (тишина).', 'Авария: Замыкание (звонок).']),
    ]));
  }
  Widget _terminalRow(String num, String desc) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(4)), child: Text(num, style: const TextStyle(fontWeight: FontWeight.bold))), const SizedBox(width: 12), Expanded(child: Text(desc))]));
  Widget _checkCard(String title, List<String> steps) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)), const Divider(), ...steps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(s)))])));
}

// ================= СОКРАТ-Р3/Н3 (БЛОКИ УПРАВЛЕНИЯ) =================
class SokratGuide extends StatefulWidget {
  const SokratGuide({super.key});
  @override State<SokratGuide> createState() => _SokratGuideState();
}

class _SokratGuideState extends State<SokratGuide> with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override void initState() {
    super.initState();
    _subTabController = TabController(length: 6, vsync: this); // Добавлена вкладка Галерея
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text.toLowerCase()));
  }

  @override void dispose() {
    _subTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // === БАЗА ПАРАМЕТРОВ СОКРАТ ===
  final List<Map<String, dynamic>> _allParams = [
    {'group': 'Параметры блока', 'code': '104', 'name': 'Год даты', 'desc': 'Год выпуска блока', 'values': '2012...2025', 'default': '-', 'warning': ''},
    {'group': 'Параметры блока', 'code': '105', 'name': 'Тип блока', 'desc': 'Тип блока управления', 'values': '1...8', 'default': '-', 'warning': ''},
    {'group': 'Параметры привода', 'code': '111', 'name': 'Номер привода', 'desc': 'Заводской номер электропривода', 'values': '1...65535', 'default': '-', 'warning': ''},
    {'group': 'Защиты', 'code': '213', 'name': 'Авария Umin', 'desc': 'Защита от пониженного напряжения', 'values': '60...80 В', 'default': '60', 'warning': '⚠️ При снижении ниже этого значения - авария'},
    {'group': 'Защиты', 'code': '214', 'name': 'Время Umin', 'desc': 'Время срабатывания защиты Umin', 'values': '10...60 с', 'default': '30', 'warning': ''},
    {'group': 'Защиты', 'code': '217', 'name': 'Авария Umax', 'desc': 'Защита от повышенного напряжения', 'values': '125...140 В', 'default': '125', 'warning': '⚠️ При превышении - авария'},
    {'group': 'Защиты', 'code': '219', 'name': 'Тип защиты Imax', 'desc': 'Защита от перегрузки двигателя', 'values': '0...3', 'default': '2', 'warning': ''},
    {'group': 'Защиты', 'code': '220', 'name': 'Предупр. Imax', 'desc': 'Предупредительный уровень тока', 'values': '150...200 %', 'default': '200', 'warning': ''},
    {'group': 'Защиты', 'code': '221', 'name': 'Авария Imax', 'desc': 'Аварийный уровень тока', 'values': '200...300 %', 'default': '250', 'warning': '⚠️ Превышение тока двигателя'},
    {'group': 'Калибровка', 'code': '-', 'name': 'Конечные положения', 'desc': 'Настройка положений Открыто/Закрыто', 'values': '-', 'default': '-', 'warning': '⚠️ Требует точной установки'},
  ];

  // === АВАРИИ И НЕИСПРАВНОСТИ ===
  final List<Map<String, String>> _errors = [
    {'code': 'Авария Umin', 'msg': 'Пониженное напряжение', 'cause': 'Напряжение сети ниже 60В', 'action': '1. Проверить напряжение питания. 2. Устранить просадку сети. 3. Сбросить аварию.'},
    {'code': 'Авария Umax', 'msg': 'Повышенное напряжение', 'cause': 'Напряжение сети выше 125В', 'action': '1. Проверить напряжение. 2. Отключить питание при превышении. 3. Сбросить аварию.'},
    {'code': 'Авария Imax', 'msg': 'Перегрузка двигателя', 'cause': 'Ток двигателя превышает уставку', 'action': '1. Проверить механику арматуры. 2. Проверить уставки моментов. 3. Сбросить аварию.'},
    {'code': 'Авария ДП', 'msg': 'Неисправность датчика положения', 'cause': 'Обрыв или КЗ датчика', 'action': '1. Проверить подключение ДП. 2. Заменить датчик при необходимости.'},
    {'code': 'Выход за диапазон', 'msg': 'Положение вне конечных положений', 'cause': 'Сбиты настройки конечных положений', 'action': '1. Провести перекалибровку положений. 2. Проверить механику.'},
    {'code': 'Перегрев', 'msg': 'Перегрев двигателя', 'cause': 'Длительная работа или высокая нагрузка', 'action': '1. Дать двигателю остыть. 2. Проверить нагрузку. 3. Увеличить паузы между циклами.'},
  ];

  // === КОДЫ ОШИБОК С ГАЛЕРЕЕЙ ===
  final List<Map<String, dynamic>> _errorGallery = [
    {
      'code': 'A01',
      'name': 'Превышение момента/Муфта',
      'image': 'assets/images/sokrat_error_A01.jpg',
      'description': 'Значительное превышение момента сопротивления нагрузки',
      'steps': [
        'Остановить электропривод командой "СТОП"',
        'Перевести рукоятку выбора режима в положение "Местный" (МУ)',
        'Попробовать вручную проверить движение арматуры ручным дублером',
        'Если арматура движется туго — проверить наличие механических препятствий, смазку',
        'Если арматура движется свободно — проверить настройки моментов (параметры 280-283)',
        'При необходимости увеличить уставку момента на 10-15%',
        'Подать команду "Сброс аварий" (рукоятка №3 в положение СБРОС СТОП)',
      ],
    },
  ];

  Future<void> _launchPDF() async {
    final Uri uri = Uri.parse('https://www.sibmash.com/docs/Sokrat-RZ-N3_E32-SM.090.00.00.000-RE.pdf');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Не удалось открыть PDF');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(8.0), child: TextField(
        controller: _searchController,
        decoration: InputDecoration(hintText: 'Поиск (параметр, авария, настройка)...', prefixIcon: const Icon(Icons.search)),
      )),
      TabBar(
        controller: _subTabController, 
        isScrollable: true, 
        labelColor: Theme.of(context).colorScheme.primary, 
        tabs: const [
          Tab(text: '🚀 Настройка'),
          Tab(text: '📖 Параметры'),
          Tab(text: '🆘 Аварии'),
          Tab(text: '📊 Характеристики'),
          Tab(text: '📄 PDF'),
          Tab(text: '📸 Галерея'),
        ],
      ),
      Expanded(child: TabBarView(
        controller: _subTabController, 
        children: [
          _buildStartupTab(),
          _buildParamsTab(),
          _buildErrorsTab(),
          _buildSpecsTab(),
          _buildPDFSection(),
          _buildGalleryTab(),
        ],
      )),
    ]);
  }

  // --- ВКЛАДКА 1: НАСТРОЙКА ---
  Widget _buildStartupTab() {
    if (_searchQuery.isNotEmpty) return const Center(child: Text("Поиск не активен"));
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      
      _infoCard('⚠️ Подготовка к настройке', [
        '✅ Убедитесь, что блок подключен к сети 380В 50Гц.',
        '✅ Проверьте подключение электродвигателя.',
        '✅ Убедитесь, что арматура свободно перемещается.',
        '✅ Снимите блокировку рукоятки выбора режима (поворот по часовой стрелке).',
      ]),

      const SizedBox(height: 24),
      _stepCard('🔹 ВВОД В ЭКСПЛУАТАЦИЮ', [
        '📌 ПОШАГОВАЯ ИНСТРУКЦИЯ:',
        '1. Переведите блок в режим «Местный» (рукоятка №2 в положение МУ).',
        '2. На дисплее появится: «ЦВХ -А00 0 Н*М-%»',
        '3. Проведите настройку моментов отключения (п. 3.11 РЭ).',
        '4. Определите направление вращения штока.',
        '5. Проведите калибровку конечных положений (см. ниже).',
        '6. Настройте параметры управления и защиты (п. 3.8, 3.9, 3.12).',
        '7. Проведите пробный цикл открытия/закрытия.',
      ], Icons.settings_suggest, Colors.blue),

      const SizedBox(height: 24),
      _stepCard('🔸 КАЛИБРОВКА КОНЕЧНЫХ ПОЛОЖЕНИЙ', [
        '📌 СПОСОБ 1 (с использованием МПУ):',
        '1. Переведите блок в режим программирования (рукоятка №3).',
        '2. Переместите запорный орган в положение «Закрыто».',
        '3. Удерживайте рукоятку №3 в нижнем положении 3 сек.',
        '4. На дисплее появится «000%» - положение записано.',
        '5. Переместите орган в положение «Открыто».',
        '6. Удерживайте рукоятку №3 3 сек.',
        '7. На дисплее появится «100%» - калибровка завершена.',
        '',
        '📌 СПОСОБ 2 (автоматический):',
        '1. Войдите в меню параметров.',
        '2. Найдите параметр «Калибровка положений».',
        '3. Следуйте инструкциям на дисплее.',
      ], Icons.settings_suggest, Colors.green),

      const SizedBox(height: 24),
      _stepCard('🔹 НАСТРОЙКА МОМЕНТОВ', [
        '1. Войдите в меню параметров (рукоятка №3).',
        '2. Найдите группу «Моменты».',
        '3. Установите:',
        '   • Момент открытия: 80-90% от макс.',
        '   • Момент закрытия: 90-100% от макс.',
        '4. Сохраните настройки.',
        '⚠️ Не устанавливайте 100% - это может повредить арматуру!',
      ], Icons.tune, Colors.orange),

      const SizedBox(height: 24),
      _stepCard('❗ РЕЖИМЫ УПРАВЛЕНИЯ', [
        '🟢 МЕСТНЫЙ (МУ):',
        '  • Рукоятка №2 в положении «МУ».',
        '  • Управление с МПУ блока.',
        '  • Рукоятка №1: ОТКР/ЗАКР.',
        '  • Рукоятка №3: СТОП.',
        '',
        '🔵 ДИСТАНЦИОННЫЙ (ДУ):',
        '  • Рукоятка №2 в положении «ДУ».',
        '  • Управление по дискретным входам.',
        '  • Управление по RS-485 (ModBus).',
        '  • Управление по аналоговому входу 4-20мА.',
      ], Icons.settings_input_component, Colors.purple),
    ]));
  }

  // --- ВКЛАДКА 2: ПАРАМЕТРЫ ---
  Widget _buildParamsTab() {
    final filtered = _allParams.where((p) => 
      p['code'].toString().toLowerCase().contains(_searchQuery) || 
      p['name'].toString().toLowerCase().contains(_searchQuery) ||
      p['group'].toString().toLowerCase().contains(_searchQuery)
    ).toList();
    if (filtered.isEmpty && _searchQuery.isNotEmpty) return const Center(child: Text("Ничего не найдено"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final p = filtered[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(backgroundColor: Colors.blue[100], child: Text(p['code'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
            title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(p['group']),
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('📝 ${p['desc']}', style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                Text('⚙️ Диапазон: ${p['values']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)), child: Text('🏭 По умолчанию: ${p['default']}', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold))),
                if (p['warning']!.isNotEmpty) ...[const SizedBox(height: 8), Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)), child: Text(p['warning'], style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold)))],
              ])),
            ],
          ),
        );
      },
    );
  }

  // --- ВКЛАДКА 3: АВАРИИ ---
  Widget _buildErrorsTab() {
    final filtered = _errors.where((e) => e['code']!.toLowerCase().contains(_searchQuery) || e['msg']!.toLowerCase().contains(_searchQuery)).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.isEmpty ? _errors.length : filtered.length,
      itemBuilder: (ctx, i) {
        final e = filtered.isEmpty ? _errors[i] : filtered[i];
        return Card(
          color: Colors.red[50],
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.red),
            title: Text(e['code']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e['msg']!, style: const TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 6),
              Text('⚠️ Причина: ${e['cause']}', style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 4),
              Text('🛠 Решение: ${e['action']}', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w600)),
            ]),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // --- ВКЛАДКА 4: ХАРАКТЕРИСТИКИ ---
  Widget _buildSpecsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _specCard('⚡ Основные характеристики', [
          'Напряжение питания: ~380В 50Гц',
          'Мощность двигателя: 0.09...7.5 кВт',
          'Маркировка взрывозащиты: 1Ex d IIС T4 Gb',
          'Степень защиты: IP67/IP68',
          'Интерфейс: RS-485 (ModBus RTU)',
          'Скорость обмена: до 115200 бит/с',
        ]),
        const SizedBox(height: 16),
        _specCard('📡 Входы/Выходы', [
          'Цифровые входы: 4 или 6 (24В DC)',
          'Релейные выходы: 6 или 8 (сухой контакт)',
          'Аналоговый вход: 4...20 мА',
          'Аналоговый выход: 4...20 мА',
          'Напряжение коммутации: ~250В, =36В',
          'Ток коммутации: не более 2А',
        ]),
        const SizedBox(height: 16),
        _specCard('🛡️ Защиты', [
          'От пониженного напряжения (Umin)',
          'От повышенного напряжения (Umax)',
          'От перегрузки двигателя (Imax)',
          'От перегрева двигателя',
          'От отсутствия движения',
          'От выхода за диапазон положений',
          'От неисправности датчика положения',
        ]),
        const SizedBox(height: 16),
        _specCard('📊 Дополнительные функции', [
          'Местное управление с МПУ',
          'Дистанционное управление',
          'Тактовый режим работы',
          'Промежуточные положения останова',
          'Журнал событий (200 записей)',
          'Энергонезависимая память',
          'Встроенный нагреватель (100Вт)',
        ]),
      ]),
    );
  }

  // --- ВКЛАДКА 5: PDF ---
  Widget _buildPDFSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Card(
          color: Colors.blue[50],
          child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
            const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Руководство по эксплуатации', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('СОКРАТ-Р3 / СОКРАТ-Н3', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Блоки управления взрывозащищенные', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _launchPDF,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Открыть PDF документ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text('https://www.sibmash.com/docs/\nSokrat-RZ-N3_E32-SM.090.00.00.000-RE.pdf', 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
        ),
        const SizedBox(height: 24),
        _infoCard('📚 Содержание руководства', [
          '1. Требования безопасности',
          '2. Описание и работа блока',
          '3. Использование по назначению',
          '   • Подготовка к использованию',
          '   • Электрическое подключение',
          '   • Настройка параметров',
          '   • Калибровка положений',
          '   • Местное и дистанционное управление',
          '   • Аварии и неисправности',
          '4. Техническое обслуживание',
          '5. Ремонт',
          '6. Транспортирование и хранение',
        ]),
      ]),
    );
  }

  // --- ВКЛАДКА 6: ГАЛЕРЕЯ ОШИБОК ---
Widget _buildGalleryTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('📸 Примеры аварий', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      
      // ИСПРАВЛЕНО: Явно указываем тип (Map<String, dynamic> error) в map()
      ..._errorGallery.map((Map<String, dynamic> error) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              error['image'],  // Теперь работает, т.к. error явно типа Map
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, errorObj, stackTrace) {
                return Container(
                  height: 300,
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'Нет изображения\nПроверьте: ${error['image']}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('❗ Авария ${error['code']} - ${error['name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('📌 Описание: ${error['description']}', style: const TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              const Text('🔧 Что делать:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(error['steps'].length, (index) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${index + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(error['steps'][index])),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ]),
      )), // .toList() обязателен после map() для Spread-оператора ...
    ]),
  );
}

  // Вспомогательные виджеты
  Widget _infoCard(String title, List<String> items) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const Divider(),
      ...items.map((i) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(i, style: const TextStyle(fontSize: 14)))),
    ])));
  }

  Widget _stepCard(String title, List<String> steps, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color, size: 28), const SizedBox(width: 12), Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)))]),
        const Divider(),
        const SizedBox(height: 8),
        ...steps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(s, style: TextStyle(fontSize: 14, height: 1.4, color: s.isEmpty ? Colors.transparent : Colors.black87)))),
      ])),
    );
  }

  Widget _specCard(String title, List<String> items) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        const Divider(),
        const SizedBox(height: 8),
        ...items.map((i) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(i, style: const TextStyle(fontSize: 14)))),
      ])),
    );
  }
}