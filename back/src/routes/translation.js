const express = require('express');
const Joi = require('joi');
const FlowiseService = require('../services/flowiseService');
const multer = require('multer');
const SpeechToTextService = require('../services/speechToTextService');
const TextToSpeechService = require('../services/textToSpeechService');

const router = express.Router();
const flowiseService = new FlowiseService();
const sttService = new SpeechToTextService();
const ttsService = new TextToSpeechService();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 15 * 1024 * 1024 // 15MB
  },
  fileFilter: (req, file, cb) => {
    // Accept both image and audio files
    if (file.mimetype.startsWith('image/') || file.mimetype.startsWith('audio/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image and audio files are allowed'), false);
    }
  }
});

// Validation schemas
const textTranslationSchema = Joi.object({
  message: Joi.string().min(1).max(5000).required(),
  chatflowId: Joi.string().required(),
  sourceLanguage: Joi.string().min(2).max(10).optional(),
  targetLanguage: Joi.string().min(2).max(10).optional(),
  history: Joi.array().items(Joi.object({
    message: Joi.string().required(),
    type: Joi.string().valid('user', 'assistant').required()
  })).optional()
});

/**
 * POST /api/translation/text
 * Translate text using Flowise AI agent
 */
router.post('/text', async (req, res) => {
  try {
    const {
      message,
      sourceLanguage,
      targetLanguage,
      history
    } = req.body;
    const chatflowId = req.body.chatflowId || process.env.DEFAULT_TRANSLATION_CHATFLOW_ID;

    // Basic validation
    if (!message || !chatflowId) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        message: 'Both message and chatflowId are required'
      });
    }

    // Prepare options for Flowise
    const options = {
      sourceLanguage: sourceLanguage || 'auto',
      targetLanguage: targetLanguage || 'auto',
      history
    };

    // Send request to Flowise
    const result = await flowiseService.sendChatMessage(message, chatflowId, options);

    if (result.success) {
      res.json({
        success: true,
        data: {
          originalText: message,
          translatedText: result.data.answer || result.data.text || result.data.response,
          sourceLanguage: sourceLanguage || 'auto',
          targetLanguage: targetLanguage || 'auto',
          timestamp: new Date().toISOString()
        },
        message: 'Text translation completed successfully'
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: 'Failed to translate text'
      });
    }
  } catch (error) {
    console.error('Text translation error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during text translation',
      message: error.message
    });
  }
});

/**
 * POST /api/translation/test
 * Simple test endpoint for easy API testing
 */
router.post('/test', async (req, res) => {
  try {
    const { message, sourceLanguage, targetLanguage } = req.body;
    const chatflowId = req.body.chatflowId || process.env.DEFAULT_TRANSLATION_CHATFLOW_ID;

    // Validate required fields
    if (!message || !chatflowId) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        message: 'Both message and chatflowId are required'
      });
    }

    // Prepare options for Flowise
    const options = {
      sourceLanguage: sourceLanguage || 'auto',
      targetLanguage: targetLanguage || 'auto'
    };

    // Send request to Flowise
    const result = await flowiseService.sendChatMessage(message, chatflowId, options);

    if (result.success) {
      res.json({
        success: true,
        data: {
          originalText: message,
          translatedText: result.data.answer || result.data.text || result.data.response,
          sourceLanguage: sourceLanguage || 'auto',
          targetLanguage: targetLanguage || 'auto',
          timestamp: new Date().toISOString()
        },
        message: 'Test translation completed successfully'
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: 'Failed to translate text'
      });
    }
  } catch (error) {
    console.error('Test translation error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during test translation',
      message: error.message
    });
  }
});

/**
 * GET /api/translation/chatflows
 * Get available chatflows from Flowise
 */
router.get('/chatflows', async (req, res) => {
  try {
    const result = await flowiseService.getChatflows();

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: 'Chatflows retrieved successfully'
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: 'Failed to retrieve chatflows'
      });
    }
  } catch (error) {
    console.error('Get chatflows error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error while retrieving chatflows',
      message: error.message
    });
  }
});

/**
 * GET /api/translation/languages
 * Get supported languages for translation
 */
