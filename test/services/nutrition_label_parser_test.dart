import 'package:flutter_test/flutter_test.dart';
import 'package:larger/services/nutrition_label_parser.dart';

void main() {
  group('NutritionLabelParser', () {
    test('parses a US nutrition facts panel', () {
      const label = '''
Nutrition Facts
Serving Size 1 cup (240ml)
Calories 150
Total Fat 5g
Saturated Fat 3g
Protein 8g
Total Carbohydrate 20g
''';

      final parsed = NutritionLabelParser.parse(label);

      expect(parsed.servingLabel, '1 cup (240ml)');
      expect(parsed.calories, 150);
      expect(parsed.fatG, 5);
      expect(parsed.proteinG, 8);
      expect(parsed.carbsG, 20);
    });

    test('parses EU energy in kcal', () {
      const label = '''
Energy 420 kcal
Protein 12.5 g
Carbohydrate 45 g
Fat 8 g
''';

      final parsed = NutritionLabelParser.parse(label);

      expect(parsed.calories, 420);
      expect(parsed.proteinG, 12.5);
      expect(parsed.carbsG, 45);
      expect(parsed.fatG, 8);
    });

    test('converts energy in kJ to kcal when kcal is missing', () {
      const label = 'Energy 418.4 kJ\nProtein 4g';

      final parsed = NutritionLabelParser.parse(label);

      expect(parsed.calories, 100);
      expect(parsed.proteinG, 4);
      expect(parsed.servingLabel, isNull);
    });

    test('leaves missing serving and macros null', () {
      const label = 'Calories 80';

      final parsed = NutritionLabelParser.parse(label);

      expect(parsed.calories, 80);
      expect(parsed.servingLabel, isNull);
      expect(parsed.proteinG, isNull);
      expect(parsed.carbsG, isNull);
      expect(parsed.fatG, isNull);
    });

    test('parses a Turkish bilingual panel with kJ/kcal slash values', () {
      const label = '''
Enerji ve Besin Öğeleri / Nutritional Values / 100 ml
Enerji / Energy (kJ/kcal) 172/41
Yağ / Fat (g) 1
- Doymuş yağ / of which saturates (g) 0,7
Karbonhidrat / Carbohydrate (g) 4,8
- Şekerler / of which sugars (g) 4,8
Protein (g) 3
Tuz / Salt (g) 0,09
''';

      final parsed = NutritionLabelParser.parse(label);

      expect(parsed.servingLabel, '100 ml');
      expect(parsed.calories, 41);
      expect(parsed.fatG, 1);
      expect(parsed.carbsG, 4.8);
      expect(parsed.proteinG, 3);
    });

    test('parses Turkish labels then a matching values column', () {
      const label = '''
ENERJİ VE BESİN ÖĞELERİ (100 ml İÇİN)
ENERJİ
YAĞ
DOYMUŞ YAĞ
KARBONHİDRAT
ŞEKERLER
PROTEİN
TUZ
3 kcal (11 kJ)
0 g
0 g
0,9 g
0 g
0 g
0,20 g
''';

      final parsed = NutritionLabelParser.parse(label);

      expect(parsed.servingLabel, '100 ml');
      expect(parsed.calories, 3);
      expect(parsed.fatG, 0);
      expect(parsed.carbsG, 0.9);
      expect(parsed.proteinG, 0);
    });

    test('uses the portion column on a 100ml vs porsiyon table', () {
      const label = '''
ENERJİ VE BESİN ÖĞELERİ
100ml için
1 Porsiyon (250 ml)
ENERJİ
5kJ/1kcal
12kJ/3kcal
YAĞ
0g
0g
KARBONHİDRAT
0,1g
0,2g
PROTEİN
0,0g
0,1g
''';

      final parsed = NutritionLabelParser.parse(label);

      expect(parsed.servingLabel, '1 Porsiyon (250 ml)');
      expect(parsed.calories, 3);
      expect(parsed.fatG, 0);
      expect(parsed.carbsG, 0.2);
      expect(parsed.proteinG, 0.1);
    });

    test('uses the right-hand product column on a comparison label', () {
      const label = '''
HEINZ LIGHT MAYONEZ
Enerji ve Besin Öğeleri
Heinz Mayonez 100 g için
Heinz Light Mayonez 100 g için
Enerji 1587 kJ/ 385 kcal 1108 kJ/ 268 kcal
Yağ
39 g
26 g
Karbonhidrat
6,2 g
8,0 g
Protein
<0,5 g
0,6 g
''';

      final parsed = NutritionLabelParser.parse(label);

      expect(parsed.servingLabel, '100 g');
      expect(parsed.calories, 268);
      expect(parsed.fatG, 26);
      expect(parsed.carbsG, 8);
      expect(parsed.proteinG, 0.6);
    });

    test('parses pesto-style unit-then-number rows', () {
      const label = '''
Enerji Ve Besin Öğeleri 100
Enerji
Yağ
kJ 2030 / kcal 492
g 47
- Doymuş Yağ
g 5,3
Karbonhidrat
g 11
- Şekerler
g 5,0
Protein
g 4,7
Tuz
g 3,2
''';

      final parsed = NutritionLabelParser.parse(label);

      expect(parsed.servingLabel, '100 g');
      expect(parsed.calories, 492);
      expect(parsed.fatG, 47);
      expect(parsed.carbsG, 11);
      expect(parsed.proteinG, 4.7);
    });

    test('parses next-line Turkish values', () {
      const label = '''
ENERJİ VE BESİN ÖĞELERİ
100 g için
Enerji (kJ/kcal)
377/90
Yağ (g)
5,5
-Doymuş yağ (g)
3,6
Karbonhidrat (g)
5,5
Protein (g)
4,7
Tuz (g)
0,1
''';

      final parsed = NutritionLabelParser.parse(label);

      expect(parsed.servingLabel, '100 g');
      expect(parsed.calories, 90);
      expect(parsed.fatG, 5.5);
      expect(parsed.carbsG, 5.5);
      expect(parsed.proteinG, 4.7);
    });

    test('reads OCR from a bilingual 100 ml carton', () {
      final parsed = NutritionLabelParser.parse(_ocr0708);

      expect(parsed.servingLabel, '100 ml');
      expect(parsed.calories, 41);
    });

    test('reads OCR from an energy drink can', () {
      final parsed = NutritionLabelParser.parse(_ocr0710);

      expect(parsed.servingLabel, '100 ml');
      expect(parsed.calories, 3);
      expect(parsed.fatG, 0);
      expect(parsed.carbsG, 0.9);
      expect(parsed.proteinG, 0);
    });

    test('reads OCR from a two-column soda label', () {
      final parsed = NutritionLabelParser.parse(_ocr0711);

      expect(parsed.servingLabel, '1 Porsiyon (250 ml)');
      expect(parsed.calories, 3);
      expect(parsed.fatG, 0);
      expect(parsed.carbsG, 0.2);
      expect(parsed.proteinG, 0.1);
    });

    test('reads OCR from pesto with delayed kJ/kcal values', () {
      final parsed = NutritionLabelParser.parse(_ocr0712);

      expect(parsed.calories, 492);
      expect(parsed.fatG, 47);
      expect(parsed.carbsG, 11);
      expect(parsed.proteinG, 4.7);
    });

    test('reads OCR from a Heinz light vs regular comparison', () {
      final parsed = NutritionLabelParser.parse(_ocr0713);

      expect(parsed.servingLabel, '100 g');
      expect(parsed.calories, 268);
      expect(parsed.fatG, 26);
      expect(parsed.carbsG, 8);
      expect(parsed.proteinG, 0.6);
    });

    test('reads OCR from a next-line 100 g dairy label', () {
      final parsed = NutritionLabelParser.parse(_ocr0714);

      expect(parsed.servingLabel, '100 g');
      expect(parsed.calories, 90);
      expect(parsed.fatG, 5.5);
      expect(parsed.carbsG, 5.5);
      expect(parsed.proteinG, 4.7);
    });
  });
}

