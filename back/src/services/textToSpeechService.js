const textToSpeech = require('@google-cloud/text-to-speech');
const fs = require('fs');
const path = require('path');

class TextToSpeechService {
  constructor() {
    // Initialize the TTS client with error handling
    try {
      // Try API key first, then fall back to service account
      const apiKey = process.env.GOOGLE_API_KEY || process.env.GOOGLE_OAUTH_CREDENTIALS;
      
      if (apiKey) {
        this.client = new textToSpeech.TextToSpeechClient({
          apiKey: apiKey
        });
        this.isAvailable = true;
        console.log('✅ Text-to-Speech initialized with API key');
      } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
        this.client = new textToSpeech.TextToSpeechClient({
          // Credentials will be loaded from GOOGLE_APPLICATION_CREDENTIALS env var
        });
        this.isAvailable = true;
        console.log('✅ Text-to-Speech initialized with service account');
      } else {
        this.client = null;
        this.isAvailable = false;
        console.warn('⚠️ Text-to-Speech not available: No API key or credentials found');
      }
    } catch (error) {
      console.warn('Text-to-Speech service not available:', error.message);
      this.client = null;
      this.isAvailable = false;
    }

    // Default voice configurations for different languages
    this.defaultVoices = {
      'en': { languageCode: 'en-US', name: 'en-US-Wavenet-D' },
      'es': { languageCode: 'es-ES', name: 'es-ES-Wavenet-B' },
      'fr': { languageCode: 'fr-FR', name: 'fr-FR-Wavenet-A' },
      'de': { languageCode: 'de-DE', name: 'de-DE-Wavenet-A' },
      'it': { languageCode: 'it-IT', name: 'it-IT-Wavenet-A' },
      'pt': { languageCode: 'pt-PT', name: 'pt-PT-Wavenet-A' },
      'ru': { languageCode: 'ru-RU', name: 'ru-RU-Wavenet-A' },
      'ja': { languageCode: 'ja-JP', name: 'ja-JP-Wavenet-A' },
      'ko': { languageCode: 'ko-KR', name: 'ko-KR-Wavenet-A' },
      'zh': { languageCode: 'cmn-CN', name: 'cmn-CN-Standard-A' }, // Fixed: Use cmn-CN for Mandarin Chinese
      'ar': { languageCode: 'ar-XA', name: 'ar-XA-Standard-A' }, // Fixed: Use Standard instead of Wavenet
      'hi': { languageCode: 'hi-IN', name: 'hi-IN-Standard-A' }, // Fixed: Use Standard instead of Wavenet
      'th': { languageCode: 'th-TH', name: 'th-TH-Standard-A' },
      'vi': { languageCode: 'vi-VN', name: 'vi-VN-Standard-A' }
    };

