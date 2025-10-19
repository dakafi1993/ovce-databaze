const { sequelize } = require('../config/database');
const Ovce = require('../models/Ovce');

const testData = [
  {
    usi_cislo: 'CZ001',
    datum_narozeni: '2023-03-15',
    matka: 'CZ999',
    otec: 'CZ998',
    plemeno: 'Merinolandschaf',
    kategorie: 'BER',
    cislo_matky: 'M001',
    pohlavi: 'F',
    poznamka: 'Zdravá ovce, bez problémů',
    recognition_accuracy: 0.85,
    is_trained_for_recognition: true
  },
  {
    usi_cislo: 'CZ002',
    datum_narozeni: '2023-04-20',
    matka: 'CZ997',
    otec: 'CZ996',
    plemeno: 'Suffolk',
    kategorie: 'BAH',
    cislo_matky: 'M002',
    pohlavi: 'M',
    poznamka: 'Silný beran, vhodný pro chov',
    recognition_accuracy: 0.92,
    is_trained_for_recognition: true
  },
  {
    usi_cislo: 'CZ003',
    datum_narozeni: '2024-01-10',
    matka: 'CZ001',
    otec: 'CZ002',
    plemeno: 'Křížení Merino x Suffolk',
    kategorie: 'JEH',
    cislo_matky: 'M003',
    pohlavi: 'F',
    poznamka: 'Mladé jehně, rychle roste',
    recognition_accuracy: 0.65,
    is_trained_for_recognition: false
  },
  {
    usi_cislo: 'CZ004',
    datum_narozeni: '2022-12-05',
    matka: 'CZ995',
    otec: 'CZ994',
    plemeno: 'Charollais',
    kategorie: 'BER',
    cislo_matky: 'M004',
    pohlavi: 'F',
    poznamka: 'Matka více jehňat, výborná mléčnost',
    recognition_accuracy: 0.78,
    is_trained_for_recognition: true
  },
  {
    usi_cislo: 'CZ005',
    datum_narozeni: '2023-08-30',
    matka: 'CZ993',
    otec: 'CZ992',
    plemeno: 'Texel',
    kategorie: 'OTHER',
    cislo_matky: 'M005',
    pohlavi: 'M',
    poznamka: 'Mladý beran, připravuje se na chov',
    recognition_accuracy: 0.71,
    is_trained_for_recognition: false
  }
];

async function seed() {
  try {
    console.log('🌱 Starting database seeding...');
    
    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connection established.');
    
    // Check if data already exists
    const existingCount = await Ovce.count();
    if (existingCount > 0) {
      console.log(`ℹ️  Database already contains ${existingCount} records. Skipping seed.`);
      process.exit(0);
    }
    
    // Insert test data
    for (const ovceData of testData) {
      await Ovce.create(ovceData);
      console.log(`✅ Created sheep: ${ovceData.usi_cislo}`);
    }
    
    console.log(`🎉 Successfully seeded ${testData.length} sheep records!`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  }
}

seed();