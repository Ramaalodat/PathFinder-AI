const axios = require('axios');

class FlowiseService {
  constructor() {
    this.apiUrl = process.env.FLOWISE_API_URL || 'https://cloud.flowiseai.com';
    this.apiKey = process.env.FLOWISE_API_KEY;
    
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
  }

  /**
   * Send a chat message to Flowise and get AI response
   * @param {string} message - The user message
   * @param {string} chatflowId - The Flowise chatflow ID
   * @param {Object} options - Additional options like language, context, etc.
   * @returns {Promise<Object>} - AI response from Flowise
   */
  async sendChatMessage(message, chatflowId, options = {}) {
    try {
      let contextualMessage = message;
      
      // Handle image requests differently
      if (options.isImageRequest) {
        // For image requests, send the message as-is since it contains the image data
        contextualMessage = message;
      } else if (options.sourceLanguage || options.targetLanguage) {
        // Only add translation-specific prompts for text translation requests
        const systemPrompt = `You are a translator, translate from language ${options.sourceLanguage || 'auto'} to language ${options.targetLanguage || 'auto'}`;
        contextualMessage = `${systemPrompt}\n\nText to translate: "${message}"`;
      }
      
      const payload = {
        question: contextualMessage,
        history: options.history || []
      };

      // Debug: Log what we're sending to Flowise (but truncate image data for readability)
      const debugPayload = { ...payload };
      if (debugPayload.question && debugPayload.question.includes('Image: data:')) {
        debugPayload.question = debugPayload.question.substring(0, 200) + '...[Image data truncated]';
      }
      console.log('Sending to Flowise:', JSON.stringify(debugPayload, null, 2));
      console.log('API URL:', `${this.apiUrl}/api/v1/prediction/${chatflowId}`);
      
      const response = await this.client.post(`/api/v1/prediction/${chatflowId}`, payload);
      
      // Debug: Log what we get back from Flowise
      console.log('Response from Flowise:', JSON.stringify(response.data, null, 2));
      
      return {
        success: true,
        data: response.data,
        message: response.data.answer || response.data.text || response.data.response || 'Translation completed'
      };
    } catch (error) {
      console.error('Flowise API Error:', error.response?.data || error.message);
      
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Failed to process translation request',
        statusCode: error.response?.status || 500
      };
    }
  }

  /**
   * Send an image to Flowise for analysis using the correct uploads format
   * @param {Buffer} imageBuffer - The image buffer
   * @param {string} mimeType - The image MIME type
   * @param {string} chatflowId - The Flowise chatflow ID
   * @param {string} prompt - The analysis prompt
   * @param {Object} options - Additional options
   * @returns {Promise<Object>} - AI response from Flowise
   */
  async sendImageMessage(imageBuffer, mimeType, chatflowId, prompt, options = {}) {
    try {
      // Convert image to base64 data URL
      const imageBase64 = imageBuffer.toString('base64');
      const dataUrl = `data:${mimeType};base64,${imageBase64}`;
      
      // Create payload with uploads array as per Flowise documentation
      const payload = {
        question: prompt,
        uploads: [
          {
            data: dataUrl,
            type: "file",
            name: `image.${mimeType.split('/')[1]}`,
            mime: mimeType
          }
        ],
        history: options.history || []
      };

      console.log('Sending image to Flowise using uploads format');
      console.log('API URL:', `${this.apiUrl}/api/v1/prediction/${chatflowId}`);
      console.log('Image size:', imageBuffer.length, 'bytes');
      console.log('MIME type:', mimeType);
      console.log('Data URL length:', dataUrl.length, 'characters');
      
      const response = await this.client.post(`/api/v1/prediction/${chatflowId}`, payload, {
        timeout: 120000 // 2 minutes timeout for image processing
      });
      
      // Debug: Log what we get back from Flowise
      console.log('Response from Flowise:', JSON.stringify(response.data, null, 2));
      
      return {
        success: true,
        data: response.data,
        message: response.data.answer || response.data.text || response.data.response || 'Image analysis completed'
      };
    } catch (error) {
      console.error('Flowise Image API Error:', error.response?.data || error.message);
      
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Failed to process image request',
        statusCode: error.response?.status || 500
      };
    }
  }


  /**
   * Get available chatflows from Flowise
   * @returns {Promise<Object>} - List of available chatflows
   */
  async getChatflows() {
    try {
      const response = await this.client.get('/api/v1/chatflows');
      
      return {
        success: true,
        data: response.data,
        message: 'Chatflows retrieved successfully'
      };
    } catch (error) {
      console.error('Flowise Chatflows API Error:', error.response?.data || error.message);
      
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Failed to retrieve chatflows',
        statusCode: error.response?.status || 500
      };
    }
  }

  /**
   * Health check for Flowise connection
   * @returns {Promise<Object>} - Connection status
   */
  async healthCheck() {
    try {
      const response = await this.client.get('/api/v1/ping');
      
      return {
        success: true,
        data: response.data,
        message: 'Flowise connection is healthy'
      };
    } catch (error) {
      console.error('Flowise Health Check Error:', error.response?.data || error.message);
      
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Flowise connection failed',
        statusCode: error.response?.status || 500
      };
    }
  }
}

module.exports = FlowiseService;
