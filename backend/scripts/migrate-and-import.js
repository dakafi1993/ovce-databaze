#!/usr/bin/env node

// Vytvoříme vlastní instanci Sequelize pro migraci, aby jsme nezavřeli hlavní connection pool
const { Sequelize, DataTypes } = require('sequelize');

// Vlastní Sequelize instance pro migration
const migrationSequelize = new Sequelize(process.env.DATABASE_URL, {
  dialect: 'postgres',
  protocol: 'postgres',
  dialectOptions: {
    ssl: process.env.NODE_ENV === 'production' ? {
      require: true,
      rejectUnauthorized: false
    } : false
  },
  logging: console.log
});

// Definujeme model Ovce pro migration
const Ovce = migrationSequelize.define('Ovce', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  usi_cislo: {
    type: DataTypes.STRING(50),
    allowNull: false,
    unique: true,
    validate: {
      notEmpty: true,
      len: [1, 50]
    }
  },
  datum_narozeni: {
    type: DataTypes.DATEONLY,
    allowNull: false,
    validate: {
      isDate: true,
      isBefore: new Date().toISOString()
    }
  },
  matka: {
    type: DataTypes.STRING(50),
    allowNull: true,
    defaultValue: ''
  },
  otec: {
    type: DataTypes.STRING(50),
    allowNull: true,
    defaultValue: ''
  },
  plemeno: {
    type: DataTypes.STRING(100),
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [1, 100]
    }
  },
  kategorie: {
    type: DataTypes.ENUM('BER', 'BAH', 'JEH', 'OTHER'),
    allowNull: false,
    defaultValue: 'OTHER'
  },
  cislo_matky: {
    type: DataTypes.STRING(20),
    allowNull: true,
    defaultValue: ''
  },
  cislo_otce: {
    type: DataTypes.STRING(20),
    allowNull: true,
    defaultValue: ''
  },
  poznamky: {
    type: DataTypes.TEXT,
    allowNull: true,
    defaultValue: ''
  },
  fotky: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: []
  },
  biometric_data: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: null
  }
}, {
  tableName: 'Ovces',
  timestamps: true
});

// Import data
const sheepData = [
  {
    usi_cislo: "CZ0123456789",
    datum_narozeni: "2023-03-15",
    matka: "CZ0987654321",
    otec: "CZ0111222333",
    plemeno: "Berrichon du Cher",
    kategorie: "BER",
    cislo_matky: "001",
    cislo_otce: "002",
    poznamky: "Kvalitní plemenná ovce"
  },
  {
    usi_cislo: "CZ0234567890",
    datum_narozeni: "2023-04-22",
    matka: "CZ0888999000",
    otec: "CZ0444555666",
    plemeno: "Bílá hornická",
    kategorie: "BAH",
    cislo_matky: "003",
    cislo_otce: "004",
    poznamky: "Dobrá mléčnost"
  },
  {
    usi_cislo: "CZ0345678901",
    datum_narozeni: "2023-05-10",
    matka: "CZ0777888999",
    otec: "CZ0333444555",
    plemeno: "Jehnce",
    kategorie: "JEH",
    cislo_matky: "005",
    cislo_otce: "006",
    poznamky: "Mladé jehně"
  },
  {
    usi_cislo: "CZ0456789012",
    datum_narozeni: "2022-06-18",
    matka: "CZ0666777888",
    otec: "CZ0222333444",
    plemeno: "Berrichon du Cher",
    kategorie: "BER",
    cislo_matky: "007",
    cislo_otce: "008",
    poznamky: "Silná stavba těla"
  },
  {
    usi_cislo: "CZ0567890123",
    datum_narozeni: "2022-07-25",
    matka: "CZ0555666777",
    otec: "CZ0111222333",
    plemeno: "Bílá hornická",
    kategorie: "BAH",
    cislo_matky: "009",
    cislo_otce: "002",
    poznamky: "Vysoká užitkovost"
  },
  {
    usi_cislo: "CZ0678901234",
    datum_narozeni: "2023-08-12",
    matka: "CZ0444555666",
    otec: "CZ0777888999",
    plemeno: "Jehnce",
    kategorie: "JEH",
    cislo_matky: "010",
    cislo_otce: "011",
    poznamky: "Rychlý růst"
  },
  {
    usi_cislo: "CZ0789012345",
    datum_narozeni: "2022-09-20",
    matka: "CZ0333444555",
    otec: "CZ0666777888",
    plemeno: "Berrichon du Cher",
    kategorie: "BER",
    cislo_matky: "012",
    cislo_otce: "013",
    poznamky: "Odolná vůči nemocem"
  },
  {
    usi_cislo: "CZ0890123456",
    datum_narozeni: "2023-10-03",
    matka: "CZ0222333444",
    otec: "CZ0555666777",
    plemeno: "Bílá hornická",
    kategorie: "BAH",
    cislo_matky: "014",
    cislo_otce: "015",
    poznamky: "Vynikající matka"
  },
  {
    usi_cislo: "CZ0901234567",
    datum_narozeni: "2023-11-16",
    matka: "CZ0111222333",
    otec: "CZ0444555666",
    plemeno: "Jehnce",
    kategorie: "JEH",
    cislo_matky: "016",
    cislo_otce: "017",
    poznamky: "Aktivní jehnče"
  },
  {
    usi_cislo: "CZ1012345678",
    datum_narozeni: "2022-12-28",
    matka: "CZ0777888999",
    otec: "CZ0333444555",
    plemeno: "Berrichon du Cher",
    kategorie: "BER",
    cislo_matky: "018",
    cislo_otce: "019",
    poznamky: "Vhodná pro chov"
  },
  {
    usi_cislo: "CZ1123456789",
    datum_narozeni: "2023-01-14",
    matka: "CZ0666777888",
    otec: "CZ0222333444",
    plemeno: "Bílá hornická",
    kategorie: "BAH",
    cislo_matky: "020",
    cislo_otce: "021",
    poznamky: "Dobré zdraví"
  },
  {
    usi_cislo: "CZ1234567890",
    datum_narozeni: "2023-02-27",
    matka: "CZ0555666777",
    otec: "CZ0111222333",
    plemeno: "Jehnce",
    kategorie: "JEH",
    cislo_matky: "022",
    cislo_otce: "023",
    poznamky: "Perspektivní jehnče"
  },
  {
    usi_cislo: "CZ1345678901",
    datum_narozeni: "2022-04-05",
    matka: "CZ0444555666",
    otec: "CZ0777888999",
    plemeno: "Berrichon du Cher",
    kategorie: "BER",
    cislo_matky: "024",
    cislo_otce: "025",
    poznamky: "Robustní konstituci"
  },
  {
    usi_cislo: "CZ1456789012",
    datum_narozeni: "2022-05-19",
    matka: "CZ0333444555",
    otec: "CZ0666777888",
    plemeno: "Bílá hornická",
    kategorie: "BAH",
    cislo_matky: "026",
    cislo_otce: "027",
    poznamky: "Kvalitní vlna"
  },
  {
    usi_cislo: "CZ1567890123",
    datum_narozeni: "2023-06-30",
    matka: "CZ0222333444",
    otec: "CZ0555666777",
    plemeno: "Jehnce",
    kategorie: "JEH",
    cislo_matky: "028",
    cislo_otce: "029",
    poznamky: "Zdravé jehnče"
  },
  {
    usi_cislo: "CZ1678901234",
    datum_narozeni: "2022-08-11",
    matka: "CZ0111222333",
    otec: "CZ0444555666",
    plemeno: "Berrichon du Cher",
    kategorie: "BER",
    cislo_matky: "030",
    cislo_otce: "031",
    poznamky: "Vynikající růst"
  },
  {
    usi_cislo: "CZ1789012345",
    datum_narozeni: "2022-09-24",  
    matka: "CZ0777888999",
    otec: "CZ0333444555",
    plemeno: "Bílá hornická",
    kategorie: "BAH",
    cislo_matky: "032",
    cislo_otce: "033",
    poznamky: "Dobré mateřské vlastnosti"
  },
  {
    usi_cislo: "CZ1890123456",
    datum_narozeni: "2023-10-15",
    matka: "CZ0666777888",
    otec: "CZ0222333444",
    plemeno: "Jehnce",
    kategorie: "JEH",
    cislo_matky: "034",
    cislo_otce: "035",
    poznamky: "Aktivní a zdravé"
  },
  {
    usi_cislo: "CZ1901234567",
    datum_narozeni: "2022-11-07",
    matka: "CZ0555666777",
    otec: "CZ0111222333",
    plemeno: "Berrichon du Cher",
    kategorie: "BER",
    cislo_matky: "036",
    cislo_otce: "037", 
    poznamky: "Plemenný samec"
  },
  {
    usi_cislo: "CZ2012345678",
    datum_narozeni: "2023-12-21",
    matka: "CZ0444555666",
    otec: "CZ0777888999",
    plemeno: "Bílá hornická",
    kategorie: "BAH",
    cislo_matky: "038",
    cislo_otce: "039",
    poznamky: "Zimní jehně"
  },
  {
    usi_cislo: "CZ2123456789",
    datum_narozeni: "2023-01-08",
    matka: "CZ0333444555",
    otec: "CZ0666777888",
    plemeno: "Jehnce",
    kategorie: "JEH",
    cislo_matky: "040",
    cislo_otce: "041",
    poznamky: "Novorozeně"
  },
  {
    usi_cislo: "CZ2234567890",
    datum_narozeni: "2022-03-02",
    matka: "CZ0222333444",
    otec: "CZ0555666777",
    plemeno: "Berrichon du Cher",
    kategorie: "BER",
    cislo_matky: "042",
    cislo_otce: "043",
    poznamky: "Jarní jehně"
  },
  {
    usi_cislo: "CZ2345678901",
    datum_narozeni: "2022-04-17",
    matka: "CZ0111222333",
    otec: "CZ0444555666",
    plemeno: "Bílá hornická",
    kategorie: "BAH",
    cislo_matky: "044",
    cislo_otce: "045",
    poznamky: "Silné jehně"
  },
  {
    usi_cislo: "CZ2456789012",
    datum_narozeni: "2023-05-29",
    matka: "CZ0777888999",
    otec: "CZ0333444555",
    plemeno: "Jehnce",
    kategorie: "JEH",
    cislo_matky: "046",
    cislo_otce: "047",
    poznamky: "Květnové jehně"
  },
  {
    usi_cislo: "CZ2567890123",
    datum_narozeni: "2022-07-13",
    matka: "CZ0666777888",
    otec: "CZ0222333444",
    plemeno: "Berrichon du Cher",
    kategorie: "BER",
    cislo_matky: "048",
    cislo_otce: "049",
    poznamky: "Letní jehně"
  },
  {
    usi_cislo: "CZ2678901234",
    datum_narozeni: "2023-08-26",
    matka: "CZ0555666777",
    otec: "CZ0111222333",
    plemeno: "Bílá hornická",
    kategorie: "BAH",
    cislo_matky: "050",
    cislo_otce: "051",
    poznamky: "Poslední v sezóně"
  }
];

