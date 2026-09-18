const express = require('express');
const Joi = require('joi');
const FlowiseService = require('../services/flowiseService');

const router = express.Router();
const flowiseService = new FlowiseService();

// Get default chatflow ID from environment
const DEFAULT_PRICE_ADVISOR_CHATFLOW_ID = process.env.DEFAULT_PRICE_ADVISOR_CHATFLOW_ID || '07afcffe-f864-4a73-8a28-9cbf096919e5';

// Validation schemas
const priceAdviceSchema = Joi.object({
  item: Joi.string().min(1).max(200).required(),
  price: Joi.number().min(0).required(),
  location: Joi.string().min(2).max(100).optional(),
  currency: Joi.string().min(3).max(3).optional().default('USD'),
  chatflowId: Joi.string().required(),
  context: Joi.object({
    marketType: Joi.string().valid('street', 'market', 'shop', 'restaurant', 'hotel', 'tour', 'transportation').optional(),
    itemCategory: Joi.string().valid('food', 'souvenir', 'clothing', 'electronics', 'art', 'jewelry', 'accommodation', 'service', 'other').optional(),
    sellerType: Joi.string().valid('local', 'tourist', 'official', 'street', 'online').optional(),
    timeOfDay: Joi.string().valid('morning', 'afternoon', 'evening', 'night').optional(),
    season: Joi.string().valid('peak', 'off-peak', 'holiday').optional()
  }).optional(),
  history: Joi.array().items(Joi.object({
    message: Joi.string().required(),
    type: Joi.string().valid('user', 'assistant').required()
  })).optional()
});

const scamDetectionSchema = Joi.object({
  situation: Joi.string().min(10).max(2000).required(),
  location: Joi.string().min(2).max(100).optional(),
  chatflowId: Joi.string().required(),
  redFlags: Joi.array().items(Joi.string().min(2).max(100)).optional().default([]),
  urgency: Joi.string().valid('low', 'medium', 'high').optional().default('medium'),
  history: Joi.array().items(Joi.object({
    message: Joi.string().required(),
    type: Joi.string().valid('user', 'assistant').required()
  })).optional()
});

const generalAdviceSchema = Joi.object({
  query: Joi.string().min(5).max(1000).required(),
  location: Joi.string().min(2).max(100).optional(),
  chatflowId: Joi.string().required(),
  adviceType: Joi.string().valid('price', 'safety', 'general', 'negotiation', 'bargaining').optional().default('general'),
  history: Joi.array().items(Joi.object({
    message: Joi.string().required(),
    type: Joi.string().valid('user', 'assistant').required()
  })).optional()
});

/**
 * POST /api/scam-prevention/price-advice
 * Get price advice and fair pricing information for items/services
 */
router.post('/price-advice', async (req, res) => {
  try {
    const { error, value } = priceAdviceSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: error.details[0].message,
        details: error.details
      });
    }

    const {
      item,
      price,
      location,
      currency,
      chatflowId,
      context,
      history
    } = value;

    // Create a contextual message for the AI agent
    const contextualMessage = `I need price advice for an item. Here are the details:
Item: ${item}
Price: ${price} ${currency}
Location: ${location || 'Not specified'}
Context: ${JSON.stringify(context || {})}

Please provide advice on whether this price is fair, typical market rates, negotiation tips, and any red flags to watch for.`;

    // Send request to Flowise
    const result = await flowiseService.sendChatMessage(contextualMessage, chatflowId, { history });

    if (result.success) {
      res.json({
        success: true,
        data: {
          item: item,
          price: price,
          currency: currency,
          location: location,
          advice: result.data.answer || result.data.text || result.data.response,
          context: context,
          timestamp: new Date().toISOString()
        },
        message: 'Price advice generated successfully'
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: 'Failed to generate price advice'
      });
    }
  } catch (error) {
    console.error('Price advice error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during price advice generation',
      message: error.message
    });
  }
});

/**
 * POST /api/scam-prevention/detect
 * Analyze a situation for potential scams or fraud
 */
router.post('/detect', async (req, res) => {
  try {
    const { error, value } = scamDetectionSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: error.details[0].message,
        details: error.details
      });
    }

    const {
      situation,
      location,
      chatflowId,
      redFlags,
      urgency,
      history
    } = value;

    // Create a contextual message for the AI agent
    const contextualMessage = `I need help analyzing a potentially suspicious situation for scams or fraud. Here are the details:
Situation: ${situation}
Location: ${location || 'Not specified'}
Urgency Level: ${urgency}
Red Flags I've noticed: ${redFlags.length > 0 ? redFlags.join(', ') : 'None specified'}

Please analyze this situation for potential scams, provide safety advice, and suggest appropriate actions.`;

    // Send request to Flowise
    const result = await flowiseService.sendChatMessage(contextualMessage, chatflowId, { history });

    if (result.success) {
      res.json({
        success: true,
        data: {
          situation: situation,
          location: location,
          urgency: urgency,
          analysis: result.data.answer || result.data.text || result.data.response,
          redFlags: redFlags,
          timestamp: new Date().toISOString()
        },
        message: 'Scam detection analysis completed successfully'
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: 'Failed to analyze situation for scams'
      });
    }
  } catch (error) {
    console.error('Scam detection error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during scam detection',
      message: error.message
    });
  }
});

/**
 * POST /api/scam-prevention/advice
 * Get general safety and scam prevention advice
 */