const _ocr0708 = '''
Enerji ve Besin Öğeleri /
Nutritional Values
Enerji / Energy (kJ/kcal)
Yağ / Fat (g)
- Doymuş yağ /
of which saturates (g)
Karbonhidrat /
Carbohydrate (g)
- Şekerler /
of which sugars (g)
Protein (g)
Tuz / Salt (g)
/ 100 ml
172/41
4,8
4,8
3
0,09
''';

const _ocr0710 = '''
ENERJİ VE BESİN ÖĞELERİ (100 ml İÇİN)
ENERJİ
YAĞ
DOYMUŞ YAG
KARBONHİDRAT
ŞEKERLER
PROTEİN
TUZ
3 kcal (11 kJ)
0 g
0 g
0,9 g
0 g
0 g
0,20 g
''';

const _ocr0711 = '''
ENERJİ VE BESİN ÖĞELERİ
1 Porsiyon (250 ml)
100ml için
ENERJİ
5kJ/1kcal
12kJ/3kcal
YAĞ
0g
0g
-DOYMUŞ YAĞ
0g
0g
KARBONHİDRAT
0,1g
0,2g
-SEKERLER
0,0g
0,1g
LİF
0g
0g
PROTEİN
0,0g
0,1g
TUZ
0,02g
0,05g
''';

const _ocr0712 = '''
Enerji Ve Besin Öğeleri 100
Enerji
Yağ
J 2030 / kcal 492
g 47
- Doymuş Yağ
g 5,3
Karbonhidrat
g 11
- Şekerler
g 5,0
Lif
g 3,0
Protein
g 4,7
Tuz
g 3,2
''';

const _ocr0713 = '''
HEINZ LIGHT MAYONEZ
Eneri ve Besin Oğeleri 100 g için
100 g için
Eneri 1587 kJ/ 385 kcal 1108 kJ/ 268 kcal
Yağ
39 g
26 g
Doymus vağ 4,7 g
3,0 g
Karbonhidrat
6,2 g
8,0 g
6 hafla içinde tüketiniz Tavsiye
Protein
<0,5 g
0,6 g
''';

const _ocr0714 = '''
ENERJİ VE BESİN ÖĞELERİ
100 g için
Enerji (kJ/kcal)
377/90
Yağ (g)
5,5
-Doymuş yağ (g)
3,6
Karbonhidrat (g)
5,5
Protein (g)
4,7
Tuz (g)
0,1
''';

