import '../models/guide.dart';
import '../models/guide_procedure.dart';
import 'guides.dart';

/// Unsupported guide IDs deliberately have no manufacturer-backed workflow.
List<GuideProcedure> proceduresForGuide(String guideId) =>
    _registry[guideId] ?? const [];

final Map<String, List<GuideProcedure>> _registry = {
  'sokrat': _sokrat(),
  'su1s': _su1s(),
  'sipart': _sipart(),
};

InstrumentGuide _guide(String id) =>
    guides.singleWhere((item) => item.id == id);

// Reuse reviewed catalogue paragraphs verbatim. Do not silently promote a
// checklist or a paragraph whose source evidence was subsequently downgraded.
ProcedureStep _step(
  InstrumentGuide guide,
  String sectionTitle,
  int paragraph,
  String expectedResult,
) {
  final section = guide.sections.singleWhere(
    (item) => item.title == sectionTitle,
  );
  final evidence = section.evidenceFor(paragraph);
  if (evidence.isEmpty ||
      evidence.any((item) => item.state != GuideEvidenceState.verified)) {
    throw StateError(
      'Unverified procedure paragraph: ${guide.id}/$sectionTitle',
    );
  }
  return ProcedureStep(
    action: section.paragraphs[paragraph],
    expectedResult: expectedResult,
    evidence: List.unmodifiable(evidence),
  );
}

List<GuideProcedure> _sokrat() {
  final guide = _guide('sokrat');
  const scope =
      'СОКРАТ Р3/Н3 · Э32 · только ПО 03.01. '
      'СМ.090.00.00.000 РЭ, август 2019.';
  return List.unmodifiable([
    GuideProcedure(
      id: 'sokrat-travel',
      guideId: guide.id,
      title: 'Запись крайних положений',
      scope: '$scope § 3.10 · PDF с. 51–52.',
      prerequisites: [guide.sections.first.paragraphs.first],
      sources: guide.sources,
      variants: [
        ProcedureVariant(
          id: 'r3-n3',
          title: 'Р3 / Н3 · Э32 · ПО 03.01',
          scope: scope,
          prerequisites: const [
            'Полный ход арматуры разрешён; направление вращения сверено. '
                'Уплотнение по моменту — отдельная настройка по § 3.11.',
          ],
          steps: [
            _step(
              guide,
              'Запись закрытого положения',
              0,
              'На дисплее МПУ; закрытое положение выставлено ручным дублёром.',
            ),
            _step(
              guide,
              'Запись закрытого положения',
              1,
              'Рукоятка №2 отпущена после 0,2…2 с; №1 установлена к ЗАКР. '
                  'Запись закрытия выполняется следующим шагом.',
            ),
            _step(
              guide,
              'Запись закрытого положения',
              2,
              'Дождитесь показания 0% и индикации закрытия на приборе.',
            ),
            _step(
              guide,
              'Запись открытого положения',
              0,
              'Открытое положение выставлено ручным дублёром.',
            ),
            _step(
              guide,
              'Запись открытого положения',
              1,
              'Дождитесь показания 100% и индикации открытия на приборе.',
            ),
          ],
        ),
      ],
    ),
    GuideProcedure(
      id: 'sokrat-codes',
      guideId: guide.id,
      title: 'Определение сообщения аварии',
      scope: '$scope Таблицы 36 и 38; только расшифровка сообщения.',
      prerequisites: const [
        'Обозначение прибора и ПО совпадают с областью применения. '
            'Расшифровка кода не является разрешением на сброс или ремонт.',
      ],
      sources: guide.sources,
      variants: [
        ProcedureVariant(
          id: 'r3-n3',
          title: 'Р3 / Н3 · Э32 · ПО 03.01',
          scope: '$scope Табл. 36 · РЭ с. 58; табл. 38 · с. 59.',
          prerequisites: const [],
          steps: [
            _step(
              guide,
              'Аварии · таблицы 36, 38',
              0,
              'Сопоставьте фактический код с таблицей: А28 относится к датчику '
                  'положения и требует ремонта. Для отсутствующего кода откройте РЭ; '
                  'эта карта не устанавливает причину неисправности.',
            ),
          ],
        ),
      ],
    ),
  ]);
}

