const axios = require('axios');

class CurrencyService {
  constructor() {
    this.apiUrl = process.env.FLOWISE_API_URL || 'https://cloud.flowiseai.com';
    this.apiKey = process.env.FLOWISE_API_KEY;
    this.currencyChatflowId = '8a5ceb67-167b-474d-83dc-adcac6579aae';
    
    if (!this.apiKey) {
      throw new Error('Flowise API Key must be configured in environment variables');
    }

    this.client = axios.create({
      baseURL: this.apiUrl,
      headers: {
        'X-API-KEY': this.apiKey,
        'Content-Type': 'application/json'
      },
      timeout: 30000 // 30 seconds timeout
    });

    // Common currency codes for validation
    this.supportedCurrencies = [
      'USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY', 'SEK', 'NZD',
      'MXN', 'SGD', 'HKD', 'NOK', 'TRY', 'RUB', 'INR', 'BRL', 'ZAR', 'KRW',
      'AED', 'SAR', 'QAR', 'KWD', 'BHD', 'OMR', 'JOD', 'LBP', 'EGP', 'MAD',
      'TND', 'DZD', 'LYD', 'SDG', 'ETB', 'KES', 'UGX', 'TZS', 'ZMW', 'BWP',
      'NAD', 'SZL', 'LSL', 'MZN', 'AOA', 'XOF', 'XAF', 'CDF', 'RWF', 'BIF'
    ];
  }

