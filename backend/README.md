# Ovce Databáze - Backend API

REST API server for sheep farm management system built with Node.js, Express, and PostgreSQL.

## 🚀 Features

- **Complete CRUD operations** for sheep data
- **Photo upload and management** with automatic optimization
- **Thumbnail generation** for fast loading
- **PostgreSQL database** with Sequelize ORM
- **Data validation** and error handling
- **CORS support** for Flutter mobile app
- **Ready for Railway deployment**

## 📋 API Endpoints

### Sheep Management
- `GET /api/ovce` - Get all sheep (with pagination, filtering, sorting)
- `GET /api/ovce/:id` - Get specific sheep
- `POST /api/ovce` - Create new sheep
- `PUT /api/ovce/:id` - Update sheep
- `DELETE /api/ovce/:id` - Delete sheep
- `GET /api/ovce/stats/summary` - Get statistics

### Photo Management
- `POST /api/upload-photo` - Upload single photo
- `POST /api/upload-photos` - Upload multiple photos
- `DELETE /api/delete-photo` - Delete photo
- `GET /api/photos/:usiCislo` - Get all photos for a sheep

### System
- `GET /health` - Health check
- `GET /api/status` - API status and database connection

## 🛠️ Local Development

### Prerequisites
- Node.js 18+
- PostgreSQL 12+
- npm or yarn

### Setup

1. **Install dependencies:**
   ```bash
   cd backend
   npm install
   ```

2. **Setup PostgreSQL database:**
   ```sql
   CREATE DATABASE ovce_databaze_dev;
   CREATE USER postgres WITH PASSWORD 'password';
   GRANT ALL PRIVILEGES ON DATABASE ovce_databaze_dev TO postgres;
   ```

3. **Create environment file:**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

4. **Run database migrations:**
   ```bash
   npm run migrate
   ```

5. **Start development server:**
   ```bash
   npm run dev
   ```

The API will be available at `http://localhost:3000`

### Testing the API

```bash
# Check API status
curl http://localhost:3000/api/status

# Get all sheep
curl http://localhost:3000/api/ovce

# Create new sheep
curl -X POST http://localhost:3000/api/ovce \
  -H "Content-Type: application/json" \
  -d '{
    "usi_cislo": "12345",
    "datum_narozeni": "2023-01-01",
    "plemeno": "Merinolandschaf",
    "kategorie": "BER",
    "pohlavi": "F"
  }'
```

## 🌐 Railway Deployment

### Automatic Deployment

1. **Connect your repository to Railway**
2. **Add PostgreSQL service** in Railway dashboard
3. **Environment variables** are automatically set by Railway
4. **Deploy** - Railway will automatically build and deploy

### Manual Environment Setup

If needed, set these environment variables in Railway:

```
NODE_ENV=production
BASE_URL=https://your-app.railway.app
```

### Database Migration

Railway will automatically run migrations on deployment. For manual migration:

```bash
railway run npm run migrate
```

## 📊 Database Schema

### Ovce Table
```sql
CREATE TABLE ovce (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usi_cislo VARCHAR(50) UNIQUE NOT NULL,
  datum_narozeni DATE NOT NULL,
  matka VARCHAR(50),
  otec VARCHAR(50),
  plemeno VARCHAR(100) NOT NULL,
  kategorie VARCHAR(10) DEFAULT 'OTHER',
  cislo_matky VARCHAR(50),
  pohlavi VARCHAR(10) DEFAULT 'UNKNOWN',
  poznamka TEXT,
  fotky TEXT[],
  datum_registrace TIMESTAMP DEFAULT NOW(),
  biometrics JSONB,
  reference_photos TEXT[],
  recognition_history JSONB DEFAULT '{}',
  recognition_accuracy FLOAT DEFAULT 0.0,
  is_trained_for_recognition BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

## 📸 Photo Storage

Photos are stored in the following structure:
```
uploads/
├── photos/
│   └── {usi_cislo}/
│       ├── photo1.jpg
│       └── photo2.jpg
└── thumbnails/
    └── {usi_cislo}/
        ├── thumb_photo1.jpg
        └── thumb_photo2.jpg
```

## 🔐 Security Features

- **Helmet.js** for security headers
- **CORS** configured for Flutter app
- **Rate limiting** (100 requests per 15 minutes)
- **File type validation** for uploads
- **SQL injection protection** via Sequelize ORM
- **Input validation** with express-validator

## 📝 Error Handling

All API responses follow this structure:

### Success Response
```json
{
  "data": {...},
  "message": "Success message",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Error Response
```json
{
  "error": "Error message",
  "details": "Detailed error information",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## 🚀 Production Considerations

- **Environment variables** are properly configured
- **Database connection pooling** is enabled
- **Error logging** is implemented
- **Graceful shutdown** handling
- **Health checks** for monitoring
- **Image optimization** for performance
- **GZIP compression** enabled

## 📞 Support

For issues and questions, check:
1. API status endpoint: `/api/status`
2. Health check endpoint: `/health`
3. Application logs in Railway dashboard
4. Database connection in Railway PostgreSQL service