// server.js (merged)

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

/* -------------------------- Process-level safeguards -------------------------- */
// Handle unhandled promise rejections to prevent crashes
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  // Intentionally do not exit; just log
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  // Intentionally do not exit; just log
});

/* --------------------------------- Routes --------------------------------- */
const translationRoutes = require('./routes/translation');
const transportationRoutes = require('./routes/transportation');
const recommendationsRoutes = require('./routes/recommendations');
const scamPreventionRoutes = require('./routes/scamPrevention');
const currencyRoutes = require('./routes/currency');

const app = express();
const PORT = process.env.PORT || 3000;

/* ----------------------------- Security & Ops ----------------------------- */

// Security headers
app.use(helmet());

// CORS
const devAllowedOrigins = [
  'http://localhost:3000',
  'http://localhost:3001',
  'http://127.0.0.1:3000',
  'http://127.0.0.1:5500',
];

const prodAllowedOrigins = (() => {
  // Allow comma-separated list via env, else fallback
  if (process.env.FRONTEND_ORIGINS) {
    return process.env.FRONTEND_ORIGINS.split(',').map((s) => s.trim());
  }
  return ['https://your-frontend-domain.com'];
})();

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow same-origin / non-browser like curl/postman (no Origin header)
      if (!origin) return callback(null, true);

      if (process.env.NODE_ENV === 'production') {
        return prodAllowedOrigins.includes(origin)
          ? callback(null, true)
          : callback(new Error('Not allowed by CORS'));
      }

      // Development: allow common localhost origins and file:// (null origin string some tools send)
      if (origin === 'null' || devAllowedOrigins.includes(origin)) {
        return callback(null, true);
      }

      // Fallback in non-production: allow anything to ease local dev
      if (process.env.NODE_ENV !== 'production') {
        return callback(null, true);
      }

      return callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
  })
);

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 15 * 60 * 1000, // 15 min
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS, 10) || 100,
  message: {
    error: 'Too many requests from this IP, please try again later.',
    retryAfter: Math.ceil(
      (parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 15 * 60 * 1000) / 1000
    ),
  },
});
app.use(limiter);

// Parsers & compression
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(compression());

// Logging
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

/* --------------------------------- Routes --------------------------------- */
app.use('/api/translation', translationRoutes);
app.use('/api/transportation', transportationRoutes);
app.use('/api/recommendations', recommendationsRoutes);
app.use('/api/scam-prevention', scamPreventionRoutes);
app.use('/api/currency', currencyRoutes);

/* ------------------------------- Root Index ------------------------------- */
app.get('/', (req, res) => {
  res.json({
    message: 'AI Travel Assistant API',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      // Translation
      translation: '/api/translation',
      test: '/api/translation/test',
      languages: '/api/translation/languages',
      chatflows: '/api/translation/chatflows',
      textToSpeech: '/api/translation/text-to-speech',
      translateAndSpeak: '/api/translation/translate-and-speak',
      audioTranslateSpeak: '/api/translation/audio-translate-speak',
      voices: '/api/translation/voices',
      ttsLanguages: '/api/translation/tts-languages',

      // Transportation
      transportation: '/api/transportation',
      transportationOptions: '/api/transportation/options',
      transportationRealtime: '/api/transportation/realtime',
      transportationDirections: '/api/transportation/directions',
      transportationStatus: '/api/transportation/status',
      transportationHelp: '/api/transportation/help',

      // Recommendations
      recommendations: '/api/recommendations',
      personalizedRecommendations: '/api/recommendations/personalized',
      culturalEtiquette: '/api/recommendations/cultural-etiquette',
      comprehensiveRecommendations: '/api/recommendations/comprehensive',
      recommendationsTest: '/api/recommendations/test',
      recommendationsHealth: '/api/recommendations/health',
      recommendationsInterests: '/api/recommendations/interests',

      // Scam Prevention
      scamPrevention: '/api/scam-prevention',
      priceAdvice: '/api/scam-prevention/price-advice',
      scamDetection: '/api/scam-prevention/detect',
      safetyAdvice: '/api/scam-prevention/advice',
      scamPreventionTest: '/api/scam-prevention/test',
      redFlags: '/api/scam-prevention/red-flags',
      scamPreventionHealth: '/api/scam-prevention/health',

      // Currency
      currency: '/api/currency',
      currencyConvert: '/api/currency/convert',
      currencyExchangeRates: '/api/currency/exchange-rates',
      currencyInfo: '/api/currency/info/:currency',
      currencyMarketInsights: '/api/currency/market-insights',
      currencySupported: '/api/currency/supported',
      currencyHealth: '/api/currency/health',
      currencyTest: '/api/currency/test',
    },
    quickTest: {
      translation: {
        method: 'POST',
        url: '/api/translation/test',
        body: {
          message: 'Hello, how are you?',
          sourceLanguage: 'en',
          targetLanguage: 'es',
          chatflowId: 'your-chatflow-id-here',
        },
      },
      textToSpeech: {
        method: 'POST',
        url: '/api/translation/text-to-speech',
        body: {
          text: 'Hello, this is a test of text-to-speech!',
          languageCode: 'en-US',
          audioFormat: 'mp3',
        },
      },
      translateAndSpeak: {
        method: 'POST',
        url: '/api/translation/translate-and-speak',
        body: {
          message: 'Hello, how are you?',
          sourceLanguage: 'en',
          targetLanguage: 'es',
          chatflowId: 'your-chatflow-id-here',
          audioFormat: 'mp3',
        },
      },
      recommendations: {
        method: 'POST',
        url: '/api/recommendations/test',
        body: {
          location: 'Paris, France',
          interests: ['culture', 'food'],
          budget: 'medium',
          chatflowId: 'your-recommendations-chatflow-id-here',
        },
      },
      scamPrevention: {
        method: 'POST',
        url: '/api/scam-prevention/test',
        body: {
          testType: 'price',
          chatflowId: '07afcffe-f864-4a73-8a28-9cbf096919e5',
        },
      },
      currency: {
        method: 'POST',
        url: '/api/currency/convert',
        body: {
          amount: 100,
          fromCurrency: 'USD',
          toCurrency: 'EUR',
        },
      },
    },
  });
});