router.get('/languages', (req, res) => {
  res.json({
    success: true,
    data: {
      supportedLanguages: [
        { code: 'en', name: 'English' },
        { code: 'es', name: 'Spanish' },
        { code: 'fr', name: 'French' },
        { code: 'de', name: 'German' },
        { code: 'it', name: 'Italian' },
        { code: 'pt', name: 'Portuguese' },
        { code: 'ru', name: 'Russian' },
        { code: 'ja', name: 'Japanese' },
        { code: 'ko', name: 'Korean' },
        { code: 'zh', name: 'Chinese' },
        { code: 'ar', name: 'Arabic' },
        { code: 'hi', name: 'Hindi' },
        { code: 'th', name: 'Thai' },
        { code: 'vi', name: 'Vietnamese' },
        { code: 'auto', name: 'Auto-detect' }
      ],
      commonTouristLanguages: [
        'en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh', 'ar'
      ]
    },
    message: 'Supported languages retrieved successfully'
  });
});

/**
 * POST /api/translation/text-to-speech
 * Convert text to speech using Google TTS
 */
router.post('/text-to-speech', async (req, res) => {
  try {
    const {
      text,
      languageCode = 'en-US',
      voiceName,
      audioFormat = 'mp3',
      speakingRate = 1.0,
      pitch = 0.0,
      volumeGainDb = 0.0,
      ssmlGender = 'NEUTRAL'
    } = req.body;

    if (!text || text.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Text is required',
        message: 'Please provide text to convert to speech'
      });
    }

    const options = {
      languageCode,
      voiceName,
      audioFormat,
      speakingRate,
      pitch,
      volumeGainDb,
      ssmlGender
    };

    const result = await ttsService.synthesize(text, options);

    if (result.success) {
      // Set appropriate headers for audio response
      res.set({
        'Content-Type': `audio/${audioFormat}`,
        'Content-Length': result.data.audioContent.length,
        'Content-Disposition': `attachment; filename="speech.${audioFormat}"`
      });

      res.send(result.data.audioContent);
    } else {
      res.status(400).json({
        success: false,
        error: result.error,
        message: result.message
      });
    }
  } catch (error) {
    console.error('Text-to-speech error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during text-to-speech conversion',
      message: error.message
    });
  }
});

/**
 * POST /api/translation/translate-and-speak
 * Translate text and convert to speech
 */
router.post('/translate-and-speak', async (req, res) => {
  try {
    const {
      message,
      chatflowId,
      sourceLanguage = 'auto',
      targetLanguage = 'auto',
      history,
      // TTS options
      audioFormat = 'mp3',
      speakingRate = 1.0,
      pitch = 0.0,
      volumeGainDb = 0.0,
      ssmlGender = 'NEUTRAL',
      returnAudio = true
    } = req.body;

    if (!message || !chatflowId) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        message: 'Both message and chatflowId are required'
      });
    }

    // First, translate the text
    const options = {
      sourceLanguage,
      targetLanguage,
      history
    };

    const translationResult = await flowiseService.sendChatMessage(message, chatflowId, options);

    if (!translationResult.success) {
      return res.status(translationResult.statusCode || 500).json({
        success: false,
        error: translationResult.error,
        message: 'Failed to translate text'
      });
    }

    const translatedText = translationResult.data.answer || translationResult.data.text || translationResult.data.response;

    // Determine language code for TTS based on target language
    const languageCode = targetLanguage === 'auto' ? 'en-US' : 
      ttsService.defaultVoices[targetLanguage]?.languageCode || 'en-US';

    const response = {
      success: true,
      data: {
        originalText: message,
        translatedText: translatedText,
        sourceLanguage,
        targetLanguage,
        timestamp: new Date().toISOString()
      },
      message: 'Translation completed successfully'
    };

    if (returnAudio) {
      // Convert translated text to speech
      const ttsOptions = {
        languageCode,
        audioFormat,
        speakingRate,
        pitch,
        volumeGainDb,
        ssmlGender
      };

      const ttsResult = await ttsService.synthesize(translatedText, ttsOptions);

      if (ttsResult.success) {
        response.data.audio = {
          format: audioFormat,
          size: ttsResult.data.audioContent.length,
          languageCode: languageCode,
          voiceName: ttsResult.data.voiceName
        };

        // If client wants audio in response body, include it
        if (req.body.includeAudioInResponse) {
          response.data.audioContent = ttsResult.data.audioContent.toString('base64');
        }
      } else {
        response.warnings = response.warnings || [];
        response.warnings.push(`Text-to-speech failed: ${ttsResult.message}`);
        console.warn('TTS Warning:', ttsResult.message);
      }
    }

    res.json(response);

  } catch (error) {
    console.error('Translate and speak error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during translation and speech conversion',
      message: error.message
    });
  }
});

