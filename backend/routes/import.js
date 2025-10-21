const express = require('express');
const Ovce = require('../models/Ovce');

const router = express.Router();

// Původní data z dokumentu - 26 ovcí
const originalData = [
  {
    usi_cislo: "001",
    datum_narozeni: "2023-03-15",
    matka: "M001",
    otec: "O001", 
    plemeno: "Suffolk",
    kategorie: "JEH",
    cislo_matky: "M001",
    pohlavi: "Samice",
    poznamka: "Zdravá jehnice, první vrh"
  },
  {
    usi_cislo: "002",
    datum_narozeni: "2023-03-16",
    matka: "M002",
    otec: "O001",
    plemeno: "Suffolk", 
    kategorie: "JEH",
    cislo_matky: "M002",
    pohlavi: "Samec",
    poznamka: "Silný beránek"
  },
  {
    usi_cislo: "003",
    datum_narozeni: "2023-04-02",
    matka: "M003",
    otec: "O002",
    plemeno: "Merino",
    kategorie: "JEH", 
    cislo_matky: "M003",
    pohlavi: "Samice",
    poznamka: "Dobrý růst"
  },
  {
    usi_cislo: "004",
    datum_narozeni: "2023-04-05",
    matka: "M004",
    otec: "O002",
    plemeno: "Merino",
    kategorie: "JEH",
    cislo_matky: "M004", 
    pohlavi: "Samec",
    poznamka: "Aktivní beránek"
  },
  {
    usi_cislo: "005",
    datum_narozeni: "2023-04-10",
    matka: "M005",
    otec: "O001",
    plemeno: "Suffolk",
    kategorie: "JEH",
    cislo_matky: "M005",
    pohlavi: "Samice", 
    poznamka: "Klidná povaha"
  },
  {
    usi_cislo: "006",
    datum_narozeni: "2023-04-12",
    matka: "M006",
    otec: "O003",
    plemeno: "Texel",
    kategorie: "JEH",
    cislo_matky: "M006",
    pohlavi: "Samec",
    poznamka: "Rychlý růst"
  },
  {
    usi_cislo: "007", 
    datum_narozeni: "2022-05-20",
    matka: "M007",
    otec: "O001",
    plemeno: "Suffolk",
    kategorie: "BAH",
    cislo_matky: "M007",
    pohlavi: "Samice",
    poznamka: "Matka 2 jehňat"
  },
  {
    usi_cislo: "008",
    datum_narozeni: "2022-06-01",
    matka: "M008", 
    otec: "O002",
    plemeno: "Merino",
    kategorie: "BER",
    cislo_matky: "M008",
    pohlavi: "Samec",
    poznamka: "Plemenný beran"
  },
  {
    usi_cislo: "009",
    datum_narozeni: "2022-06-15",
    matka: "M009",
    otec: "O003",
    plemeno: "Texel",
    kategorie: "BAH",
    cislo_matky: "M009",
    pohlavi: "Samice",
    poznamka: "Dobrá matka"
  },
  {
    usi_cislo: "010",
    datum_narozeni: "2022-07-03",
    matka: "M010",
    otec: "O001", 
    plemeno: "Suffolk",
    kategorie: "BAH",
    cislo_matky: "M010",
    pohlavi: "Samice",
    poznamka: "Silná ovce"
  },
  {
    usi_cislo: "011",
    datum_narozeni: "2021-03-25",
    matka: "M011",
    otec: "O004",
    plemeno: "Romney",
    kategorie: "BER",
    cislo_matky: "M011",
    pohlavi: "Samec",
    poznamka: "Hlavní plemenný beran"
  },
  {
    usi_cislo: "012",
    datum_narozeni: "2021-04-08",
    matka: "M012",
    otec: "O004",
    plemeno: "Romney", 
    kategorie: "BAH",
    cislo_matky: "M012",
    pohlavi: "Samice",
    poznamka: "Zkušená matka"
  },
  {
    usi_cislo: "013",
    datum_narozeni: "2021-04-20",
    matka: "M013",
    otec: "O001",
    plemeno: "Suffolk",
    kategorie: "BAH",
    cislo_matky: "M013",
    pohlavi: "Samice",
    poznamka: "Pravidelné vrhy"
  },
  {
    usi_cislo: "014",
    datum_narozeni: "2021-05-12",
    matka: "M014",
    otec: "O002",
    plemeno: "Merino",
    kategorie: "BAH",
    cislo_matky: "M014",
    pohlavi: "Samice", 
    poznamka: "Kvalitní vlna"
  },
  {
    usi_cislo: "015",
    datum_narozeni: "2021-05-28",
    matka: "M015",
    otec: "O003",
    plemeno: "Texel",
    kategorie: "BAH",
    cislo_matky: "M015",
    pohlavi: "Samice",
    poznamka: "Robustní zdraví"
  },
  {
    usi_cislo: "016",
    datum_narozeni: "2020-03-10",
    matka: "M016",
    otec: "O005",
    plemeno: "Charollais",
    kategorie: "BER",
    cislo_matky: "M016",
    pohlavi: "Samec",
    poznamka: "Těžký beran"
  },
  {
    usi_cislo: "017",
    datum_narozeni: "2020-04-22",
    matka: "M017",
    otec: "O005",
    plemeno: "Charollais",
    kategorie: "BAH",
    cislo_matky: "M017",
    pohlavi: "Samice",
    poznamka: "Velká ovce"
  },
  {
    usi_cislo: "018",
    datum_narozeni: "2020-05-05",
    matka: "M018",
    otec: "O001",
    plemeno: "Suffolk",
    kategorie: "BAH", 
    cislo_matky: "M018",
    pohlavi: "Samice",
    poznamka: "Stárnoucí ovce"
  },
  {
    usi_cislo: "019",
    datum_narozeni: "2020-06-18",
    matka: "M019",
    otec: "O002",
    plemeno: "Merino",
    kategorie: "BAH",
    cislo_matky: "M019",
    pohlavi: "Samice",
    poznamka: "Mírná povaha"
  },
  {
    usi_cislo: "020",
    datum_narozeni: "2019-04-15",
    matka: "M020",
    otec: "O006",
    plemeno: "Leicester", 
    kategorie: "BER",
    cislo_matky: "M020",
    pohlavi: "Samec",
    poznamka: "Starší plemenník"
  },
  {
    usi_cislo: "021",
    datum_narozeni: "2019-05-30",
    matka: "M021",
    otec: "O006",
    plemeno: "Leicester",
    kategorie: "BAH",
    cislo_matky: "M021",
    pohlavi: "Samice",
    poznamka: "Veteránka stáda"
  },
  {
    usi_cislo: "022",
    datum_narozeni: "2023-05-15",
    matka: "M007",
    otec: "O001",
    plemeno: "Suffolk",
    kategorie: "JEH",
    cislo_matky: "M007",
    pohlavi: "Samice",
    poznamka: "Mladá jehnice z M007"
  },
  {
    usi_cislo: "023",
    datum_narozeni: "2023-05-15",
    matka: "M007", 
    otec: "O001",
    plemeno: "Suffolk", 
    kategorie: "JEH",
    cislo_matky: "M007",
    pohlavi: "Samec",
    poznamka: "Dvojče k 022"
  },
  {
    usi_cislo: "024",
    datum_narozeni: "2023-06-02",
    matka: "M009",
    otec: "O003",
    plemeno: "Texel",
    kategorie: "JEH",
    cislo_matky: "M009",
    pohlavi: "Samice",
    poznamka: "Pozdní vrh"
  },
  {
    usi_cislo: "025",
    datum_narozeni: "2023-06-20",
    matka: "M012",
    otec: "O004",
    plemeno: "Romney",
    kategorie: "JEH",
    cislo_matky: "M012",
    pohlavi: "Samec",
    poznamka: "Poslední letošní jehně"
  },
  {
    usi_cislo: "026",
    datum_narozeni: "2022-08-10",
    matka: "M013", 
    otec: "O001",
    plemeno: "Suffolk",
    kategorie: "BAH",
    cislo_matky: "M013",
    pohlavi: "Samice",
    poznamka: "Podzimní narození"
  }
];

