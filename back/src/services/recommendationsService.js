const FlowiseService = require('./flowiseService');

class RecommendationsService {
  constructor() {
    this.flowiseService = new FlowiseService();
  }

  /**
   * Get personalized recommendations based on user message and chat history
   * @param {Object} params - Recommendation parameters
   * @param {string} params.userMessage - User's message/query
   * @param {string} params.chatflowId - Flowise chatflow ID for recommendations
   * @param {Array} params.chatHistory - Previous chat messages
   * @returns {Promise<Object>} - Personalized recommendations
   */
  async getPersonalizedRecommendations(params) {
    try {
      const {
        userMessage,
        chatflowId,
        chatHistory = []
      } = params;

      if (!userMessage || !chatflowId) {
        throw new Error('userMessage and chatflowId are required');
      }

      // Prepare chat history for Flowise
      const history = chatHistory.map(msg => ({
        role: msg.role === 'user' ? 'userMessage' : 'apiMessage',
        content: msg.text || msg.content || ''
      }));

      // Use FlowiseService to send the user message with chat history
      const result = await this.flowiseService.sendChatMessage(userMessage, chatflowId, { history });
      
      if (result.success) {
        return {
          success: true,
          data: {
            recommendations: this._parseRecommendationsResponse(result.data),
            metadata: {
              userMessage,
              chatHistoryLength: chatHistory.length,
              timestamp: new Date().toISOString()
            }
          },
          message: 'Personalized recommendations generated successfully'
        };
      } else {
        return {
          success: false,
          error: result.error,
          statusCode: result.statusCode || 500
        };
      }
    } catch (error) {
      console.error('Recommendations API Error:', error);
      
      return {
        success: false,
        error: error.message || 'Failed to generate recommendations',
        statusCode: 500
      };
    }
  }

  /**
   * Get cultural etiquette information for a specific location
   * @param {Object} params - Cultural etiquette parameters
   * @param {string} params.location - Destination location
   * @param {string} params.chatflowId - Flowise chatflow ID for cultural etiquette
   * @param {Array} params.specificTopics - Specific cultural topics to focus on
   * @returns {Promise<Object>} - Cultural etiquette information
   */
  async getCulturalEtiquette(params) {
    try {
      const {
        location,
        chatflowId,
        specificTopics = []
      } = params;

      if (!location || !chatflowId) {
        throw new Error('Location and chatflowId are required');
      }

      // Create a simple prompt for cultural etiquette (like translation API)
      const simplePrompt = `Provide cultural etiquette information for ${location}. Focus on: ${specificTopics.join(', ') || 'general etiquette'}.`;

      // Use FlowiseService to send the message, just like translation API does
      const result = await this.flowiseService.sendChatMessage(simplePrompt, chatflowId, {});
      
      if (result.success) {
        return {
          success: true,
          data: {
            culturalEtiquette: this._parseCulturalEtiquetteResponse(result.data),
            metadata: {
              location,
              specificTopics,
              timestamp: new Date().toISOString()
            }
          },
          message: 'Cultural etiquette information retrieved successfully'
        };
      } else {
        return {
          success: false,
          error: result.error,
          statusCode: result.statusCode || 500
        };
      }
    } catch (error) {
      console.error('Cultural Etiquette API Error:', error);
      
      return {
        success: false,
        error: error.message || 'Failed to retrieve cultural etiquette information',
        statusCode: 500
      };
    }
  }

  /**
   * Get comprehensive travel recommendations including both attractions and cultural etiquette
   * @param {Object} params - Comprehensive recommendation parameters
   * @returns {Promise<Object>} - Complete travel recommendations
   */
  async getComprehensiveRecommendations(params) {
    try {
      const {
        location,
        interests = [],
        budget = 'medium',
        preferences = {},
        duration = '1 week',
        travelStyle = 'tourist',
        dietaryRestrictions = [],
        recommendationsChatflowId,
        culturalEtiquetteChatflowId,
        includeCulturalEtiquette = true
      } = params;

      if (!location || !recommendationsChatflowId) {
        throw new Error('Location and recommendationsChatflowId are required');
      }

      // Get personalized recommendations
      const recommendationsResult = await this.getPersonalizedRecommendations({
        location,
        interests,
        budget,
        preferences,
        duration,
        travelStyle,
        dietaryRestrictions,
        chatflowId: recommendationsChatflowId
      });

      let culturalEtiquetteResult = null;
      
      // Get cultural etiquette if requested and chatflowId provided
      if (includeCulturalEtiquette && culturalEtiquetteChatflowId) {
        culturalEtiquetteResult = await this.getCulturalEtiquette({
          location,
          chatflowId: culturalEtiquetteChatflowId,
          specificTopics: interests
        });
      }

      return {
        success: true,
        data: {
          recommendations: recommendationsResult.success ? recommendationsResult.data : null,
          culturalEtiquette: culturalEtiquetteResult?.success ? culturalEtiquetteResult.data : null,
          metadata: {
            location,
            interests,
            budget,
            duration,
            travelStyle,
            timestamp: new Date().toISOString()
          }
        },
        message: 'Comprehensive travel recommendations generated successfully'
      };
    } catch (error) {
      console.error('Comprehensive Recommendations Error:', error);
      
      return {
        success: false,
        error: error.message || 'Failed to generate comprehensive recommendations',
        statusCode: 500
      };
    }
  }

  /**
   * Build the recommendations prompt for Flowise
   * @private
   */
  _buildRecommendationsPrompt(params) {
    const {
      location,
      interests,
      budget,
      preferences,
      duration,
      travelStyle,
      dietaryRestrictions
    } = params;

    let prompt = `You are a professional travel advisor. Provide personalized recommendations for a trip to ${location}.\n\n`;
    
    prompt += `**Trip Details:**\n`;
    prompt += `- Location: ${location}\n`;
    prompt += `- Duration: ${duration}\n`;
    prompt += `- Travel Style: ${travelStyle}\n`;
    prompt += `- Budget Level: ${budget}\n`;
    
    if (interests.length > 0) {
      prompt += `- Interests: ${interests.join(', ')}\n`;
    }
    
    if (dietaryRestrictions.length > 0) {
      prompt += `- Dietary Restrictions: ${dietaryRestrictions.join(', ')}\n`;
    }
    
    if (Object.keys(preferences).length > 0) {
      prompt += `- Additional Preferences: ${JSON.stringify(preferences)}\n`;
    }
    
    prompt += `\n**Please provide recommendations in the following JSON format:**\n`;
    prompt += `{\n`;
    prompt += `  "attractions": [\n`;
    prompt += `    {\n`;
    prompt += `      "name": "Attraction Name",\n`;
    prompt += `      "type": "museum|restaurant|activity|landmark|entertainment",\n`;
    prompt += `      "description": "Brief description",\n`;
    prompt += `      "budgetLevel": "low|medium|high|luxury",\n`;
    prompt += `      "estimatedCost": "Cost range or free",\n`;
    prompt += `      "duration": "Time needed to visit",\n`;
    prompt += `      "bestTimeToVisit": "When to go",\n`;
    prompt += `      "whyRecommended": "Why this fits the user's interests"\n`;
    prompt += `    }\n`;
    prompt += `  ],\n`;
    prompt += `  "restaurants": [\n`;
    prompt += `    {\n`;
    prompt += `      "name": "Restaurant Name",\n`;
    prompt += `      "cuisine": "Type of cuisine",\n`;
    prompt += `      "priceRange": "$|$$|$$$|$$$$",\n`;
    prompt += `      "description": "What makes it special",\n`;
    prompt += `      "dietaryFriendly": "Vegetarian/Vegan/Gluten-free options",\n`;
    prompt += `      "location": "Area/neighborhood",\n`;
    prompt += `      "whyRecommended": "Why this fits the user's preferences"\n`;
    prompt += `    }\n`;
    prompt += `  ],\n`;
    prompt += `  "activities": [\n`;
    prompt += `    {\n`;
    prompt += `      "name": "Activity Name",\n`;
    prompt += `      "type": "outdoor|indoor|cultural|adventure|relaxation",\n`;
    prompt += `      "description": "What the activity involves",\n`;
    prompt += `      "budgetLevel": "low|medium|high|luxury",\n`;
    prompt += `      "estimatedCost": "Cost range",\n`;
    prompt += `      "duration": "How long it takes",\n`;
    prompt += `      "bestTimeToDo": "When to do this activity",\n`;
    prompt += `      "whyRecommended": "Why this fits the user's interests"\n`;
    prompt += `    }\n`;
    prompt += `  ],\n`;
    prompt += `  "itinerary": {\n`;
    prompt += `    "day1": "Suggested activities for first day",\n`;
    prompt += `    "day2": "Suggested activities for second day",\n`;
    prompt += `    "day3": "Suggested activities for third day"\n`;
    prompt += `  },\n`;
    prompt += `  "tips": [\n`;
    prompt += `    "Practical travel tips for this destination",\n`;
    prompt += `    "Money-saving tips",\n`;
    prompt += `    "Safety considerations"\n`;
    prompt += `  ]\n`;
    prompt += `}\n\n`;
    
    prompt += `Focus on providing practical, actionable recommendations that match the user's budget, interests, and travel style. Include both popular attractions and hidden gems.`;

    return prompt;
  }

  /**
   * Build the cultural etiquette prompt for Flowise
   * @private
   */
  _buildCulturalEtiquettePrompt(location, specificTopics) {
    let prompt = `You are a cultural etiquette expert. Provide detailed cultural etiquette information for ${location}.\n\n`;
    
    if (specificTopics.length > 0) {
      prompt += `**Focus Areas:** ${specificTopics.join(', ')}\n\n`;
    }
    
    prompt += `**Please provide cultural etiquette information in the following JSON format:**\n`;
    prompt += `{\n`;
    prompt += `  "generalEtiquette": {\n`;
    prompt += `    "greetings": "How to greet people properly",\n`;
    prompt += `    "dressCode": "Appropriate clothing and dress codes",\n`;
    prompt += `    "bodyLanguage": "Important body language and gestures",\n`;
    prompt += `    "personalSpace": "Personal space and physical contact norms"\n`;
    prompt += `  },\n`;
    prompt += `  "diningEtiquette": {\n`;
    prompt += `    "tableManners": "Proper table manners and dining customs",\n`;
    prompt += `    "tipping": "Tipping customs and expectations",\n`;
    prompt += `    "diningTimes": "Typical meal times and dining culture",\n`;
    prompt += `    "foodCustoms": "Special food-related customs and traditions"\n`;
    prompt += `  },\n`;
    prompt += `  "socialEtiquette": {\n`;
    prompt += `    "conversation": "Conversation topics and taboos",\n`;
    prompt += `    "giftGiving": "Gift giving customs and traditions",\n`;
    prompt += `    "businessEtiquette": "Business meeting and professional customs",\n`;
    prompt += `    "religiousConsiderations": "Religious customs and considerations"\n`;
    prompt += `  },\n`;
    prompt += `  "dosAndDonts": {\n`;
    prompt += `    "dos": [\n`;
    prompt += `      "Things you should do in this culture",\n`;
    prompt += `      "Positive behaviors to adopt"\n`;
    prompt += `    ],\n`;
    prompt += `    "donts": [\n`;
    prompt += `      "Things you should avoid doing",\n`;
    prompt += `      "Behaviors that are considered rude or offensive"\n`;
    prompt += `    ]\n`;
    prompt += `  },\n`;
    prompt += `  "languageTips": {\n`;
    prompt += `    "commonPhrases": ["Useful local phrases", "Greetings", "Thank you", "Please", "Excuse me"],\n`;
    prompt += `    "pronunciation": "Pronunciation tips for common words",\n`;
    prompt += `    "formality": "Formal vs informal language usage"\n`;
    prompt += `  },\n`;
    prompt += `  "culturalNorms": {\n`;
    prompt += `    "timePunctuality": "Attitudes towards time and punctuality",\n`;
    prompt += `    "familyValues": "Family and social structure importance",\n`;
    prompt += `    "hierarchy": "Social hierarchy and respect customs",\n`;
    prompt += `    "celebrations": "Important celebrations and holidays"\n`;
    prompt += `  }\n`;
    prompt += `}\n\n`;
    
    prompt += `Provide specific, practical advice that will help travelers avoid cultural misunderstandings and show respect for local customs. Include both general cultural norms and specific etiquette rules.`;

    return prompt;
  }

  /**
   * Parse the recommendations response from Flowise
   * @private
   */
  _parseRecommendationsResponse(responseData) {
    try {
      // Try to extract JSON from the response
      const responseText = responseData.answer || responseData.text || responseData.response || '';
      
      // Look for JSON in the response
      const jsonMatch = responseText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
      
      // If no JSON found, return the raw response
      return {
        rawResponse: responseText,
        parsed: false
      };
    } catch (error) {
      console.error('Error parsing recommendations response:', error);
      return {
        rawResponse: responseData.answer || responseData.text || responseData.response || '',
        parsed: false,
        error: 'Failed to parse structured recommendations'
      };
    }
  }

  /**
   * Parse the cultural etiquette response from Flowise
   * @private
   */
  _parseCulturalEtiquetteResponse(responseData) {
    try {
      // Try to extract JSON from the response
      const responseText = responseData.answer || responseData.text || responseData.response || '';
      
      // Look for JSON in the response
      const jsonMatch = responseText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
      
      // If no JSON found, return the raw response
      return {
        rawResponse: responseText,
        parsed: false
      };
    } catch (error) {
      console.error('Error parsing cultural etiquette response:', error);
      return {
        rawResponse: responseData.answer || responseData.text || responseData.response || '',
        parsed: false,
        error: 'Failed to parse structured cultural etiquette information'
      };
    }
  }

  /**
   * Health check for recommendations service
   * @returns {Promise<Object>} - Service health status
   */
  async healthCheck() {
    try {
      const result = await this.flowiseService.healthCheck();
      
      if (result.success) {
        return {
          success: true,
          data: result.data,
          message: 'Recommendations service is healthy'
        };
      } else {
        return {
          success: false,
          error: result.error,
          statusCode: result.statusCode || 500
        };
      }
    } catch (error) {
      console.error('Recommendations Service Health Check Error:', error);
      
      return {
        success: false,
        error: error.message || 'Recommendations service connection failed',
        statusCode: 500
      };
    }
  }
}

module.exports = RecommendationsService;