    // Audio format options
    this.audioFormats = {
      'mp3': 'MP3',
      'wav': 'LINEAR16',
      'ogg': 'OGG_OPUS',
      'flac': 'FLAC'
    };
  }

  /**
   * Convert text to speech
   * @param {string} text - Text to convert to speech
   * @param {Object} options - Configuration options
   * @param {string} options.languageCode - Language code (e.g., 'en-US')
   * @param {string} options.voiceName - Voice name (e.g., 'en-US-Wavenet-D')
   * @param {string} options.audioFormat - Audio format ('mp3', 'wav', 'ogg', 'flac')
   * @param {number} options.speakingRate - Speaking rate (0.25 to 4.0)
   * @param {number} options.pitch - Pitch (-20.0 to 20.0)
   * @param {number} options.volumeGainDb - Volume gain in dB (-96.0 to 16.0)
   * @param {string} options.ssmlGender - Gender ('NEUTRAL', 'FEMALE', 'MALE')
   * @returns {Promise<Object>} - Result with audio buffer and metadata
   */
  async synthesize(text, options = {}) {
    try {
      // Check if TTS service is available
      if (!this.isAvailable || !this.client) {
        return {
          success: false,
          error: 'Text-to-Speech service not available',
          message: 'Google Cloud Text-to-Speech credentials not configured. Please set up GOOGLE_APPLICATION_CREDENTIALS environment variable.'
        };
      }

      if (!text || text.trim().length === 0) {
        return {
          success: false,
          error: 'Text is required for speech synthesis',
          message: 'Please provide text to convert to speech'
        };
      }

      // Set default options
      const {
        languageCode = 'en-US',
        voiceName,
        audioFormat = 'mp3',
        speakingRate = 1.0,
        pitch = 0.0,
        volumeGainDb = 0.0,
        ssmlGender = 'NEUTRAL'
      } = options;

      // Get voice name with fallback
      const selectedVoiceName = voiceName || this.getVoiceForLanguage(languageCode);

      // Validate audio format
      if (!this.audioFormats[audioFormat]) {
        return {
          success: false,
          error: 'Unsupported audio format',
          message: `Supported formats: ${Object.keys(this.audioFormats).join(', ')}`
        };
      }

      // Prepare the request
      const request = {
        input: { text: text },
        voice: {
          languageCode: languageCode,
          name: selectedVoiceName,
          ssmlGender: ssmlGender
        },
        audioConfig: {
          audioEncoding: this.audioFormats[audioFormat],
          speakingRate: speakingRate,
          pitch: pitch,
          volumeGainDb: volumeGainDb
        }
      };

      // Perform the text-to-speech request with fallback
      let response;
      try {
        [response] = await this.client.synthesizeSpeech(request);
      } catch (error) {
        // If voice doesn't exist, try with a fallback voice
        if (error.code === 3 && error.details && error.details.includes('does not exist')) {
          console.warn(`Voice ${selectedVoiceName} not available, trying fallback...`);
          
          // Try with a basic Standard voice
          const fallbackVoice = selectedVoiceName.replace('Wavenet', 'Standard');
          const fallbackRequest = {
            ...request,
            voice: {
              ...request.voice,
              name: fallbackVoice
            }
          };
          
          try {
            [response] = await this.client.synthesizeSpeech(fallbackRequest);
            console.log(`✅ Successfully used fallback voice: ${fallbackVoice}`);
          } catch (fallbackError) {
            // If fallback also fails, try with just the language code
            const basicVoice = `${languageCode}-Standard-A`;
            const basicRequest = {
              ...request,
              voice: {
                ...request.voice,
                name: basicVoice
              }
            };
            
            [response] = await this.client.synthesizeSpeech(basicRequest);
            console.log(`✅ Successfully used basic voice: ${basicVoice}`);
          }
        } else {
          throw error;
        }
      }

      return {
        success: true,
        data: {
          audioContent: response.audioContent,
          audioFormat: audioFormat,
          languageCode: languageCode,
          voiceName: selectedVoiceName,
          textLength: text.length,
          timestamp: new Date().toISOString()
        },
        message: 'Text-to-speech conversion completed successfully'
      };

    } catch (error) {
      console.error('Text-to-speech synthesis error:', error);
      
      // Handle specific Google Cloud errors
      if (error.code === 7) {
        return {
          success: false,
          error: 'Permission denied',
          message: 'Check your Google Cloud credentials and permissions for Text-to-Speech API'
        };
      } else if (error.code === 3) {
        return {
          success: false,
          error: 'Invalid argument',
          message: 'Invalid language code, voice name, or audio format'
        };
      } else if (error.code === 8) {
        return {
          success: false,
          error: 'Resource exhausted',
          message: 'Text-to-Speech API quota exceeded'
        };
      }

      return {
        success: false,
        error: 'Text-to-speech synthesis failed',
        message: error.message || 'Unknown error occurred during speech synthesis'
      };
    }
  }

  /**
   * Convert text to speech with SSML support
   * @param {string} ssml - SSML formatted text
   * @param {Object} options - Configuration options
   * @returns {Promise<Object>} - Result with audio buffer and metadata
   */
  async synthesizeSSML(ssml, options = {}) {
    try {
      // Check if TTS service is available
      if (!this.isAvailable || !this.client) {
        return {
          success: false,
          error: 'Text-to-Speech service not available',
          message: 'Google Cloud Text-to-Speech credentials not configured. Please set up GOOGLE_APPLICATION_CREDENTIALS environment variable.'
        };
      }

      if (!ssml || ssml.trim().length === 0) {
        return {
          success: false,
          error: 'SSML is required for speech synthesis',
          message: 'Please provide SSML formatted text'
        };
      }

      const {
        audioFormat = 'mp3',
        speakingRate = 1.0,
        pitch = 0.0,
        volumeGainDb = 0.0
      } = options;

      // Validate audio format
      if (!this.audioFormats[audioFormat]) {
        return {
          success: false,
          error: 'Unsupported audio format',
          message: `Supported formats: ${Object.keys(this.audioFormats).join(', ')}`
        };
      }

      // Prepare the request with SSML
      const request = {
        input: { ssml: ssml },
        voice: {
          languageCode: 'en-US', // SSML should specify language in the markup
          name: 'en-US-Wavenet-D'
        },
        audioConfig: {
          audioEncoding: this.audioFormats[audioFormat],
          speakingRate: speakingRate,
          pitch: pitch,
          volumeGainDb: volumeGainDb
        }
      };

      // Perform the text-to-speech request
      const [response] = await this.client.synthesizeSpeech(request);

      return {
        success: true,
        data: {
          audioContent: response.audioContent,
          audioFormat: audioFormat,
          textLength: ssml.length,
          timestamp: new Date().toISOString()
        },
        message: 'SSML text-to-speech conversion completed successfully'
      };

    } catch (error) {
      console.error('SSML text-to-speech synthesis error:', error);
      return {
        success: false,
        error: 'SSML text-to-speech synthesis failed',
        message: error.message || 'Unknown error occurred during SSML speech synthesis'
      };
    }
  }

  /**
   * Get available voices for a language
   * @param {string} languageCode - Language code (e.g., 'en-US')
   * @returns {Promise<Object>} - Available voices for the language
   */
  async getVoices(languageCode = 'en-US') {
    try {
      // Check if TTS service is available
      if (!this.isAvailable || !this.client) {
        return {
          success: false,
          error: 'Text-to-Speech service not available',
          message: 'Google Cloud Text-to-Speech credentials not configured. Please set up GOOGLE_APPLICATION_CREDENTIALS environment variable.'
        };
      }

      const [result] = await this.client.listVoices({
        languageCode: languageCode
      });

      return {
        success: true,
        data: {
          voices: result.voices || [],
          languageCode: languageCode
        },
        message: 'Voices retrieved successfully'
      };

    } catch (error) {
      console.error('Get voices error:', error);
      return {
        success: false,
        error: 'Failed to retrieve voices',
        message: error.message || 'Unknown error occurred while retrieving voices'
      };
    }
  }

  /**
   * Get supported languages and their default voices
   * @returns {Object} - Supported languages and voices
   */
  getSupportedLanguages() {
    return {
      success: true,
      data: {
        languages: Object.keys(this.defaultVoices).map(code => ({
          code: code,
          languageCode: this.defaultVoices[code].languageCode,
          defaultVoice: this.defaultVoices[code].name,
          name: this.getLanguageName(code)
        })),
        audioFormats: Object.keys(this.audioFormats),
        message: 'Supported languages and voices retrieved successfully'
      }
    };
  }

  /**
   * Get the correct voice for a language with fallback options
   * @param {string} languageCode - Language code (e.g., 'zh-CN')
   * @returns {string} - Voice name
   */
  getVoiceForLanguage(languageCode) {
    const langPrefix = languageCode.split('-')[0];
    const voiceConfig = this.defaultVoices[langPrefix];
    
    if (voiceConfig) {
      return voiceConfig.name;
    }
    
    // Fallback voices for common languages
    const fallbackVoices = {
      'zh': 'cmn-CN-Standard-A',
      'ar': 'ar-XA-Standard-A', 
      'hi': 'hi-IN-Standard-A',
      'th': 'th-TH-Standard-A',
      'vi': 'vi-VN-Standard-A'
    };
    
    return fallbackVoices[langPrefix] || 'en-US-Wavenet-D';
  }

  /**
   * Get human-readable language name
   * @param {string} code - Language code
   * @returns {string} - Language name
   */
  getLanguageName(code) {
    const languageNames = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'ar': 'Arabic',
      'hi': 'Hindi',
      'th': 'Thai',
      'vi': 'Vietnamese'
    };
    return languageNames[code] || code;
  }

  /**
   * Save audio content to file
   * @param {Buffer} audioContent - Audio buffer
   * @param {string} filename - Output filename
   * @param {string} audioFormat - Audio format
   * @returns {Promise<Object>} - File save result
   */
  async saveAudioToFile(audioContent, filename, audioFormat = 'mp3') {
    try {
      const outputDir = path.join(__dirname, '../../audio-output');
      
      // Create output directory if it doesn't exist
      if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
      }

      const filePath = path.join(outputDir, `${filename}.${audioFormat}`);
      fs.writeFileSync(filePath, audioContent);

      return {
        success: true,
        data: {
          filePath: filePath,
          filename: `${filename}.${audioFormat}`,
          size: audioContent.length
        },
        message: 'Audio file saved successfully'
      };

    } catch (error) {
      console.error('Save audio file error:', error);
      return {
        success: false,
        error: 'Failed to save audio file',
        message: error.message || 'Unknown error occurred while saving audio file'
      };
    }
  }
}

module.exports = TextToSpeechService;
