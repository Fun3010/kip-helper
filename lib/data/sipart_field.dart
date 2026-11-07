import '../models/guide.dart';
import '../models/guide_procedure.dart';

const _keys = GuideIllustration(
  asset: 'assets/illustrations/sipart-field-keys.png',
  title: 'Кнопки SIPART PS2',
  caption:
      '2 — режим (слева); 3 — «−» (середина); 4 — «+» (справа). Номера исходного рисунка.',
  source: 'A5E00074631-AF · 10/2020 · рис. 6-1 · с. 94',
);

const _linearEvidence = GuideEvidence(
  sourceKey: 'sipart-compact',
  locator: '§ 5.6.2 · с. 60–62',
);
const _rotaryEvidence = GuideEvidence(
  sourceKey: 'sipart-compact',
  locator: '§ 5.7.2 · с. 64–65',
);
const _exitEvidence = GuideEvidence(
  sourceKey: 'sipart-full',
  locator: '§ 6.2.2 · с. 96; § 11.1.2 · с. 212',
);
const _cancelEvidence = GuideEvidence(
  sourceKey: 'sipart-compact',
  locator: '§ 5.8 · с. 66',
);
const _scope =
    'Только механическая обратная связь с муфтой, без NCS/iNCS и внешнего датчика. '
    'Исполнения без муфты этим маршрутом не охвачены.';

ProcedureStep _enter(bool linear) => ProcedureStep(
  title: 'Вход в конфигурацию',
  action:
      'Из подготовленного режима P manual удерживайте левую кнопку режима не менее 5 секунд. '
      'Откроется конфигурация с параметром 1.YFCT.',
  control: 'Кнопка режима · слева',
  hold: 'Не менее 5 секунд',
  illustration: _keys,
  display: '1.YFCT',
  displayAsset: 'assets/illustrations/sipart-field-way.png',
  expectedResult:
      'На нижней строке — 1.YFCT. WAY на рисунке — пример начального значения; '
      'нужный тип выбирается следующим шагом.',
  evidence: [linear ? _linearEvidence : _rotaryEvidence],
);

ProcedureStep _type(bool linear) => ProcedureStep(
  title: 'Тип привода · 1.YFCT',
  action: linear
      ? 'Для стандартного линейного привода со штатным рычагом проверьте WAY в 1.YFCT. '
            'Значения меняют кнопками «−» и «+». FWAY, LWAY, инвертированные и NCS-варианты требуют своей процедуры.'
      : 'В 1.YFCT кнопкой «−» выберите turn для стандартного поворотного привода. '
            'Не переносите это значение на NCS/iNCS и другие варианты обратной связи.',
  control: linear ? '«−» / «+» · значение' : '«−» · средняя кнопка',
  hold: 'До нужного значения',
  illustration: _keys,
  display: linear ? 'WAY' : 'turn',
  displayAsset:
      'assets/illustrations/sipart-field-${linear ? 'way' : 'turn'}.png',
  expectedResult: linear
      ? '1.YFCT = WAY; механика соответствует стандартному линейному варианту.'
      : '1.YFCT = turn. Для этого варианта 2.YAGL автоматически устанавливается в 90°.',
  evidence: [
    linear ? _linearEvidence : _rotaryEvidence,
    const GuideEvidence(
      sourceKey: 'sipart-compact',
      locator: '§ 5.4 · с. 56–57',
    ),
    const GuideEvidence(
      sourceKey: 'sipart-full',
      locator: '§ 6.1.2 · с. 94–95',
    ),
  ],
);

ProcedureStep _angle(bool linear) => ProcedureStep(
  title: 'Передаточное отношение · 2.YAGL',
  action: linear
      ? 'Кратко нажмите кнопку режима: откроется 2.YAGL. Сравните 33° или 90° '
            'с положением переключателя передаточного отношения. При несовпадении вернитесь к подготовке по § 5.6.1; запускать инициализацию пока нельзя.'
      : 'Кратко нажмите кнопку режима: откроется 2.YAGL. Убедитесь, что показаны 90° '
            'и переключатель передаточного отношения установлен на 90° согласно подготовке § 5.7.1.',
  control: 'Кнопка режима · слева',
  hold: 'Краткое нажатие',
  illustration: _keys,
  display: linear ? '33° / 90°' : '90°',
  displayAsset: 'assets/illustrations/sipart-field-yagl.png',
  expectedResult:
      'Значение 2.YAGL совпадает с подготовленной механикой. На рисунке показаны оба значения; '
      '${linear ? 'выбирайте по фактической установке' : 'для turn требуется 90°'}.',
  evidence: [linear ? _linearEvidence : _rotaryEvidence],
);

const _stroke = ProcedureStep(
  title: 'Ход в миллиметрах · 3.YWAY',
  action:
      'Кратко нажмите кнопку режима, чтобы перейти к 3.YWAY. Настройка необязательная: '
      'если ход в мм не нужен, оставьте OFF и перейдите к следующему параметру. '
      'Если нужен — считайте значение, отмеченное штифтом на шкале рычага, и задайте его кнопками «−»/«+». Не подставляйте предполагаемый ход.',
  control: 'Режим → параметр; «−» / «+» → значение',
  hold: 'Краткие нажатия',
  illustration: _keys,
  display: '3.YWAY · OFF или ход',
  displayAsset: 'assets/illustrations/sipart-field-yway.png',
  expectedResult:
      'OFF либо значение со шкалы рычага. Установка 3.YWAY влияет на отображение полного хода в мм.',
  evidence: [_linearEvidence],
);