router.post('/advice', async (req, res) => {
  try {
    const { error, value } = generalAdviceSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: error.details[0].message,
        details: error.details
      });
    }

    const {
      query,
      location,
      chatflowId,
      adviceType,
      history
    } = value;

    // Create a contextual message for the AI agent
    const contextualMessage = `I need general advice about travel safety and scam prevention. Here are the details:
Query: ${query}
Location: ${location || 'Not specified'}
Advice Type: ${adviceType}

Please provide helpful advice, tips, and guidance related to travel safety, scam prevention, and best practices.`;

    // Send request to Flowise
    const result = await flowiseService.sendChatMessage(contextualMessage, chatflowId, { history });

    if (result.success) {
      res.json({
        success: true,
        data: {
          query: query,
          location: location,
          adviceType: adviceType,
          advice: result.data.answer || result.data.text || result.data.response,
          timestamp: new Date().toISOString()
        },
        message: 'General safety advice generated successfully'
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: 'Failed to generate safety advice'
      });
    }
  } catch (error) {
    console.error('General advice error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during advice generation',
      message: error.message
    });
  }
});

/**
 * POST /api/scam-prevention/test
 * Simple test endpoint for easy API testing
 */
router.post('/test', async (req, res) => {
  try {
    const { 
      testType = 'price',
      chatflowId = DEFAULT_PRICE_ADVISOR_CHATFLOW_ID
    } = req.body;

    let testMessage;
    let testData;

    switch (testType) {
      case 'price':
        testMessage = `I need price advice for an item. Here are the details:
Item: Handmade ceramic bowl
Price: $25 USD
Location: Bangkok, Thailand
Context: Street market, local vendor, afternoon

Please provide advice on whether this price is fair, typical market rates, negotiation tips, and any red flags to watch for.`;
        testData = {
          item: 'Handmade ceramic bowl',
          price: 25,
          currency: 'USD',
          location: 'Bangkok, Thailand',
          advice: 'Test advice response'
        };
        break;
      
      case 'scam':
        testMessage = `I need help analyzing a potentially suspicious situation for scams or fraud. Here are the details:
Situation: Someone approached me offering to show me a "secret temple" that's not in guidebooks, but they want money upfront and won't let me see it first
Location: Siem Reap, Cambodia
Urgency Level: medium
Red Flags I've noticed: Asking for money upfront, won't show the location first, claiming it's "secret"

Please analyze this situation for potential scams, provide safety advice, and suggest appropriate actions.`;
        testData = {
          situation: 'Secret temple offer',
          location: 'Siem Reap, Cambodia',
          urgency: 'medium',
          analysis: 'Test analysis response'
        };
        break;
      
      default:
        testMessage = `I need general advice about travel safety and scam prevention. Here are the details:
Query: What are the most common tourist scams in Southeast Asia?
Location: Southeast Asia
Advice Type: general

Please provide helpful advice, tips, and guidance related to travel safety, scam prevention, and best practices.`;
        testData = {
          query: 'Common tourist scams in Southeast Asia',
          location: 'Southeast Asia',
          adviceType: 'general',
          advice: 'Test advice response'
        };
    }

    // Send request to Flowise
    const result = await flowiseService.sendChatMessage(testMessage, chatflowId);

    if (result.success) {
      res.json({
        success: true,
        data: {
          ...testData,
          response: result.data.answer || result.data.text || result.data.response,
          timestamp: new Date().toISOString()
        },
        message: `Test ${testType} advice completed successfully`
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: `Failed to generate test ${testType} advice`
      });
    }
  } catch (error) {
    console.error('Test advice error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during test advice',
      message: error.message
    });
  }
});

/**
 * GET /api/scam-prevention/red-flags
 * Get list of common red flags and warning signs
 */
router.get('/red-flags', (req, res) => {
  res.json({
    success: true,
    data: {
      commonRedFlags: [
        'Asking for money upfront before showing anything',
        'Pushing for immediate decisions',
        'Refusing to show ID or credentials',
        'Offering deals that seem too good to be true',
        'Asking you to go somewhere private or isolated',
        'Refusing to provide written receipts or contracts',
        'Claiming to be an "official" without proper identification',
        'Using high-pressure sales tactics',
        'Asking for personal information unnecessarily',
        'Refusing to accept credit cards or official payment methods',
        'Changing the price or terms after initial agreement',
        'Claiming something is "urgent" or "limited time only"',
        'Asking you to pay in cash only',
        'Refusing to provide contact information or business address',
        'Claiming they know your hotel or personal information'
      ],
      marketTypes: [
        'street',
        'market', 
        'shop',
        'restaurant',
        'hotel',
        'tour',
        'transportation'
      ],
      itemCategories: [
        'food',
        'souvenir',
        'clothing',
        'electronics',
        'art',
        'jewelry',
        'accommodation',
        'service',
        'other'
      ],
      sellerTypes: [
        'local',
        'tourist',
        'official',
        'street',
        'online'
      ],
      adviceTypes: [
        'price',
        'safety',
        'general',
        'negotiation',
        'bargaining'
      ],
      urgencyLevels: [
        'low',
        'medium',
        'high'
      ]
    },
    message: 'Scam prevention resources retrieved successfully'
  });
});

/**
 * GET /api/scam-prevention/health
 * Health check for scam prevention service
 */
router.get('/health', async (req, res) => {
  try {
    const result = await flowiseService.healthCheck();

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: 'Scam prevention service is healthy'
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: 'Scam prevention service health check failed'
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

module.exports = router;
