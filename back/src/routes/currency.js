const express = require('express');
const Joi = require('joi');
const CurrencyService = require('../services/currencyService');

const router = express.Router();
const currencyService = new CurrencyService();

// Validation schemas
const convertCurrencySchema = Joi.object({
  amount: Joi.number().positive().required().messages({
    'number.positive': 'Amount must be a positive number',
    'any.required': 'Amount is required'
  }),
  fromCurrency: Joi.string().length(3).pattern(/^[A-Z]{3}$/i).required().messages({
    'string.length': 'Currency code must be exactly 3 characters',
    'string.pattern': 'Currency code must contain only letters',
    'any.required': 'Source currency is required'
  }),
  toCurrency: Joi.string().length(3).pattern(/^[A-Z]{3}$/i).required().messages({
    'string.length': 'Currency code must be exactly 3 characters',
    'string.pattern': 'Currency code must contain only letters',
    'any.required': 'Target currency is required'
  }),
  history: Joi.array().optional()
});

const exchangeRatesSchema = Joi.object({
  baseCurrency: Joi.string().length(3).pattern(/^[A-Z]{3}$/i).required().messages({
    'string.length': 'Currency code must be exactly 3 characters',
    'string.pattern': 'Currency code must contain only letters',
    'any.required': 'Base currency is required'
  }),
  targetCurrencies: Joi.array().items(
    Joi.string().length(3).pattern(/^[A-Z]{3}$/i)
  ).optional().messages({
    'array.items': 'Each target currency must be a 3-letter code'
  })
});

const currencyInfoSchema = Joi.object({
  currency: Joi.string().length(3).pattern(/^[A-Z]{3}$/i).required().messages({
    'string.length': 'Currency code must be exactly 3 characters',
    'string.pattern': 'Currency code must contain only letters',
    'any.required': 'Currency code is required'
  })
});

/**
 * @route POST /api/currency/convert
 * @desc Convert currency using Flowise AI
 * @access Public
 */