List<GuideProcedure> _su1s() {
  final guide = _guide('su1s');
  const scope =
      'СУ-1С по РГАУ.407834.006 РЭ, 2014. '
      'Исполнение, паспорт и маркировка крышки должны совпадать.';
  return List.unmodifiable([
    GuideProcedure(
      id: 'su1s-connections',
      guideId: guide.id,
      title: 'Сверка контактов перед подключением',
      scope:
          '$scope Это карта назначения контактов, а не полный монтажный наряд.',
      prerequisites: const [
        'До подключения сверьте исполнение и схему. Питание обогрева '
            'не определяют по напряжению питания электронной части.',
      ],
      sources: guide.sources,
      variants: [
        ProcedureVariant(
          id: 'su1s-2014',
          title: 'СУ-1С · РГАУ.407834.006 · 2014',
          scope: '$scope П. 1.4.5 · РЭ с. 13; приложения А и Л.',
          prerequisites: const [],
          steps: [
            _step(
              guide,
              'Карта контактов · РГАУ.407834.006',
              0,
              'Контакты 1–3 относятся к уровню; 4–5 — к исправности. '
                  'Назначение сверено с маркировкой установленного прибора.',
            ),
            _step(
              guide,
              'Карта контактов · РГАУ.407834.006',
              1,
              '6 — +24 В, 7 — минус питания, 8–9 — внутреннее заземление. '
                  'Для 10–11 питание обогрева установлено по схеме исполнения.',
            ),
            _step(
              guide,
              'Карта контактов · РГАУ.407834.006',
              2,
              'Геометрическое расположение сверено по приложению Л, '
                  'внешние соединения — по приложению А. '
                  'Приложение не подтверждает выполненный монтаж.',
            ),
          ],
        ),
      ],
    ),
    GuideProcedure(
      id: 'su1s-relays',
      guideId: guide.id,
      title: 'Сопоставление состояния реле',
      scope: '$scope Пп. 1.2.2 и 1.2.7 · РЭ с. 7.',
      prerequisites: const [
        'Для уже полученных результатов проверки. Способ безопасного '
            'измерения выбирается по РЭ и процедуре обслуживания объекта; '
            'этот просмотр не описывает измерение под напряжением.',
      ],
      sources: guide.sources,
      variants: [
        ProcedureVariant(
          id: 'su1s-2014',
          title: 'СУ-1С · РГАУ.407834.006 · 2014',
          scope: scope,
          prerequisites: const [],
          steps: [
            _step(
              guide,
              'Уровень и исправность',
              0,
              'Без жидкости: 1–3 замкнуты и 1–2 разомкнуты. '
                  'При достижении уровня: 1–2 замкнуты и 1–3 разомкнуты.',
            ),
            _step(
              guide,
              'Уровень и исправность',
              1,
              'Исправности соответствует замкнутая цепь 4–5. '
                  'Разомкнутая цепь не подтверждает исправность.',
            ),
          ],
        ),
      ],
    ),
  ]);
}

List<GuideProcedure> _sipart() {
  final guide = _guide('sipart');
  return List.unmodifiable([
    GuideProcedure(
      id: 'sipart-initialization',
      guideId: guide.id,
      title: 'Подготовка к автоматической инициализации',
      scope:
          'SIPART PS2 · A5E03436620-AH, 02/2024. '
          'Маршрут по §§ 5.6–5.7; не полная последовательность кнопок. '
          'Для исполнения без механической муфты нужна инструкция его версии.',
      prerequisites: [
        guide.sections.first.paragraphs[1],
        guide.sections.first.paragraphs[2],
        'До запуска откройте § 5.6.2 или § 5.7.2 для своего привода. '
            'Не начинайте движение, если исполнение или условия запуска не установлены.',
      ],
      sources: guide.sources,
      variants: [
        for (final linear in [true, false])
          ProcedureVariant(
            id: linear ? 'linear' : 'rotary',
            title: linear
                ? 'Линейный привод · § 5.6'
                : 'Поворотный привод · § 5.7',
            scope: linear
                ? 'Линейный привод · § 5.6 · РЭ с. 59–65 (общий диапазон §§ 5.6–5.7). '
                      'Монтаж и механика обратной связи должны соответствовать исполнению.'
                : 'Поворотный привод · § 5.7 · РЭ с. 59–65 (общий диапазон §§ 5.6–5.7). '
                      'Монтаж и механика обратной связи должны соответствовать исполнению.',
            prerequisites: const [
              'Тип одинарного или двойного действия установлен; '
                  'перемещение арматуры на весь диапазон разрешено.',
            ],
            steps: [
              _step(
                guide,
                'Перед инициализацией',
                0,
                'Тип привода и схема обратной связи определены; '
                    'для выбранного ${linear ? 'линейного' : 'поворотного'} '
                    'привода используется § ${linear ? '5.6' : '5.7'}.',
              ),
              _step(
                guide,
                'Автоматическая настройка · 4.INITA',
                0,
                '1.YFCT выбран по типу привода и механике обратной связи '
                    'согласно § ${linear ? '5.6' : '5.7'} выбранного исполнения.',
              ),
              _step(
                guide,
                'Автоматическая настройка · 4.INITA',
                1,
                'Параметр 4.INITA относится к автоматической инициализации. '
                    'До запуска сверяйте условия и кнопки по § '
                    '${linear ? '5.6.2 · РЭ с. 60' : '5.7.2 · РЭ с. 64'}. '
                    'Переход в приложении не запускает и не подтверждает инициализацию.',
              ),
            ],
          ),
      ],
    ),
  ]);
}
