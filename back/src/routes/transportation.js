const express = require('express');
const Joi = require('joi');
const TransportationService = require('../services/transportationService');

const router = express.Router();
const transportationService = new TransportationService(false); // Enable LIVE mode for real location tracking

// Validation schemas
const transportationOptionsSchema = Joi.object({
  from: Joi.string().min(1).max(200).required(),
  to: Joi.string().min(1).max(200).required(),
  mode: Joi.string().valid('all', 'bus', 'metro', 'transit').optional(),
  preferences: Joi.object({
    ecoFriendly: Joi.boolean().optional(),
    budget: Joi.number().min(0).optional(),
    maxTime: Joi.number().min(1).optional(),
    accessibility: Joi.boolean().optional()
  }).optional()
});

const directionsSchema = Joi.object({
  from: Joi.string().min(1).max(200).required(),
  to: Joi.string().min(1).max(200).required(),
  transportType: Joi.string().valid('bus', 'metro').required(),
  routeId: Joi.string().optional()
});

const realTimeUpdatesSchema = Joi.object({
  transportType: Joi.string().valid('all', 'bus', 'metro').optional()
});

const locationTrackingSchema = Joi.object({
  latitude: Joi.number().min(-90).max(90).required(),
  longitude: Joi.number().min(-180).max(180).required(),
  accuracy: Joi.number().min(0).optional(),
  timestamp: Joi.date().optional()
});

const locationBasedRealtimeSchema = Joi.object({
  latitude: Joi.number().min(-90).max(90).required(),
  longitude: Joi.number().min(-180).max(180).required(),
  radius: Joi.number().min(100).max(10000).optional().default(1000), // meters
  transportType: Joi.string().valid('all', 'bus', 'metro').optional()
}).options({ convert: true }); // This converts string numbers to actual numbers

/**
 * POST /api/transportation/options
 * Get transportation options between two points
 */
