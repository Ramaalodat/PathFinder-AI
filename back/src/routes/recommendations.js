const express = require('express');
const Joi = require('joi');
const RecommendationsService = require('../services/recommendationsService');

const router = express.Router();
const recommendationsService = new RecommendationsService();

// Validation schemas
const personalizedRecommendationsSchema = Joi.object({
  userMessage: Joi.string().min(1).max(1000).required(),
  chatflowId: Joi.string().required(),
  chatHistory: Joi.array().items(
    Joi.object({
      role: Joi.string().valid('user', 'ai', 'assistant').required(),
      text: Joi.string().optional(),
      content: Joi.string().optional()
    }).or('text', 'content')
  ).optional().default([])
});

const culturalEtiquetteSchema = Joi.object({
  location: Joi.string().min(2).max(100).required(),
  chatflowId: Joi.string().required(),
  specificTopics: Joi.array().items(Joi.string().min(2).max(50)).optional().default([])
});

const comprehensiveRecommendationsSchema = Joi.object({
  location: Joi.string().min(2).max(100).required(),
  interests: Joi.array().items(Joi.string().min(2).max(50)).optional().default([]),
  budget: Joi.string().valid('low', 'medium', 'high', 'luxury').optional().default('medium'),
  preferences: Joi.object().optional().default({}),
  duration: Joi.string().min(3).max(50).optional().default('1 week'),
  travelStyle: Joi.string().valid('backpacker', 'family', 'business', 'luxury', 'tourist', 'adventure').optional().default('tourist'),
  dietaryRestrictions: Joi.array().items(Joi.string().min(2).max(50)).optional().default([]),
  recommendationsChatflowId: Joi.string().required(),
  culturalEtiquetteChatflowId: Joi.string().optional(),
  includeCulturalEtiquette: Joi.boolean().optional().default(true)
});

/**
 * POST /api/recommendations/personalized
 * Get personalized travel recommendations based on user message and chat history
 */
router.post('/personalized', async (req, res) => {
  try {
    const {
      userMessage,
      chatflowId,
      chatHistory
    } = req.body;

    // Validate input
    const { error, value } = personalizedRecommendationsSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: error.details[0].message,
        details: error.details
      });
    }

    // Get personalized recommendations
    const result = await recommendationsService.getPersonalizedRecommendations(value);

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: 'Personalized recommendations generated successfully'
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: 'Failed to generate personalized recommendations'
      });
    }
  } catch (error) {
    console.error('Personalized recommendations error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during recommendations generation',
      message: error.message
    });
  }
});

/**
 * POST /api/recommendations/cultural-etiquette
 * Get cultural etiquette information for a specific location
 */
router.post('/cultural-etiquette', async (req, res) => {
  try {
    const {
      location,
      chatflowId,
      specificTopics
    } = req.body;

    // Validate input
    const { error, value } = culturalEtiquetteSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: error.details[0].message,
        details: error.details
      });
    }

    // Get cultural etiquette information
    const result = await recommendationsService.getCulturalEtiquette(value);

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: 'Cultural etiquette information retrieved successfully'
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: 'Failed to retrieve cultural etiquette information'
      });
    }
  } catch (error) {
    console.error('Cultural etiquette error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during cultural etiquette retrieval',
      message: error.message
    });
  }
});

/**
 * POST /api/recommendations/comprehensive
 * Get comprehensive travel recommendations including both attractions and cultural etiquette
 */
router.post('/comprehensive', async (req, res) => {
  try {
    const {
      location,
      interests,
      budget,
      preferences,
      duration,
      travelStyle,
      dietaryRestrictions,
      recommendationsChatflowId,
      culturalEtiquetteChatflowId,
      includeCulturalEtiquette
    } = req.body;

    // Validate input
    const { error, value } = comprehensiveRecommendationsSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: error.details[0].message,
        details: error.details
      });
    }

    // Get comprehensive recommendations
    const result = await recommendationsService.getComprehensiveRecommendations(value);

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: 'Comprehensive travel recommendations generated successfully'
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: 'Failed to generate comprehensive recommendations'
      });
    }
  } catch (error) {
    console.error('Comprehensive recommendations error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during comprehensive recommendations generation',
      message: error.message
    });
  }
});

/**
 * POST /api/recommendations/test
 * Simple test endpoint for easy API testing
 */
router.post('/test', async (req, res) => {
  try {
    const { 
      location = 'Paris, France',
      interests = ['culture', 'food'],
      budget = 'medium',
      chatflowId 
    } = req.body;

    // Validate required fields
    if (!chatflowId) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        message: 'chatflowId is required for testing'
      });
    }

    // Get test recommendations
    const result = await recommendationsService.getPersonalizedRecommendations({
      location,
      interests,
      budget,
      chatflowId
    });

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: 'Test recommendations completed successfully'
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: 'Failed to generate test recommendations'
      });
    }
  } catch (error) {
    console.error('Test recommendations error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during test recommendations',
      message: error.message
    });
  }
});

/**
 * GET /api/recommendations/health
 * Health check for recommendations service
 */
router.get('/health', async (req, res) => {
  try {
    const result = await recommendationsService.healthCheck();

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: 'Recommendations service is healthy'
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: 'Recommendations service health check failed'
      });
    }
  } catch (error) {
    console.error('Health check error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during health check',
      message: error.message
    });
  }
});

/**
 * GET /api/recommendations/interests
 * Get list of supported interests for recommendations
 */
router.get('/interests', (req, res) => {
  res.json({
    success: true,
    data: {
      interests: [
        'culture',
        'history',
        'art',
        'music',
        'food',
        'nightlife',
        'adventure',
        'nature',
        'beaches',
        'mountains',
        'shopping',
        'architecture',
        'photography',
        'sports',
        'wellness',
        'family-friendly',
        'romantic',
        'business',
        'budget-travel',
        'luxury',
        'local-experiences',
        'festivals',
        'museums',
        'religious-sites',
        'outdoor-activities'
      ],
      travelStyles: [
        'backpacker',
        'family',
        'business',
        'luxury',
        'tourist',
        'adventure',
        'cultural',
        'relaxation',
        'photography',
        'foodie'
      ],
      budgetLevels: [
        'low',
        'medium',
        'high',
        'luxury'
      ],
      commonDurations: [
        'weekend',
        '3 days',
        '1 week',
        '2 weeks',
        '1 month',
        'long-term'
      ]
    },
    message: 'Supported interests and preferences retrieved successfully'
  });
});

module.exports = router;
