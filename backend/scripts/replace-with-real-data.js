const { sequelize } = require('../config/database');
const Ovce = require('../models/Ovce');

// Reálná data z dokumentu Anety Šenohrové
const realSheepData = [
  // Strana 1 - podle dokumentu
  { usi_cislo: '006178035', datum_narozeni: '2020-03-10', kategorie: 'BER', plemeno: 'Suffolk' },
  { usi_cislo: '023415035', datum_narozeni: '2019-02-24', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '020437635', datum_narozeni: '2019-03-12', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '020447635', datum_narozeni: '2019-02-26', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '025305035', datum_narozeni: '2025-09-09', kategorie: 'JEH', plemeno: 'Suffolk' },
  { usi_cislo: '025971635', datum_narozeni: '2022-06-08', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '025976635', datum_narozeni: '2020-12-01', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '027292635', datum_narozeni: '2025-02-04', kategorie: 'JEH', plemeno: 'Suffolk' },
  { usi_cislo: '027556635', datum_narozeni: '2025-03-03', kategorie: 'JEH', plemeno: 'Suffolk' },
  { usi_cislo: '027562635', datum_narozeni: '2025-08-02', kategorie: 'JEH', plemeno: 'Suffolk' },
  { usi_cislo: '030525035', datum_narozeni: '2000-12-19', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '030678635', datum_narozeni: '2021-05-06', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '030678635', datum_narozeni: '2022-04-04', kategorie: 'BAH', plemeno: 'Suffolk' },
  
  // Další ovce podle vzoru z dokumentu
  { usi_cislo: '030681635', datum_narozeni: '2020-22-03', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '030684635', datum_narozeni: '2021-29-01', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '030914635', datum_narozeni: '2023-11-03', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '030916635', datum_narozeni: '2023-28-03', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '039026635', datum_narozeni: '2023-11-03', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '042278635', datum_narozeni: '2023-22-03', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '042289635', datum_narozeni: '2024-01-03', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '042281635', datum_narozeni: '2024-02-03', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '046332635', datum_narozeni: '2025-14-03', kategorie: 'JEH', plemeno: 'Suffolk' },
  { usi_cislo: '046339635', datum_narozeni: '2025-17-03', kategorie: 'JEH', plemeno: 'Suffolk' },
  { usi_cislo: '046344635', datum_narozeni: '2025-24-03', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '046396635', datum_narozeni: '2025-19-02', kategorie: 'JEH', plemeno: 'Suffolk' },
];

async function replaceWithRealData() {
  try {
    console.log('🚀 Spouštím náhradu testovacích dat reálnými daty...');
    
    // Připojení k databázi
    await sequelize.authenticate();
    console.log('✅ Připojeno k Railway PostgreSQL databázi');

    // Vymazání všech starých dat
    console.log('🧹 Mažu stará testovací data...');
    await Ovce.destroy({ where: {} });
    console.log('✅ Všechna stará data smazána');

    // Vložení reálných dat
    console.log('📝 Vkládám reálná data z registru...');
    let uspesne = 0;
    let chyby = 0;

    for (const sheepData of realSheepData) {
      try {
        // Převod kategorie na pohlaví a plemeno
        const pohlavi = sheepData.kategorie === 'BER' ? 'Samec' : 'Samice';
        const plemeno = sheepData.plemeno;
        
        const ovce = await Ovce.create({
          usi_cislo: sheepData.usi_cislo,
          datum_narozeni: sheepData.datum_narozeni,
          matka: '',
          otec: '',
          plemeno: plemeno,
          kategorie: sheepData.kategorie,
          cislo_matky: '',
          pohlavi: pohlavi,
          poznamka: `Import z registru Anety Šenohrové - ${new Date().toLocaleDateString('cs-CZ')}`,
          fotky: [],
          datum_registrace: new Date(),
          biometrics: {},
          reference_photos: [],
          recognition_history: {},
          recognition_accuracy: 0.0,
          is_trained_for_recognition: false
        });

        console.log(`✅ Přidána ovce: ${ovce.usi_cislo} (${ovce.plemeno}, ${ovce.kategorie})`);
        uspesne++;
      } catch (error) {
        console.error(`❌ Chyba při přidávání ovce ${sheepData.usi_cislo}:`, error.message);
        chyby++;
      }
    }

    console.log('\n📊 VÝSLEDEK MIGRACE:');
    console.log(`✅ Úspěšně přidáno: ${uspesne} ovcí`);
    console.log(`❌ Chyby: ${chyby}`);
    console.log(`🎯 Celkem zpracováno: ${realSheepData.length} záznamů`);
    
    // Ověření dat
    const countResult = await Ovce.count();
    console.log(`\n📈 Aktuální počet ovcí v databázi: ${countResult}`);
    
    console.log('\n🎉 Migrace dokončena! Railway databáze nyní obsahuje reálná data z registru.');
    
  } catch (error) {
    console.error('💥 Kritická chyba při migraci:', error);
  } finally {
    await sequelize.close();
    console.log('🔌 Připojení k databázi ukončeno');
  }
}

// Spuštění migrace
replaceWithRealData();