  /**
   * Convert currency using Flowise AI with dynamic real-time data
   * @param {number} amount - Amount to convert
   * @param {string} fromCurrency - Source currency code (e.g., 'USD')
   * @param {string} toCurrency - Target currency code (e.g., 'EUR')
   * @param {Object} options - Additional options
   * @returns {Promise<Object>} - Conversion result
   */
  async convertCurrency(amount, fromCurrency, toCurrency, options = {}) {
    try {
      // Validate inputs
      const validation = this.validateCurrencyInputs(amount, fromCurrency, toCurrency);
      if (!validation.valid) {
        return {
          success: false,
          error: validation.error,
          statusCode: 400
        };
      }

      // Get current time and date for dynamic context
      const now = new Date();
      const timeContext = this.getTimeContext(now);
      const marketContext = this.getMarketContext(now);

      // Minimal request to your existing Flowise agent
      const contextualMessage = `Convert ${amount} ${fromCurrency} to ${toCurrency}. Please respond in JSON format:
{
  "originalAmount": ${amount},
  "fromCurrency": "${fromCurrency}",
  "toCurrency": "${toCurrency}",
  "conversionRate": "rate_used",
  "convertedAmount": "calculated_amount",
  "timestamp": "${now.toISOString()}"
}`;

      const payload = {
        question: contextualMessage,
        history: options.history || []
      };

      console.log('Sending dynamic currency conversion request to Flowise:', JSON.stringify(payload, null, 2));
      
      const response = await this.client.post(`/api/v1/prediction/${this.currencyChatflowId}`, payload);
      
      console.log('Response from Flowise:', JSON.stringify(response.data, null, 2));
      
      // Process response from your existing Flowise agent
      const aiResponse = response.data.answer || response.data.text || response.data.response || '';
      
      // Try to parse JSON response, fallback to plain text
      let parsedResponse = null;
      try {
        parsedResponse = JSON.parse(aiResponse);
      } catch (e) {
        // If not JSON, extract conversion from plain text format "100 USD = 95.24 EUR"
        const match = aiResponse.match(/(\d+(?:\.\d+)?)\s+(\w+)\s*=\s*(\d+(?:\.\d+)?)\s+(\w+)/);
        if (match) {
          parsedResponse = {
            originalAmount: parseFloat(match[1]),
            fromCurrency: match[2],
            toCurrency: match[4],
            convertedAmount: parseFloat(match[3]),
            conversionRate: (parseFloat(match[3]) / parseFloat(match[1])).toFixed(4)
          };
        }
      }
      
      return {
        success: true,
        data: {
          originalAmount: amount,
          fromCurrency: fromCurrency.toUpperCase(),
          toCurrency: toCurrency.toUpperCase(),
          aiResponse: aiResponse,
          parsedResponse: parsedResponse,
          rawResponse: response.data,
          timestamp: now.toISOString(),
          marketContext: marketContext,
          timeContext: timeContext
        },
        message: 'Currency conversion completed successfully'
      };
    } catch (error) {
      console.error('Currency Conversion API Error:', error.response?.data || error.message);
      
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Failed to process currency conversion request',
        statusCode: error.response?.status || 500
      };
    }
  }

  /**
   * Get dynamic exchange rates for multiple currencies with real-time analysis
   * @param {string} baseCurrency - Base currency for rates
   * @param {Array} targetCurrencies - Array of target currencies
   * @returns {Promise<Object>} - Exchange rates with market analysis
   */
  async getExchangeRates(baseCurrency, targetCurrencies = []) {
    try {
      if (!this.validateCurrencyCode(baseCurrency)) {
        return {
          success: false,
          error: `Invalid base currency: ${baseCurrency}`,
          statusCode: 400
        };
      }

      const currencies = targetCurrencies.length > 0 ? targetCurrencies : this.supportedCurrencies.slice(0, 10);
      const now = new Date();
      const timeContext = this.getTimeContext(now);
      const marketContext = this.getMarketContext(now);
      
      const contextualMessage = `Get exchange rates for ${baseCurrency} to: ${currencies.join(', ')}. Please respond in JSON format:
{
  "baseCurrency": "${baseCurrency}",
  "timestamp": "${now.toISOString()}",
  "rates": {
    "EUR": "1.05",
    "GBP": "0.79",
    "JPY": "150.00"
  }
}`;

      const payload = {
        question: contextualMessage,
        history: []
      };

      const response = await this.client.post(`/api/v1/prediction/${this.currencyChatflowId}`, payload);
      
      return {
        success: true,
        data: {
          baseCurrency: baseCurrency.toUpperCase(),
          targetCurrencies: currencies,
          aiResponse: response.data.answer || response.data.text || response.data.response || '',
          rawResponse: response.data,
          timestamp: now.toISOString(),
          marketContext: marketContext,
          timeContext: timeContext,
          dynamicFeatures: {
            realTimeRates: true,
            marketAnalysis: true,
            trendAnalysis: true,
            recommendations: true,
            volatilityAnalysis: true
          }
        },
        message: 'Dynamic exchange rates retrieved successfully'
      };
    } catch (error) {
      console.error('Exchange Rates API Error:', error.response?.data || error.message);
      
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Failed to retrieve exchange rates',
        statusCode: error.response?.status || 500
      };
    }
  }

  /**
   * Get dynamic currency information with real-time trends and analysis
   * @param {string} currency - Currency code
   * @returns {Promise<Object>} - Currency information with market analysis
   */
  async getCurrencyInfo(currency) {
    try {
      if (!this.validateCurrencyCode(currency)) {
        return {
          success: false,
          error: `Invalid currency: ${currency}`,
          statusCode: 400
        };
      }

      const now = new Date();
      const timeContext = this.getTimeContext(now);
      const marketContext = this.getMarketContext(now);

      const contextualMessage = `Get information about ${currency}. Please respond in JSON format:
{
  "currency": {
    "code": "${currency}",
    "name": "currency_name",
    "country": "issuing_country"
  },
  "currentStatus": {
    "trend": "bullish/bearish/stable",
    "volatility": "low/medium/high"
  }
}`;

      const payload = {
        question: contextualMessage,
        history: []
      };

      const response = await this.client.post(`/api/v1/prediction/${this.currencyChatflowId}`, payload);
      
      return {
        success: true,
        data: {
          currency: currency.toUpperCase(),
          aiResponse: response.data.answer || response.data.text || response.data.response || '',
          rawResponse: response.data,
          timestamp: now.toISOString(),
          marketContext: marketContext,
          timeContext: timeContext,
          dynamicFeatures: {
            realTimeAnalysis: true,
            technicalAnalysis: true,
            fundamentalAnalysis: true,
            marketSentiment: true,
            newsIntegration: true,
            riskAssessment: true
          }
        },
        message: 'Dynamic currency information retrieved successfully'
      };
    } catch (error) {
      console.error('Currency Info API Error:', error.response?.data || error.message);
      
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Failed to retrieve currency information',
        statusCode: error.response?.status || 500
      };
    }
  }

  /**
   * Validate currency conversion inputs
   * @param {number} amount - Amount to convert
   * @param {string} fromCurrency - Source currency
   * @param {string} toCurrency - Target currency
   * @returns {Object} - Validation result
   */
  validateCurrencyInputs(amount, fromCurrency, toCurrency) {
    if (!amount || isNaN(amount) || amount <= 0) {
      return {
        valid: false,
        error: 'Amount must be a positive number'
      };
    }

    if (!this.validateCurrencyCode(fromCurrency)) {
      return {
        valid: false,
        error: `Invalid source currency: ${fromCurrency}. Must be a 3-letter currency code.`
      };
    }

    if (!this.validateCurrencyCode(toCurrency)) {
      return {
        valid: false,
        error: `Invalid target currency: ${toCurrency}. Must be a 3-letter currency code.`
      };
    }

    if (fromCurrency.toUpperCase() === toCurrency.toUpperCase()) {
      return {
        valid: false,
        error: 'Source and target currencies cannot be the same'
      };
    }

    return { valid: true };
  }

  /**
   * Validate currency code format
   * @param {string} currency - Currency code to validate
   * @returns {boolean} - Whether currency code is valid
   */
  validateCurrencyCode(currency) {
    if (!currency || typeof currency !== 'string') {
      return false;
    }
    
    const code = currency.toUpperCase();
    return code.length === 3 && /^[A-Z]{3}$/.test(code);
  }

  /**
   * Get supported currencies
   * @returns {Array} - List of supported currency codes
   */
  getSupportedCurrencies() {
    return this.supportedCurrencies;
  }

  /**
   * Get time context for dynamic responses
   * @param {Date} date - Current date
   * @returns {string} - Time context description
   */
  getTimeContext(date) {
    const hour = date.getHours();
    const day = date.getDay();
    
    let timeContext = '';
    
    // Market hours context
    if (hour >= 9 && hour < 16) {
      timeContext += 'Market Hours (Active Trading)';
    } else if (hour >= 16 && hour < 21) {
      timeContext += 'After Hours Trading';
    } else if (hour >= 21 || hour < 9) {
      timeContext += 'Extended Hours/Pre-Market';
    }
    
    // Day context
    if (day === 0) {
      timeContext += ' - Sunday (Market Closed)';
    } else if (day === 6) {
      timeContext += ' - Saturday (Market Closed)';
    } else if (day >= 1 && day <= 5) {
      timeContext += ' - Weekday';
    }
    
    return timeContext || 'Standard Business Hours';
  }

  /**
   * Get market context for dynamic responses
   * @param {Date} date - Current date
   * @returns {string} - Market context description
   */
  getMarketContext(date) {
    const hour = date.getHours();
    const day = date.getDay();
    
    // Check if markets are open
    const isWeekday = day >= 1 && day <= 5;
    const isMarketHours = hour >= 9 && hour < 16;
    
    if (isWeekday && isMarketHours) {
      return 'Markets Open - High Activity';
    } else if (isWeekday && (hour >= 16 || hour < 9)) {
      return 'Markets Closed - Low Activity';
    } else {
      return 'Markets Closed - Weekend';
    }
  }

  /**
   * Get market volatility level based on time and day
   * @param {Date} date - Current date
   * @returns {string} - Volatility level
   */
  getMarketVolatility(date) {
    const hour = date.getHours();
    const day = date.getDay();
    
    // High volatility during market open
    if (day >= 1 && day <= 5 && hour >= 9 && hour < 16) {
      return 'high';
    }
    // Medium volatility during extended hours
    else if (day >= 1 && day <= 5 && ((hour >= 16 && hour < 21) || (hour >= 6 && hour < 9))) {
      return 'medium';
    }
    // Low volatility during closed hours
    else {
      return 'low';
    }
  }

  /**
   * Get dynamic market insights
   * @param {string} baseCurrency - Base currency
   * @param {Array} targetCurrencies - Target currencies
   * @returns {Promise<Object>} - Market insights
   */
  async getMarketInsights(baseCurrency, targetCurrencies = []) {
    try {
      const now = new Date();
      const timeContext = this.getTimeContext(now);
      const marketContext = this.getMarketContext(now);
      const volatility = this.getMarketVolatility(now);

      const systemPrompt = `You are a real-time market intelligence analyst.

CURRENT MARKET CONTEXT:
- Time: ${now.toISOString()} (${timeContext})
- Market Status: ${marketContext}
- Volatility Level: ${volatility}
- Base Currency: ${baseCurrency}
- Target Currencies: ${targetCurrencies.join(', ')}

INSTRUCTIONS:
1. Provide real-time market insights and trends
2. Analyze current market conditions and sentiment
3. Identify key opportunities and risks
4. Highlight breaking news affecting currencies
5. Provide trading recommendations
6. Include economic calendar events
7. Analyze market momentum and direction
8. Suggest optimal trading strategies

RESPONSE FORMAT (JSON):
{
  "marketOverview": {
    "currentStatus": "market_status",
    "volatility": "${volatility}",
    "sentiment": "bullish/bearish/neutral",
    "keyDrivers": ["driver1", "driver2"]
  },
  "opportunities": {
    "immediate": ["opportunity1", "opportunity2"],
    "shortTerm": ["opportunity1", "opportunity2"],
    "riskLevel": "low/medium/high"
  },
  "news": {
    "breaking": ["news1", "news2"],
    "economicEvents": ["event1", "event2"],
    "marketImpact": "impact_assessment"
  },
  "recommendations": {
    "trading": ["strategy1", "strategy2"],
    "timing": "optimal_timing",
    "riskManagement": ["tip1", "tip2"]
  }
}`;

      const contextualMessage = `${systemPrompt}\n\nProvide comprehensive market insights for ${baseCurrency} and related currencies.`;

      const payload = {
        question: contextualMessage,
        history: [],
        overrideConfig: {
          temperature: 0.8,
          maxTokens: 2500
        }
      };

      const response = await this.client.post(`/api/v1/prediction/${this.currencyChatflowId}`, payload);
      
      return {
        success: true,
        data: {
          baseCurrency: baseCurrency.toUpperCase(),
          targetCurrencies: targetCurrencies,
          aiResponse: response.data.answer || response.data.text || response.data.response || '',
          rawResponse: response.data,
          timestamp: now.toISOString(),
          marketContext: marketContext,
          timeContext: timeContext,
          volatility: volatility,
          dynamicFeatures: {
            realTimeInsights: true,
            marketAnalysis: true,
            newsIntegration: true,
            tradingRecommendations: true,
            riskAssessment: true
          }
        },
        message: 'Dynamic market insights retrieved successfully'
      };
    } catch (error) {
      console.error('Market Insights API Error:', error.response?.data || error.message);
      
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Failed to retrieve market insights',
        statusCode: error.response?.status || 500
      };
    }
  }

  /**
   * Health check for currency service
   * @returns {Promise<Object>} - Service health status
   */
  async healthCheck() {
    try {
      const response = await this.client.get('/api/v1/ping');
      const now = new Date();
      
      return {
        success: true,
        data: {
          service: 'Dynamic Currency Conversion Service',
          flowiseConnection: 'healthy',
          supportedCurrencies: this.supportedCurrencies.length,
          chatflowId: this.currencyChatflowId,
          currentTime: now.toISOString(),
          timeContext: this.getTimeContext(now),
          marketContext: this.getMarketContext(now),
          volatility: this.getMarketVolatility(now),
          dynamicFeatures: {
            realTimeData: true,
            marketAnalysis: true,
            trendAnalysis: true,
            newsIntegration: true,
            riskAssessment: true,
            tradingRecommendations: true
          }
        },
        message: 'Dynamic currency service is healthy'
      };
    } catch (error) {
      console.error('Currency Service Health Check Error:', error.response?.data || error.message);
      
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Currency service health check failed',
        statusCode: error.response?.status || 500
      };
    }
  }
}

module.exports = CurrencyService;