async function migrateAndImport() {
  try {
    console.log('🔄 Připojuji se k databázi...');
    await migrationSequelize.authenticate();
    console.log('✅ Připojení k databázi úspěšné');

    console.log('🔄 Synchronizuji tabulky...');
    // force: true vytvoří tabulky od začátku (v prázdné DB je to bezpečné)
    await migrationSequelize.sync({ force: true });
    console.log('✅ Tabulky úspěšně vytvořeny');

    console.log('🔄 Importuji testovací data...');
    const imported = await Ovce.bulkCreate(sheepData, {
      validate: true,
      ignoreDuplicates: true
    });
    
    console.log(`✅ Úspěšně naimportováno ${imported.length} ovcí`);
    
    // Ověření
    const count = await Ovce.count();
    console.log(`📊 Celkem v databázi: ${count} ovcí`);
    
    // Ukázka podle kategorií
    const berCount = await Ovce.count({ where: { kategorie: 'BER' } });
    const bahCount = await Ovce.count({ where: { kategorie: 'BAH' } });
    const jehCount = await Ovce.count({ where: { kategorie: 'JEH' } });
    
    console.log(`📊 Kategorie: BER(${berCount}), BAH(${bahCount}), JEH(${jehCount})`);
    console.log('🎉 Migration a import úspěšně dokončen!');
    
  } catch (error) {
    console.error('❌ Chyba během migration/import:', error);
    throw error;
  } finally {
    await migrationSequelize.close();
  }
}

// Spustit pouze pokud je soubor spuštěn přímo
if (require.main === module) {
  migrateAndImport()
    .then(() => {
      console.log('✅ Script dokončen');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Script selhal:', error);
      process.exit(1);
    });
}

module.exports = migrateAndImport;