// POST /api/import-data - Import original sheep data
router.post('/import-data', async (req, res) => {
  try {
    console.log('🚀 Starting data import...');
    
    // Clear existing data first (optional - remove if you want to keep existing)
    const clearExisting = req.body.clearExisting || false;
    if (clearExisting) {
      await Ovce.destroy({ where: {} });
      console.log('🗑️ Cleared existing data');
    }

    const imported = [];
    const skipped = [];
    
    for (const ovcaData of originalData) {
      try {
        // Check if sheep with this usi_cislo already exists
        const existing = await Ovce.findOne({ where: { usi_cislo: ovcaData.usi_cislo } });
        
        if (existing) {
          skipped.push(ovcaData.usi_cislo);
          console.log(`⚠️ Skipped ${ovcaData.usi_cislo} - already exists`);
          continue;
        }

        // Create new sheep
        const ovce = await Ovce.create(ovcaData);
        imported.push(ovce.usi_cislo);
        console.log(`✅ Imported sheep ${ovce.usi_cislo}`);
        
      } catch (error) {
        console.error(`❌ Error importing ${ovcaData.usi_cislo}:`, error.message);
        skipped.push(ovcaData.usi_cislo);
      }
    }

    const total = await Ovce.count();
    
    res.json({
      message: 'Import completed successfully',
      results: {
        imported: imported.length,
        skipped: skipped.length,
        total_in_db: total,
        imported_list: imported,
        skipped_list: skipped
      },
      timestamp: new Date().toISOString()
    });

    console.log(`🎉 Import completed: ${imported.length} imported, ${skipped.length} skipped, ${total} total in DB`);
    
  } catch (error) {
    console.error('❌ Import failed:', error);
    res.status(500).json({
      error: 'Import failed',
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/import-data/preview - Preview data that would be imported
router.get('/import-data/preview', (req, res) => {
  res.json({
    message: 'Preview of data to be imported',
    count: originalData.length,
    data: originalData.map(item => ({
      usi_cislo: item.usi_cislo,
      datum_narozeni: item.datum_narozeni,
      plemeno: item.plemeno,
      kategorie: item.kategorie,
      pohlavi: item.pohlavi
    })),
    timestamp: new Date().toISOString()
  });
});

module.exports = router;