/* ------------------------------ 404 Handler ------------------------------- */
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    message: `The requested endpoint ${req.originalUrl} does not exist`,
    availableEndpoints: [
      'GET /',

      // Translation
      'POST /api/translation/text',
      'POST /api/translation/test',
      'GET /api/translation/languages',
      'GET /api/translation/chatflows',
      'POST /api/translation/text-to-speech',
      'POST /api/translation/translate-and-speak',
      'POST /api/translation/audio-translate-speak',
      'GET /api/translation/voices',
      'GET /api/translation/tts-languages',

      // Transportation
      'POST /api/transportation/options',
      'GET /api/transportation/realtime',
      'POST /api/transportation/directions',
      'GET /api/transportation/status',
      'GET /api/transportation/help',

      // Recommendations
      'POST /api/recommendations/personalized',
      'POST /api/recommendations/cultural-etiquette',
      'POST /api/recommendations/comprehensive',
      'POST /api/recommendations/test',
      'GET /api/recommendations/health',
      'GET /api/recommendations/interests',

      // Scam Prevention
      'POST /api/scam-prevention/price-advice',
      'POST /api/scam-prevention/detect',
      'POST /api/scam-prevention/advice',
      'POST /api/scam-prevention/test',
      'GET /api/scam-prevention/red-flags',
      'GET /api/scam-prevention/health',

      // Currency
      'POST /api/currency/convert',
      'POST /api/currency/exchange-rates',
      'GET /api/currency/info/:currency',
      'POST /api/currency/market-insights',
      'GET /api/currency/supported',
      'GET /api/currency/health',
      'POST /api/currency/test',
    ],
  });
});

/* --------------------------- Error Handler (500) -------------------------- */
app.use((error, req, res, next) => {
  console.error('Error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: error.message,
  });
});

/* --------------------------------- Start --------------------------------- */
const server = app.listen(PORT, () => {
  console.log(`🚀 AI Travel Assistant API running on port ${PORT}`);
  console.log(`📚 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🌐 API available at: http://localhost:${PORT}/`);
  console.log(
    `🎯 New Features: Personalized Recommendations, Cultural Etiquette, Currency Conversion & Scam Prevention`
  );
});

// Handle port conflicts gracefully
server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`❌ Port ${PORT} is already in use. Please:`);
    console.error(`   1. Kill the process using port ${PORT}:`);
    console.error(`      Windows: netstat -ano | findstr :${PORT}`);
    console.error(`      Then: taskkill /PID <PID> /F`);
    console.error(`   2. Or use a different port by setting PORT environment variable`);
    console.error(`      Example: PORT=3001 npm start`);
    process.exit(1);
  } else {
    console.error('❌ Server error:', err);
    process.exit(1);
  }
});

module.exports = app;
