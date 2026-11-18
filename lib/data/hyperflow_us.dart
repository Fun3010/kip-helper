import '../models/guide.dart';

const hyperflowUsGuide = InstrumentGuide(
  id: 'hyperflow_us',
  title: 'ГиперФлоу-УС',
  subtitle: 'Ультразвуковой расходомер · исполнения С и Т',
  category: 'Расход',
  searchTerms: ['гиперфлоу', 'hyperflow', 'расходомер', 'крау1.456.013'],
  scope:
      'КРАУ1.456.013 РЭ, 2011, изменения в документе до 2012 г.; только исполнения «С» и «Т». Для исполнения «Р» требуется другое РЭ. Сверьте полное обозначение и паспорт установленного прибора.',
  sections: [
    GuideSection(
      title: 'Назначение и исполнение',
      paragraphs: [
        'ГиперФлоу-УС предназначен для измерения расхода и объёма природного газа и других газовых сред с приведением к стандартным условиям.',
        'РЭ различает исполнение «С» стандартной конфигурации и исполнение «Т» для технологических измерений с врезкой в измерительный трубопровод.',
      ],
      evidenceByParagraph: {
        0: [
          GuideEvidence(
            sourceKey: 'hyperflow-us-re',
            locator: '§ 1.1.1 · РЭ и PDF с. 6',
          ),
        ],
        1: [
          GuideEvidence(
            sourceKey: 'hyperflow-us-re',
            locator: 'введение · РЭ и PDF с. 5',
          ),
        ],
      },
    ),
    GuideSection(
      title: 'Перед работой',
      paragraphs: [
        'Запишите полную маркировку расходомера, исполнение, номер, паспорт и редакцию РЭ. Сверьте измерительную среду и параметры настройки с документацией узла учёта.',
        'Настройка, монтаж и поверка зависят от исполнения и условий объекта. Эта карточка не содержит последовательности настройки или разрешения менять параметры.',
      ],
      evidenceByParagraph: {
        0: [
          GuideEvidence(
            sourceKey: 'hyperflow-us-re',
            locator: 'идентификация исполнения по паспорту и КРАУ1.456.013 РЭ',
            state: GuideEvidenceState.workingChecklist,
          ),
        ],
        1: [
          GuideEvidence(
            sourceKey: 'hyperflow-us-re',
            locator: 'границы обзорной карточки · РЭ с. 5',
            state: GuideEvidenceState.workingChecklist,
          ),
        ],
      },
    ),
  ],
  sources: [
    GuideSource(
      key: 'hyperflow-us-re',
      title: 'Вымпел · ГиперФлоу-УС · КРАУ1.456.013 РЭ, исполнения С и Т',
      url:
          'https://vympel.group/upload/iblock/20a/%D0%A0%D1%83%D0%BA%D0%BE%D0%B2%D0%BE%D0%B4%D1%81%D1%82%D0%B2%D0%BE%20%D0%BF%D0%BE%20%D1%8D%D0%BA%D1%81%D0%BF%D0%BB%D1%83%D0%B0%D1%82%D0%B0%D1%86%D0%B8%D0%B8%20%D0%93%D0%B8%D0%BF%D0%B5%D1%80%D0%A4%D0%BB%D0%BE%D1%83-%D0%A3%D0%A1.pdf',
    ),
  ],
);
