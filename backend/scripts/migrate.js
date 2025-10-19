const { sequelize } = require('../config/database');
const Ovce = require('../models/Ovce');

async function migrate() {
  try {
    console.log('🔄 Starting database migration...');
    
    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connection established.');
    
    // Sync all models
    await sequelize.sync({ 
      force: false, // Don't drop existing tables
      alter: true   // Modify existing tables to match models
    });
    console.log('✅ Database models synchronized.');
    
    // Create indexes if they don't exist
    await sequelize.query(`
      CREATE INDEX IF NOT EXISTS idx_ovce_usi_cislo ON ovce (usi_cislo);
      CREATE INDEX IF NOT EXISTS idx_ovce_plemeno ON ovce (plemeno);
      CREATE INDEX IF NOT EXISTS idx_ovce_kategorie ON ovce (kategorie);
      CREATE INDEX IF NOT EXISTS idx_ovce_datum_narozeni ON ovce (datum_narozeni);
    `);
    console.log('✅ Database indexes created.');
    
    console.log('🎉 Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrate();