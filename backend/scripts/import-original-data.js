#!/usr/bin/env node

/**
 * Import script for populating Railway database with original sheep data
 * 
 * Usage:
 *   node scripts/import-original-data.js [--clear-existing]
 * 
 * Options:
 *   --clear-existing: Clear all existing data before import
 */

const axios = require('axios');

// Railway API URL
const API_URL = 'https://ovce-databaze-production.up.railway.app/api';

async function importData(clearExisting = false) {
  try {
    console.log('🚀 Starting import to Railway database...');
    console.log(`📡 API URL: ${API_URL}`);
    
    // First, check API status
    console.log('🔍 Checking API status...');
    const statusResponse = await axios.get(`${API_URL}/status`);
    console.log('✅ API is online:', statusResponse.data);
    
    // Preview data first
    console.log('👀 Previewing data to import...');
    const previewResponse = await axios.get(`${API_URL}/import-data/preview`);
    console.log(`📋 Will import ${previewResponse.data.count} sheep records`);
    
    // Perform import
    console.log('📥 Starting import...');
    const importResponse = await axios.post(`${API_URL}/import-data`, {
      clearExisting: clearExisting
    });
    
    console.log('🎉 Import completed successfully!');
    console.log('📊 Results:');
    console.log(`   • Imported: ${importResponse.data.results.imported}`);
    console.log(`   • Skipped: ${importResponse.data.results.skipped}`);
    console.log(`   • Total in DB: ${importResponse.data.results.total_in_db}`);
    
    if (importResponse.data.results.imported_list.length > 0) {
      console.log('✅ Imported sheep:', importResponse.data.results.imported_list.join(', '));
    }
    
    if (importResponse.data.results.skipped_list.length > 0) {
      console.log('⚠️ Skipped sheep:', importResponse.data.results.skipped_list.join(', '));
    }
    
    // Verify by getting all sheep
    console.log('🔍 Verifying import by fetching all sheep...');
    const verifyResponse = await axios.get(`${API_URL}/ovce`);
    console.log(`✅ Verification: Database now contains ${verifyResponse.data.pagination.total} sheep records`);
    
    if (verifyResponse.data.data.length > 0) {
      console.log('📋 Sample records:');
      verifyResponse.data.data.slice(0, 3).forEach(ovce => {
        console.log(`   • ${ovce.usi_cislo}: ${ovce.plemeno} (${ovce.kategorie})`);
      });
    }
    
  } catch (error) {
    console.error('❌ Import failed:', error.message);
    
    if (error.response) {
      console.error('📄 Response data:', error.response.data);
      console.error('🔢 Status code:', error.response.status);
    }
    
    process.exit(1);
  }
}

// Parse command line arguments
const args = process.argv.slice(2);
const clearExisting = args.includes('--clear-existing');

if (clearExisting) {
  console.log('⚠️ WARNING: This will clear all existing data first!');
}

// Run import
importData(clearExisting)
  .then(() => {
    console.log('✅ Import script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Import script failed:', error);
    process.exit(1);
  });