/**
 * POST /api/translation/audio-translate-speak
 * Complete audio pipeline: audio input -> transcription -> translation -> speech output
 */
router.post('/audio-translate-speak', upload.single('file'), async (req, res) => {
  try {
    const {
      chatflowId = process.env.DEFAULT_TRANSLATION_CHATFLOW_ID,
      sourceLanguage = 'auto',
      targetLanguage = 'auto',
      languageCode, // for STT
      languageCodes, // for auto-detection
      // TTS options
      audioFormat = 'mp3',
      speakingRate = 1.0,
      pitch = 0.0,
      volumeGainDb = 0.0,
      ssmlGender = 'NEUTRAL',
      returnAudio = true
    } = req.body;

    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'No audio file uploaded',
        message: 'Upload an audio file in form-data with key "file"'
      });
    }

    if (!chatflowId) {
      return res.status(400).json({
        success: false,
        error: 'Missing chatflowId',
        message: 'Provide chatflowId or set DEFAULT_TRANSLATION_CHATFLOW_ID'
      });
    }

    // Step 1: Transcribe audio
    const mimeType = req.file.mimetype || 'audio/webm';
    const transcription = await sttService.transcribe(req.file.buffer, {
      mimeType,
      languageCode,
      languageCodes: languageCodes ? JSON.parse(languageCodes) : undefined
    });

    if (!transcription.success) {
      return res.status(502).json({
        success: false,
        error: transcription.error || 'Speech transcription failed',
        details: transcription.raw || null,
        message: 'Speech transcription failed'
      });
    }

    // Step 2: Translate text
    const options = { sourceLanguage, targetLanguage };
    const translationResult = await flowiseService.sendChatMessage(transcription.text, chatflowId, options);

    if (!translationResult.success) {
      return res.status(translationResult.statusCode || 500).json({
        success: false,
        error: translationResult.error,
        message: 'Failed to translate transcribed text'
      });
    }

    const translatedText = translationResult.data.answer || translationResult.data.text || translationResult.data.response;

    const response = {
      success: true,
      data: {
        originalText: transcription.text,
        translatedText: translatedText,
        sourceLanguage,
        targetLanguage,
        sttLanguageCode: languageCode || process.env.GOOGLE_SPEECH_LANGUAGE_CODE || 'en-US',
        timestamp: new Date().toISOString()
      },
      message: 'Audio translation completed successfully'
    };

    if (returnAudio) {
      // Step 3: Convert translated text to speech
      const languageCodeForTTS = targetLanguage === 'auto' ? 'en-US' : 
        ttsService.defaultVoices[targetLanguage]?.languageCode || 'en-US';

      const ttsOptions = {
        languageCode: languageCodeForTTS,
        audioFormat,
        speakingRate,
        pitch,
        volumeGainDb,
        ssmlGender
      };

      const ttsResult = await ttsService.synthesize(translatedText, ttsOptions);

      if (ttsResult.success) {
        response.data.audio = {
          format: audioFormat,
          size: ttsResult.data.audioContent.length,
          languageCode: languageCodeForTTS,
          voiceName: ttsResult.data.voiceName
        };

        // If client wants audio in response body, include it
        if (req.body.includeAudioInResponse) {
          response.data.audioContent = ttsResult.data.audioContent.toString('base64');
        }
      } else {
        response.warnings = response.warnings || [];
        response.warnings.push(`Text-to-speech failed: ${ttsResult.message}`);
        console.warn('TTS Warning:', ttsResult.message);
      }
    }

    res.json(response);

  } catch (error) {
    console.error('Audio translate speak error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during audio translation and speech conversion',
      message: error.message
    });
  }
});

/**
 * GET /api/translation/voices
 * Get available voices for text-to-speech
 */
router.get('/voices', async (req, res) => {
  try {
    const { languageCode = 'en-US' } = req.query;

    const result = await ttsService.getVoices(languageCode);

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        message: 'Voices retrieved successfully'
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.error,
        message: result.message
      });
    }
  } catch (error) {
    console.error('Get voices error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error while retrieving voices',
      message: error.message
    });
  }
});

/**
 * GET /api/translation/tts-languages
 * Get supported languages for text-to-speech
 */
