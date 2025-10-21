const express = require('express');
const { sequelize } = require('../config/database');
const Ovce = require('../models/Ovce');

const router = express.Router();

// Reálná data z dokumentu Anety Šenohrové
const realSheepData = [
  // Podle dokumentu - převedeno z fotky
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
  { usi_cislo: '030678635', datum_narozeni: '2021-06-05', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '030678935', datum_narozeni: '2022-04-04', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '030681635', datum_narozeni: '2020-03-22', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '030684635', datum_narozeni: '2021-01-29', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '030914635', datum_narozeni: '2023-03-11', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '030916635', datum_narozeni: '2023-03-28', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '039026635', datum_narozeni: '2023-03-11', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '042278635', datum_narozeni: '2023-03-22', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '042289635', datum_narozeni: '2024-03-01', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '042281635', datum_narozeni: '2024-03-02', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '046332635', datum_narozeni: '2025-03-14', kategorie: 'JEH', plemeno: 'Suffolk' },
  { usi_cislo: '046339635', datum_narozeni: '2025-03-17', kategorie: 'JEH', plemeno: 'Suffolk' },
  { usi_cislo: '046344635', datum_narozeni: '2025-03-24', kategorie: 'BAH', plemeno: 'Suffolk' },
  { usi_cislo: '046396635', datum_narozeni: '2025-02-19', kategorie: 'JEH', plemeno: 'Suffolk' },
];

// POST /api/replace-real-data - Nahradí testovací data reálnými daty z registru
router.post('/replace-real-data', async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    console.log('🚀 Spouštím náhradu testovacích dat reálnými daty...');
    
    // Vymazání všech starých dat
    console.log('🧹 Mažu stará testovací data...');
    await Ovce.destroy({ where: {}, transaction });
    console.log('✅ Všechna stará data smazána');

    // Vložení reálných dat
    console.log('📝 Vkládám reálná data z registru...');
    let uspesne = 0;
    let chyby = 0;
    const vysledky = [];

    for (const sheepData of realSheepData) {
      try {
        // Převod kategorie na pohlaví
        const pohlavi = sheepData.kategorie === 'BER' ? 'Samec' : 'Samice';
        
        const ovce = await Ovce.create({
          usi_cislo: sheepData.usi_cislo,
          datum_narozeni: sheepData.datum_narozeni,
          matka: '',
          otec: '',
          plemeno: sheepData.plemeno,
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
        }, { transaction });

        vysledky.push({
          usi_cislo: ovce.usi_cislo,
          status: 'success',
          message: `Přidána ovce: ${ovce.usi_cislo} (${ovce.plemeno}, ${ovce.kategorie})`
        });
        uspesne++;
      } catch (error) {
        vysledky.push({
          usi_cislo: sheepData.usi_cislo,
          status: 'error',
          message: error.message
        });
        chyby++;
      }
    }

    // Commit transakce
    await transaction.commit();
    
    // Ověření dat
    const countResult = await Ovce.count();
    
    console.log('\n📊 VÝSLEDEK MIGRACE:');
    console.log(`✅ Úspěšně přidáno: ${uspesne} ovcí`);
    console.log(`❌ Chyby: ${chyby}`);
    console.log(`📈 Aktuální počet ovcí v databázi: ${countResult}`);
    
    res.status(200).json({
      message: 'Migrace dokončena úspěšně',
      summary: {
        uspesne,
        chyby,
        celkem: realSheepData.length,
        aktualni_pocet_v_db: countResult
      },
      vysledky,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    await transaction.rollback();
    console.error('💥 Kritická chyba při migraci:', error);
    
    res.status(500).json({
      error: 'Chyba při nahrazování dat',
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;