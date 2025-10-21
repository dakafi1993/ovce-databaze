const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Ovce = sequelize.define('Ovce', {
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
    type: DataTypes.STRING(50),
    allowNull: true,
    defaultValue: ''
  },
  pohlavi: {
    type: DataTypes.ENUM('Samec', 'Samice', 'Nezn'),
    allowNull: false,
    defaultValue: 'Nezn'
  },
  poznamka: {
    type: DataTypes.TEXT,
    allowNull: true,
    defaultValue: ''
  },
  fotky: {
    type: DataTypes.ARRAY(DataTypes.TEXT),
    allowNull: true,
    defaultValue: []
  },
  datum_registrace: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  biometrics: {
    type: DataTypes.JSONB,
    allowNull: true,
    defaultValue: null
  },
  reference_photos: {
    type: DataTypes.ARRAY(DataTypes.TEXT),
    allowNull: true,
    defaultValue: []
  },
  recognition_history: {
    type: DataTypes.JSONB,
    allowNull: true,
    defaultValue: {}
  },
  recognition_accuracy: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 0.0,
    validate: {
      min: 0.0,
      max: 1.0
    }
  },
  is_trained_for_recognition: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  }
}, {
  tableName: 'ovce',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    {
      unique: true,
      fields: ['usi_cislo']
    },
    {
      fields: ['plemeno']
    },
    {
      fields: ['kategorie']
    },
    {
      fields: ['datum_narozeni']
    },
    {
      fields: ['is_trained_for_recognition']
    }
  ]
});

// Instance methods
Ovce.prototype.getAge = function() {
  const today = new Date();
  const birthDate = new Date(this.datum_narozeni);
  let age = today.getFullYear() - birthDate.getFullYear();
  const monthDiff = today.getMonth() - birthDate.getMonth();
  
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
    age--;
  }
  
  return age;
};

Ovce.prototype.hasGoodBiometrics = function() {
  return this.biometrics && 
         this.biometrics.confidence > 0.7 && 
         this.biometrics.trainingPhotosCount >= 3;
};

Ovce.prototype.addPhoto = function(photoUrl) {
  const photos = this.fotky || [];
  if (!photos.includes(photoUrl)) {
    photos.push(photoUrl);
    this.fotky = photos;
  }
};

Ovce.prototype.removePhoto = function(photoUrl) {
  const photos = this.fotky || [];
  this.fotky = photos.filter(photo => photo !== photoUrl);
};

// Class methods
Ovce.findByUsiCislo = function(usiCislo) {
  return this.findOne({ where: { usi_cislo: usiCislo } });
};

Ovce.findByPlemeno = function(plemeno) {
  return this.findAll({ where: { plemeno } });
};

Ovce.findTrainedForRecognition = function() {
  return this.findAll({ where: { is_trained_for_recognition: true } });
};

module.exports = Ovce;