router.get('/tts-languages', (req, res) => {
  try {
    const result = ttsService.getSupportedLanguages();
    res.json(result);
  } catch (error) {
    console.error('Get TTS languages error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error while retrieving TTS languages',
      message: error.message
    });
  }
});

/**
 * POST /api/translation/image-debug
 * Debug endpoint to see what we're sending to Flowise
 */
router.post('/image-debug', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'No image file uploaded'
      });
    }

    const imageBase64 = req.file.buffer.toString('base64');
    const mimeType = req.file.mimetype || 'image/jpeg';
    const dataUrl = `data:${mimeType};base64,${imageBase64}`;

    res.json({
      success: true,
      data: {
        filename: req.file.originalname,
        mimetype: mimeType,
        size: req.file.size,
        base64Length: imageBase64.length,
        dataUrlPreview: dataUrl.substring(0, 100) + '...',
        message: 'Image data prepared for Flowise'
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * POST /api/translation/image
 * Upload an image and translate any text found in it using Flowise
 * Form-Data fields:
 * - file: image file (required)
 * - chatflowId: optional (defaults to env DEFAULT_TRANSLATION_CHATFLOW_ID)
 * - sourceLanguage: optional
 * - targetLanguage: optional
 * - prompt: optional custom prompt for image analysis
 */
router.post('/image', upload.single('file'), async (req, res) => {
  try {
    const {
      chatflowId = process.env.DEFAULT_TRANSLATION_CHATFLOW_ID,
      sourceLanguage = 'auto',
      targetLanguage = 'auto',
      prompt = 'Please analyze this image and translate any text you find from {sourceLanguage} to {targetLanguage}. If no text is found, describe what you see in the image.'
    } = req.body;

    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'No image file uploaded',
        message: 'Upload an image file in form-data with key "file"'
      });
    }

    if (!chatflowId) {
      return res.status(400).json({
        success: false,
        error: 'Missing chatflowId',
        message: 'Provide chatflowId or set DEFAULT_TRANSLATION_CHATFLOW_ID'
      });
    }

    // Prepare the prompt with language placeholders
    const processedPrompt = prompt
      .replace('{sourceLanguage}', sourceLanguage)
      .replace('{targetLanguage}', targetLanguage);

    // Create a focused prompt for image analysis that requests JSON response
    const visionPrompt = `Analyze this image and translate any text you find. Please respond with a JSON object in the following format:

{
  "originalText": "The original text found in the image",
  "translatedText": "The translated text",
  "detectedLanguage": "The language code of the original text",
  "description": "Brief description of what you see in the image"
}

INSTRUCTIONS:
- Look carefully for ALL text, signs, labels, documents, or written content
- If text is found, provide both original and translated versions
- If no text is found, set originalText to "No text found" and describe what you see
- Pay special attention to small or partially visible text
- Always respond with valid JSON format

${processedPrompt}

Please examine the image and respond with the JSON format above.`;

    // Send image as multipart form data to Flowise
    const result = await flowiseService.sendImageMessage(
      req.file.buffer,
      req.file.mimetype || 'image/jpeg',
      chatflowId,
      visionPrompt,
      {
        sourceLanguage,
        targetLanguage
      }
    );

    if (result.success) {
      const analysisText = result.data.answer || result.data.text || result.data.response;
      
      // Try to parse JSON response first
      let originalText = '';
      let translatedText = '';
      let detectedLanguage = sourceLanguage;
      let description = '';
      
      try {
        // Try to extract JSON from the response
        const jsonMatch = analysisText.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          const jsonResponse = JSON.parse(jsonMatch[0]);
          originalText = jsonResponse.originalText || '';
          translatedText = jsonResponse.translatedText || '';
          detectedLanguage = jsonResponse.detectedLanguage || sourceLanguage;
          description = jsonResponse.description || '';
        } else {
          throw new Error('No JSON found in response');
        }
      } catch (jsonError) {
        console.log('JSON parsing failed, falling back to text parsing:', jsonError.message);
        
        // Fallback: Try to extract original and translated text from the response
        // Look for patterns like "Original: ... Translated: ..." or similar
        const originalMatch = analysisText.match(/(?:original|原文|source)[:\s]+([^\n]+)/i);
        const translatedMatch = analysisText.match(/(?:translated|译文|translation)[:\s]+([^\n]+)/i);
        
        if (originalMatch && translatedMatch) {
          // If we found both original and translated text
          originalText = originalMatch[1].trim();
          translatedText = translatedMatch[1].trim();
        } else {
          // If no clear separation, try to split by common patterns
          const parts = analysisText.split(/\*\*English Translation:\*\*|\*\*Translation:\*\*|English Translation:/i);
          
          if (parts.length >= 2) {
            originalText = parts[0].trim();
            translatedText = parts[1].trim();
          } else {
            // Last resort: detect if it contains non-English text
            const hasNonEnglish = /[\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff\uac00-\ud7af]/.test(analysisText);
            
            if (hasNonEnglish) {
              // If it contains non-English characters, treat as original text
              originalText = analysisText;
              translatedText = 'Translation not available';
            } else {
              // If it's all English, treat as translation
              originalText = 'Text extracted from image';
              translatedText = analysisText;
            }
          }
        }
      }
      
      res.json({
        success: true,
        data: {
          originalImage: {
            filename: req.file.originalname,
            mimetype: req.file.mimetype || 'image/jpeg',
            size: req.file.size
          },
          originalText: originalText,
          translatedText: translatedText,
          detectedLanguage: detectedLanguage,
          description: description,
          fullAnalysis: analysisText,
          sourceLanguage,
          targetLanguage,
          timestamp: new Date().toISOString()
        },
        message: 'Image translation completed successfully'
      });
    } else {
      res.status(result.statusCode || 500).json({
        success: false,
        error: result.error,
        message: 'Failed to analyze and translate image'
      });
    }

  } catch (error) {
    console.error('Image translation error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during image translation',
      message: error.message
    });
  }
});