router.post('/convert', async (req, res) => {
  try {
    // Validate request body
    const { error, value } = convertCurrencySchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        details: error.details.map(detail => detail.message)
      });
    }

    const { amount, fromCurrency, toCurrency, history } = value;

    // Convert currency
    const result = await currencyService.convertCurrency(
      amount, 
      fromCurrency.toUpperCase(), 
      toCurrency.toUpperCase(), 
      { history }
    );

    if (!result.success) {
      return res.status(result.statusCode || 500).json(result);
    }

    res.json({
      success: true,
      message: 'Currency conversion completed successfully',
      data: result.data
    });
  } catch (error) {
    console.error('Currency conversion error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * @route POST /api/currency/exchange-rates
 * @desc Get exchange rates for multiple currencies
 * @access Public
 */
router.post('/exchange-rates', async (req, res) => {
  try {
    // Validate request body
    const { error, value } = exchangeRatesSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        details: error.details.map(detail => detail.message)
      });
    }

    const { baseCurrency, targetCurrencies } = value;

    // Get exchange rates
    const result = await currencyService.getExchangeRates(
      baseCurrency.toUpperCase(), 
      targetCurrencies?.map(c => c.toUpperCase())
    );

    if (!result.success) {
      return res.status(result.statusCode || 500).json(result);
    }

    res.json({
      success: true,
      message: 'Exchange rates retrieved successfully',
      data: result.data
    });
  } catch (error) {
    console.error('Exchange rates error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * @route GET /api/currency/info/:currency
 * @desc Get currency information and trends
 * @access Public
 */
router.get('/info/:currency', async (req, res) => {
  try {
    const { currency } = req.params;

    // Validate currency parameter
    const { error } = currencyInfoSchema.validate({ currency });
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        details: error.details.map(detail => detail.message)
      });
    }

    // Get currency information
    const result = await currencyService.getCurrencyInfo(currency.toUpperCase());

    if (!result.success) {
      return res.status(result.statusCode || 500).json(result);
    }

    res.json({
      success: true,
      message: 'Currency information retrieved successfully',
      data: result.data
    });
  } catch (error) {
    console.error('Currency info error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * @route GET /api/currency/supported
 * @desc Get list of supported currencies
 * @access Public
 */
router.get('/supported', (req, res) => {
  try {
    const supportedCurrencies = currencyService.getSupportedCurrencies();
    
    res.json({
      success: true,
      message: 'Supported currencies retrieved successfully',
      data: {
        currencies: supportedCurrencies,
        count: supportedCurrencies.length
      }
    });
  } catch (error) {
    console.error('Supported currencies error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * @route POST /api/currency/market-insights
 * @desc Get dynamic market insights and analysis
 * @access Public
 */
router.post('/market-insights', async (req, res) => {
  try {
    const { baseCurrency, targetCurrencies } = req.body;

    // Validate base currency
    if (!baseCurrency || !currencyService.validateCurrencyCode(baseCurrency)) {
      return res.status(400).json({
        success: false,
        error: 'Valid base currency is required (3-letter code)'
      });
    }

    // Validate target currencies if provided
    if (targetCurrencies && Array.isArray(targetCurrencies)) {
      const invalidCurrencies = targetCurrencies.filter(currency => 
        !currencyService.validateCurrencyCode(currency)
      );
      if (invalidCurrencies.length > 0) {
        return res.status(400).json({
          success: false,
          error: `Invalid target currencies: ${invalidCurrencies.join(', ')}`
        });
      }
    }

    // Get market insights
    const result = await currencyService.getMarketInsights(
      baseCurrency.toUpperCase(), 
      targetCurrencies?.map(c => c.toUpperCase())
    );

    if (!result.success) {
      return res.status(result.statusCode || 500).json(result);
    }

    res.json({
      success: true,
      message: 'Market insights retrieved successfully',
      data: result.data
    });
  } catch (error) {
    console.error('Market insights error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * @route GET /api/currency/health
 * @desc Health check for currency service
 * @access Public
 */
router.get('/health', async (req, res) => {
  try {
    const result = await currencyService.healthCheck();
    
    if (!result.success) {
      return res.status(result.statusCode || 500).json(result);
    }

    res.json(result);
  } catch (error) {
    console.error('Currency health check error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * @route POST /api/currency/test
 * @desc Test currency conversion with sample data
 * @access Public
 */
router.post('/test', async (req, res) => {
  try {
    // Test with sample data
    const testData = {
      amount: 100,
      fromCurrency: 'USD',
      toCurrency: 'EUR'
    };

    const result = await currencyService.convertCurrency(
      testData.amount,
      testData.fromCurrency,
      testData.toCurrency
    );

    res.json({
      success: true,
      message: 'Currency conversion test completed',
      testData,
      result
    });
  } catch (error) {
    console.error('Currency test error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * @route GET /api/currency
 * @desc Get currency service information and available endpoints
 * @access Public
 */
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Currency Conversion Service',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      convert: {
        method: 'POST',
        url: '/api/currency/convert',
        description: 'Convert currency using Flowise AI',
        body: {
          amount: 'number (required)',
          fromCurrency: 'string (required, 3-letter code)',
          toCurrency: 'string (required, 3-letter code)',
          history: 'array (optional)'
        }
      },
      exchangeRates: {
        method: 'POST',
        url: '/api/currency/exchange-rates',
        description: 'Get exchange rates for multiple currencies',
        body: {
          baseCurrency: 'string (required, 3-letter code)',
          targetCurrencies: 'array (optional, 3-letter codes)'
        }
      },
      currencyInfo: {
        method: 'GET',
        url: '/api/currency/info/:currency',
        description: 'Get currency information and trends',
        params: {
          currency: 'string (required, 3-letter code)'
        }
      },
      marketInsights: {
        method: 'POST',
        url: '/api/currency/market-insights',
        description: 'Get dynamic market insights and analysis',
        body: {
          baseCurrency: 'string (required, 3-letter code)',
          targetCurrencies: 'array (optional, 3-letter codes)'
        }
      },
      supported: {
        method: 'GET',
        url: '/api/currency/supported',
        description: 'Get list of supported currencies'
      },
      health: {
        method: 'GET',
        url: '/api/currency/health',
        description: 'Health check for currency service'
      },
      test: {
        method: 'POST',
        url: '/api/currency/test',
        description: 'Test currency conversion with sample data'
      }
    },
    examples: {
      convert: {
        method: 'POST',
        url: '/api/currency/convert',
        body: {
          amount: 100,
          fromCurrency: 'USD',
          toCurrency: 'EUR'
        }
      },
      exchangeRates: {
        method: 'POST',
        url: '/api/currency/exchange-rates',
        body: {
          baseCurrency: 'USD',
          targetCurrencies: ['EUR', 'GBP', 'JPY']
        }
      },
      currencyInfo: {
        method: 'GET',
        url: '/api/currency/info/USD'
      },
      marketInsights: {
        method: 'POST',
        url: '/api/currency/market-insights',
        body: {
          baseCurrency: 'USD',
          targetCurrencies: ['EUR', 'GBP', 'JPY']
        }
      }
    }
  });
});

module.exports = router;