ProcedureStep _inita(bool linear) => ProcedureStep(
  title: 'Параметр запуска · 4.INITA',
  action:
      'Кратко нажимайте кнопку режима до параметра 4.INITA. '
      'На этом шаге только откройте параметр; запуск выполняется отдельно.',
  control: 'Кнопка режима · слева',
  hold: 'Краткое нажатие',
  illustration: _keys,
  display: '4.INITA',
  displayAsset: 'assets/illustrations/sipart-field-inita.png',
  expectedResult:
      'Нижняя строка — 4.INITA; no на рисунке — пример показания до запуска.',
  evidence: [linear ? _linearEvidence : _rotaryEvidence],
);

ProcedureStep _start(bool linear) => ProcedureStep(
  title: 'Запуск инициализации',
  action:
      'Только при разрешённом полном ходе удерживайте кнопку «+» не менее 5 секунд, '
      'пока не появится Strt. Привод начнёт автоматические перемещения.',
  control: '«+» · правая кнопка',
  hold: 'Не менее 5 секунд',
  illustration: _keys,
  display: 'Strt',
  displayAsset: 'assets/illustrations/sipart-field-start.png',
  expectedResult:
      'Показано Strt; затем нижняя строка отображает этапы RUN. '
      'Нажатие «Далее» в приложении не запускает прибор.',
  evidence: [linear ? _linearEvidence : _rotaryEvidence],
);

ProcedureStep _wait(bool linear) => ProcedureStep(
  title: 'Дождитесь FINSH',
  action:
      'Наблюдайте этапы RUN на приборе. Инициализация в зависимости от привода занимает до 15 минут. '
      'RUN сам по себе — этап, а не авария. Для остановившегося этапа или сообщения используйте раздел диагностики; '
      'не считайте переход приложения подтверждением завершения.',
  display: 'FINSH',
  displayAsset:
      'assets/illustrations/sipart-field-finish-${linear ? 'linear' : 'rotary'}.png',
  expectedResult: linear
      ? 'На приборе — FINSH; при заданном 3.YWAY сверху отображается определённый ход. '
            'Фрагмент РЭ показывает только вид сообщения, не измеренное значение вашего привода.'
      : 'На приборе — FINSH и определённый угол. 93.5° на рисунке — пример из РЭ, не требуемая уставка.',
  evidence: [linear ? _linearEvidence : _rotaryEvidence],
);

const _exit = ProcedureStep(
  title: 'Подтверждение и выход в MAN',
  action:
      'Только после FINSH кратко подтвердите завершение кнопкой режима. Затем удерживайте '
      'кнопку режима не менее 5 секунд, чтобы выйти из конфигурации. '
      'Версия ПО отображается при выходе; после отпускания проверьте режим MAN.',
  control: 'Режим: кратко → удерживать',
  hold: 'Удержание не менее 5 секунд',
  illustration: _keys,
  display: 'MAN',
  expectedResult:
      'Ручной режим MAN. Возврат AUT не выполняется этим шагом: '
      'сначала проверьте результат и условия технологического процесса по процедуре объекта.',
  evidence: [_exitEvidence],
);

List<ProcedureStep> _steps(bool linear) => [
  _enter(linear),
  _type(linear),
  _angle(linear),
  if (linear) _stroke,
  _inita(linear),
  _start(linear),
  _wait(linear),
  _exit,
];

const sipartCancel = ProcedureStep(
  title: 'Прерывание на самом приборе',
  action:
      'Только во время незавершённой инициализации: кратко нажмите кнопку режима. Автоматическая инициализация прервётся, появится INITA. '
      'Для выхода из конфигурации удерживайте кнопку режима не менее 5 секунд: отобразится версия ПО. '
      'После отпускания — P manual; инициализация не завершена. Это не сброс PRST.',
  expectedResult:
      'Не продолжайте маршрут завершения через FINSH. Настройки, полученные до прерывания, '
      'сохраняются; проверьте состояние прибора и следующий порядок действий по РЭ.',
  evidence: [_cancelEvidence],
);

GuideProcedure sipartFieldProcedure(InstrumentGuide guide) => GuideProcedure(
  id: 'sipart-initialization',
  guideId: guide.id,
  title: 'Автоматическая инициализация · кнопки и экраны',
  scope: 'SIPART PS2 · A5E03436620-AH, 02/2024. $_scope',
  prerequisites: [
    'Полный ход и перемещения арматуры разрешены. Монтаж, питание и пневматика '
        'подготовлены по РЭ установленного исполнения; привод стоит в среднем положении.',
    'Исходное состояние этого маршрута — P manual / NOINI. Доступ к кнопкам разрешён '
        'с учётом исполнения и требований взрывозащиты; открытие корпуса не является шагом этого просмотра.',
    'Для плотно закрывающейся арматуры до инициализации учитывается YCLS по РЭ (§§ 5.6.2, 5.7.2). '
        'Если соответствующая настройка не установлена, сначала выполните её по своему РЭ.',
  ],
  sources: guide.sources,
  variants: [
    for (final linear in [true, false])
      ProcedureVariant(
        id: linear ? 'linear' : 'rotary',
        title: linear ? 'Линейный привод · § 5.6' : 'Поворотный привод · § 5.7',
        scope:
            '${linear ? 'WAY · штатный рычаг · § 5.6' : 'turn · 90° · § 5.7'}. $_scope',
        prerequisites: [
          linear
              ? 'Механика подготовлена по § 5.6.1: положение рычага и переключателя сверено; '
                    'при горизонтальном рычаге — P48.0…P52.0.'
              : 'Механика подготовлена по § 5.7.1; переключатель передаточного отношения — 90°.',
        ],
        steps: _steps(linear),
      ),
  ],
);