module.exports = router;

/**
 * POST /api/translation/audio
 * Accept audio file, transcribe with Google STT, then translate via Flowise
 * Form-Data fields:
 * - file: audio file (required)
 * - chatflowId: optional (defaults to env DEFAULT_TRANSLATION_CHATFLOW_ID)
 * - sourceLanguage: optional
 * - targetLanguage: optional
 * - languageCode: optional speech recognition language (default env GOOGLE_SPEECH_LANGUAGE_CODE)
 */
router.post('/audio', upload.single('file'), async (req, res) => {
  try {
    const chatflowId = req.body.chatflowId || process.env.DEFAULT_TRANSLATION_CHATFLOW_ID;
    const sourceLanguage = req.body.sourceLanguage || 'auto';
    const targetLanguage = req.body.targetLanguage || 'auto';
    const languageCode = req.body.languageCode; // for STT
    const languageCodes = req.body.languageCodes ? JSON.parse(req.body.languageCodes) : undefined; // for auto-detection

    if (!req.file) {
      return res.status(400).json({ success: false, error: 'No audio file uploaded', message: 'Upload an audio file in form-data with key "file"' });
    }
    if (!chatflowId) {
      return res.status(400).json({ success: false, error: 'Missing chatflowId', message: 'Provide chatflowId or set DEFAULT_TRANSLATION_CHATFLOW_ID' });
    }

    const mimeType = req.file.mimetype || 'audio/webm';
    const transcription = await sttService.transcribe(req.file.buffer, { mimeType, languageCode, languageCodes });
    if (!transcription.success) {
      return res.status(502).json({
        success: false,
        error: transcription.error || 'Speech transcription failed',
        details: transcription.raw || null,
        stt: { mimeType, languageCode: languageCode || process.env.GOOGLE_SPEECH_LANGUAGE_CODE },
        message: 'Speech transcription failed'
      });
    }

    const options = { sourceLanguage, targetLanguage };
    const result = await flowiseService.sendChatMessage(transcription.text, chatflowId, options);

    if (result.success) {
      return res.json({
        success: true,
        data: {
          originalText: transcription.text,
          translatedText: result.data.answer || result.data.text || result.data.response,
          sourceLanguage,
          targetLanguage,
          sttLanguageCode: languageCode || process.env.GOOGLE_SPEECH_LANGUAGE_CODE || 'en-US',
          timestamp: new Date().toISOString()
        },
        message: 'Audio translation completed successfully'
      });
    }

    return res.status(result.statusCode || 500).json({ success: false, error: result.error, message: 'Failed to translate transcribed text' });
  } catch (error) {
    console.error('Audio translation error:', error);
    res.status(500).json({ success: false, error: 'Internal server error during audio translation', message: error.message });
  }
});
