const express = require('express');
const multer = require('multer');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs').promises;
const { v4: uuidv4 } = require('uuid');
const Ovce = require('../models/Ovce');

const router = express.Router();

// Ensure upload directories exist
const uploadsDir = path.join(__dirname, '../uploads');
const photosDir = path.join(uploadsDir, 'photos');
const thumbnailsDir = path.join(uploadsDir, 'thumbnails');

async function ensureDirectories() {
  try {
    await fs.mkdir(uploadsDir, { recursive: true });
    await fs.mkdir(photosDir, { recursive: true });
    await fs.mkdir(thumbnailsDir, { recursive: true });
  } catch (error) {
    console.error('Error creating upload directories:', error);
  }
}

ensureDirectories();

// Multer configuration
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only JPEG, PNG and WebP are allowed.'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
    files: 5 // Max 5 files at once
  }
});

// Helper function to process and save image
async function processAndSaveImage(buffer, filename, usiCislo) {
  try {
    // Create subdirectory for this sheep
    const sheepDir = path.join(photosDir, usiCislo);
    const thumbnailSheepDir = path.join(thumbnailsDir, usiCislo);
    
    await fs.mkdir(sheepDir, { recursive: true });
    await fs.mkdir(thumbnailSheepDir, { recursive: true });

    // Process main image (max 1920x1920, 85% quality)
    const mainImagePath = path.join(sheepDir, filename);
    await sharp(buffer)
      .resize(1920, 1920, { 
        fit: 'inside',
        withoutEnlargement: true 
      })
      .jpeg({ quality: 85 })
      .toFile(mainImagePath);

    // Create thumbnail (300x300)
    const thumbnailFilename = `thumb_${filename}`;
    const thumbnailPath = path.join(thumbnailSheepDir, thumbnailFilename);
    await sharp(buffer)
      .resize(300, 300, { 
        fit: 'cover',
        position: 'center'
      })
      .jpeg({ quality: 70 })
      .toFile(thumbnailPath);

    // Return URLs relative to server
    const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
    return {
      original: `${baseUrl}/photos/${usiCislo}/${filename}`,
      thumbnail: `${baseUrl}/photos/${usiCislo}/thumbnails/${thumbnailFilename}`
    };
  } catch (error) {
    console.error('Error processing image:', error);
    throw error;
  }
}

// POST /api/upload-photo - Upload single photo
router.post('/upload-photo', upload.single('photo'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        error: 'No photo file provided',
        timestamp: new Date().toISOString()
      });
    }

    const { usi_cislo } = req.body;
    if (!usi_cislo) {
      return res.status(400).json({
        error: 'usi_cislo is required',
        timestamp: new Date().toISOString()
      });
    }

    // Check if sheep exists
    const ovce = await Ovce.findByUsiCislo(usi_cislo);
    if (!ovce) {
      return res.status(404).json({
        error: 'Sheep not found',
        usi_cislo,
        timestamp: new Date().toISOString()
      });
    }

    // Generate unique filename
    const timestamp = Date.now();
    const uuid = uuidv4().substring(0, 8);
    const filename = `${timestamp}_${uuid}.jpg`;

    // Process and save image
    const urls = await processAndSaveImage(req.file.buffer, filename, usi_cislo);

    // Update sheep record with new photo URL
    ovce.addPhoto(urls.original);
    await ovce.save();

    res.json({
      photo_url: urls.original,
      thumbnail_url: urls.thumbnail,
      filename,
      size: req.file.size,
      message: 'Photo uploaded successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error uploading photo:', error);
    
    if (error.message.includes('Invalid file type')) {
      return res.status(400).json({
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }

    res.status(500).json({
      error: 'Failed to upload photo',
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// POST /api/upload-photos - Upload multiple photos
router.post('/upload-photos', upload.array('photos', 5), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        error: 'No photo files provided',
        timestamp: new Date().toISOString()
      });
    }

    const { usi_cislo } = req.body;
    if (!usi_cislo) {
      return res.status(400).json({
        error: 'usi_cislo is required',
        timestamp: new Date().toISOString()
      });
    }

    // Check if sheep exists
    const ovce = await Ovce.findByUsiCislo(usi_cislo);
    if (!ovce) {
      return res.status(404).json({
        error: 'Sheep not found',
        usi_cislo,
        timestamp: new Date().toISOString()
      });
    }

    const uploadResults = [];
    const errors = [];

    // Process each file
    for (const file of req.files) {
      try {
        const timestamp = Date.now();
        const uuid = uuidv4().substring(0, 8);
        const filename = `${timestamp}_${uuid}.jpg`;

        const urls = await processAndSaveImage(file.buffer, filename, usi_cislo);
        
        ovce.addPhoto(urls.original);
        
        uploadResults.push({
          photo_url: urls.original,
          thumbnail_url: urls.thumbnail,
          filename,
          size: file.size,
          originalName: file.originalname
        });
      } catch (error) {
        errors.push({
          filename: file.originalname,
          error: error.message
        });
      }
    }

    // Save updated sheep record
    await ovce.save();

    res.json({
      uploaded: uploadResults,
      errors,
      total_uploaded: uploadResults.length,
      total_errors: errors.length,
      message: `Successfully uploaded ${uploadResults.length} photos`,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error uploading photos:', error);
    res.status(500).json({
      error: 'Failed to upload photos',
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// DELETE /api/delete-photo - Delete photo
router.delete('/delete-photo', async (req, res) => {
  try {
    const { photo_url, usi_cislo } = req.body;

    if (!photo_url) {
      return res.status(400).json({
        error: 'photo_url is required',
        timestamp: new Date().toISOString()
      });
    }

    // Extract filename from URL
    const urlParts = photo_url.split('/');
    const filename = urlParts[urlParts.length - 1];
    const sheepId = urlParts[urlParts.length - 2];

    if (usi_cislo && sheepId !== usi_cislo) {
      return res.status(400).json({
        error: 'usi_cislo mismatch',
        timestamp: new Date().toISOString()
      });
    }

    // Delete physical files
    const mainPhotoPath = path.join(photosDir, sheepId, filename);
    const thumbnailPath = path.join(thumbnailsDir, sheepId, `thumb_${filename}`);

    try {
      await fs.unlink(mainPhotoPath);
      console.log('Deleted main photo:', mainPhotoPath);
    } catch (error) {
      console.warn('Could not delete main photo:', error.message);
    }

    try {
      await fs.unlink(thumbnailPath);
      console.log('Deleted thumbnail:', thumbnailPath);
    } catch (error) {
      console.warn('Could not delete thumbnail:', error.message);
    }

    // Update sheep record
    if (usi_cislo) {
      const ovce = await Ovce.findByUsiCislo(usi_cislo);
      if (ovce) {
        ovce.removePhoto(photo_url);
        await ovce.save();
      }
    }

    res.json({
      message: 'Photo deleted successfully',
      photo_url,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error deleting photo:', error);
    res.status(500).json({
      error: 'Failed to delete photo',
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/photos/:usiCislo - Get all photos for a sheep
router.get('/photos/:usiCislo', async (req, res) => {
  try {
    const { usiCislo } = req.params;
    
    const ovce = await Ovce.findByUsiCislo(usiCislo);
    if (!ovce) {
      return res.status(404).json({
        error: 'Sheep not found',
        usi_cislo: usiCislo,
        timestamp: new Date().toISOString()
      });
    }

    res.json({
      usi_cislo: usiCislo,
      photos: ovce.fotky || [],
      count: (ovce.fotky || []).length,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error fetching photos:', error);
    res.status(500).json({
      error: 'Failed to fetch photos',
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;