router.post('/options', async (req, res) => {
  try {
    const { error, value } = transportationOptionsSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: error.details[0].message,
        details: error.details
      });
    }

    const { from, to, mode, preferences } = value;
    const result = await transportationService.getTransportationOptions({
      from,
      to,
      mode,
      preferences
    });

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: result.message
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.error,
        message: result.message
      });
    }
  } catch (error) {
    console.error('Transportation options error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * GET /api/transportation/realtime
 * Get real-time transportation updates
 */
router.get('/realtime', async (req, res) => {
  try {
    const { error, value } = realTimeUpdatesSchema.validate(req.query);
    
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: error.details[0].message
      });
    }

    const { transportType = 'all' } = value;
    const result = await transportationService.getRealTimeUpdates(transportType);

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: result.message
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.error,
        message: result.message
      });
    }
  } catch (error) {
    console.error('Real-time updates error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * POST /api/transportation/directions
 * Get detailed directions for a specific transportation option
 */
router.post('/directions', async (req, res) => {
  try {
    const { error, value } = directionsSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: error.details[0].message,
        details: error.details
      });
    }

    const { from, to, transportType, routeId } = value;
    const result = await transportationService.getDirections(from, to, transportType, routeId);

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: result.message
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.error,
        message: result.message
      });
    }
  } catch (error) {
    console.error('Directions error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * GET /api/transportation/status
 * Get overall transportation system status
 */
router.get('/status', async (req, res) => {
  try {
    const result = await transportationService.getRealTimeUpdates('all');
    
    if (result.success) {
      // Calculate overall system status
      const systemStatus = {
        overall: 'Good',
        bus: result.data.bus?.realTimeStatus === 'On time' ? 'Good' : 'Delays',
        metro: result.data.metro?.realTimeStatus.includes('delays') ? 'Delays' : 'Good',
        lastUpdated: result.data.timestamp,
        alerts: [
          ...(result.data.bus?.delays || []),
          ...(result.data.metro?.delays || [])
        ]
      };

      res.json({
        success: true,
        data: systemStatus,
        message: 'Transportation system status retrieved successfully'
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.error,
        message: result.message
      });
    }
  } catch (error) {
    console.error('System status error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * POST /api/transportation/location/track
 * Track user's current location for real-time updates
 */
router.post('/location/track', async (req, res) => {
  try {
    const { error, value } = locationTrackingSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: error.details[0].message,
        details: error.details
      });
    }

    const { latitude, longitude, accuracy, timestamp } = value;
    const result = await transportationService.trackLocation({
      latitude,
      longitude,
      accuracy,
      timestamp: timestamp || new Date()
    });

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: result.message
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.error,
        message: result.message
      });
    }
  } catch (error) {
    console.error('Location tracking error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * GET /api/transportation/location/realtime
 * Get real-time transportation data based on current location
 */
router.get('/location/realtime', async (req, res) => {
  try {
    const { error, value } = locationBasedRealtimeSchema.validate(req.query);
    
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: error.details[0].message,
        details: error.details
      });
    }

    const { latitude, longitude, radius, transportType = 'all' } = value;
    const result = await transportationService.getLocationBasedRealtime({
      latitude,
      longitude,
      radius,
      transportType
    });

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: result.message
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.error,
        message: result.message
      });
    }
  } catch (error) {
    console.error('Location-based realtime error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * GET /api/transportation/location/nearby
 * Get nearby transportation options and real-time data
 */
router.get('/location/nearby', async (req, res) => {
  try {
    console.log('📍 Nearby transportation request received:');
    console.log('Query params:', req.query);
    console.log('Raw query string:', req.url);
    
    const { error, value } = locationBasedRealtimeSchema.validate(req.query);
    
    if (error) {
      console.log('❌ Validation error:', error.details);
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: error.details[0].message,
        details: error.details
      });
    }

    const { latitude, longitude, radius, transportType = 'all' } = value;
    const result = await transportationService.getNearbyTransportation({
      latitude,
      longitude,
      radius,
      transportType
    });

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: result.message
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.error,
        message: result.message
      });
    }
  } catch (error) {
    console.error('Nearby transportation error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * GET /api/transportation/help
 * Get help and documentation for transportation API
 */
router.get('/help', (req, res) => {
  res.json({
    success: true,
    data: {
      endpoints: {
        'POST /api/transportation/options': {
          description: 'Get transportation options between two points',
          parameters: {
            from: 'string (required) - Origin location',
            to: 'string (required) - Destination location',
            mode: 'string (optional) - all, bus, metro, transit',
            preferences: 'object (optional) - ecoFriendly, budget, maxTime, accessibility'
          },
          example: {
            from: 'Times Square, New York',
            to: 'Central Park, New York',
            mode: 'all',
            preferences: {
              ecoFriendly: true,
              budget: 10
            }
          }
        },
        'GET /api/transportation/realtime': {
          description: 'Get real-time transportation updates',
          parameters: {
            transportType: 'string (optional) - all, bus, metro'
          },
          example: 'GET /api/transportation/realtime?transportType=bus'
        },
        'POST /api/transportation/directions': {
          description: 'Get detailed directions for specific transportation',
          parameters: {
            from: 'string (required) - Origin location',
            to: 'string (required) - Destination location',
            transportType: 'string (required) - bus, metro',
            routeId: 'string (optional) - Specific route ID'
          },
          example: {
            from: 'Airport Terminal 1',
            to: 'Downtown Hotel',
            transportType: 'metro',
            routeId: 'M1'
          }
        },
        'GET /api/transportation/status': {
          description: 'Get overall transportation system status',
          parameters: 'None'
        },
        'POST /api/transportation/location/track': {
          description: 'Track user location and get nearby real-time data',
          parameters: {
            latitude: 'number (required) - GPS latitude (-90 to 90)',
            longitude: 'number (required) - GPS longitude (-180 to 180)',
            accuracy: 'number (optional) - Location accuracy in meters',
            timestamp: 'date (optional) - Location timestamp'
          },
          example: {
            latitude: 40.7589,
            longitude: -73.9851,
            accuracy: 10,
            timestamp: '2024-01-15T10:30:00.000Z'
          }
        },
        'GET /api/transportation/location/realtime': {
          description: 'Get real-time transportation data based on current location',
          parameters: {
            latitude: 'number (required) - GPS latitude',
            longitude: 'number (required) - GPS longitude',
            radius: 'number (optional) - Search radius in meters (100-10000)',
            transportType: 'string (optional) - all, bus, metro'
          },
          example: 'GET /api/transportation/location/realtime?latitude=40.7589&longitude=-73.9851&radius=1000&transportType=all'
        },
        'GET /api/transportation/location/nearby': {
          description: 'Get nearby transportation options and real-time data',
          parameters: {
            latitude: 'number (required) - GPS latitude',
            longitude: 'number (required) - GPS longitude',
            radius: 'number (optional) - Search radius in meters (100-10000)',
            transportType: 'string (optional) - all, bus, metro'
          },
          example: 'GET /api/transportation/location/nearby?latitude=40.7589&longitude=-73.9851&radius=500&transportType=bus'
        }
      },
      supportedTransportTypes: ['bus', 'metro'],
      features: [
        'Real-time updates and delays',
        'Cost estimation',
        'Travel time estimates',
        'Route planning',
        'Multiple transportation options',
        'Accessibility information',
        'Eco-friendly recommendations',
        'Location-based real-time data',
        'GPS coordinate tracking',
        'Nearby transportation discovery',
        'Traffic condition monitoring',
        'Walking distance calculations'
      ]
    },
    message: 'Transportation API help and documentation'
  });
});

module.exports = router;
