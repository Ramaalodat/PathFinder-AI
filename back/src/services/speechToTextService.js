const axios = require('axios');
const { GoogleAuth } = require('google-auth-library');

/**
 * Simple Google Speech-to-Text service using REST API.
 * Expects raw audio Buffer; caller provides mimeType and optional languageCode.
 */
class SpeechToTextService {
  constructor() {
    this.apiKey = process.env.GOOGLE_SPEECH_API_KEY; // optional when using OAuth
    this.defaultLanguageCode = process.env.GOOGLE_SPEECH_LANGUAGE_CODE || 'en-US';
    this.endpoint = 'https://speech.googleapis.com/v1/speech:recognize';

    // Use OAuth only if ADC is configured; otherwise fall back to API key
    this.useAuth = !!process.env.GOOGLE_APPLICATION_CREDENTIALS;
    this.auth = this.useAuth
      ? new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/cloud-platform'] })
      : null;
  }

  /**
   * Transcribe audio buffer
   * @param {Buffer} audioBuffer
   * @param {Object} options
   * @param {string} options.mimeType - e.g., 'audio/webm', 'audio/mpeg', 'audio/wav'
   * @param {string} [options.languageCode]
   * @returns {Promise<{ success: boolean, text?: string, raw?: any, error?: string }>} 
   */
   async transcribe(audioBuffer, options = {}) {
     try {
       if (!audioBuffer || !Buffer.isBuffer(audioBuffer)) {
         return { success: false, error: 'Invalid audio buffer' };
       }

       const mimeType = options.mimeType || 'audio/webm';
       const languageCode = options.languageCode || this.defaultLanguageCode;
       const customLanguageCodes = options.languageCodes;

      const audioContent = audioBuffer.toString('base64');

      const isWebmOrOgg = /webm|ogg|opus/i.test(mimeType);
      
      // Use automatic language detection with common languages or custom list
      const alternativeLanguageCodes = customLanguageCodes || [
        'en-US', 'zh-CN', 'zh-TW', 'es-ES', 'fr-FR', 'de-DE', 'ja-JP', 'ko-KR', 
        'ar-SA', 'hi-IN', 'th-TH', 'vi-VN', 'it-IT', 'pt-BR', 'ru-RU', 'nl-NL'
      ];
      
      const requestBody = {
        config: {
          encoding: this._encodingFromMime(mimeType),
          // Let API auto-detect sample rate; avoid mismatches
          sampleRateHertz: undefined,
          languageCode: languageCode || 'en-US', // fallback language
          alternativeLanguageCodes: alternativeLanguageCodes,
          enableAutomaticPunctuation: true,
          model: 'default',
          enableSpokenPunctuation: true,
          enableSpokenEmojis: false,
          ...(isWebmOrOgg ? { audioChannelCount: 2, enableSeparateRecognitionPerChannel: false } : {})
        },
        audio: {
          content: audioContent
        }
      };

      let url = this.endpoint;
      const headers = { 'Content-Type': 'application/json' };

      if (this.useAuth) {
        // Try OAuth first when ADC is configured
        try {
          const client = await this.auth.getClient();
          const accessToken = await client.getAccessToken();
          if (accessToken?.token) headers.Authorization = `Bearer ${accessToken.token}`;
        } catch (authError) {
          console.warn('Google STT OAuth not available, falling back to API key if set. Details:', authError.message);
        }
      }

      // If no Authorization header set, try API key mode
      if (!headers.Authorization) {
        if (!this.apiKey) {
          return { success: false, error: 'No Google auth available. Set GOOGLE_APPLICATION_CREDENTIALS or GOOGLE_SPEECH_API_KEY.' };
        }
        url = `${this.endpoint}?key=${this.apiKey}`;
      }

      const response = await axios.post(url, requestBody, { headers, timeout: 60000 });

      const results = response.data.results || [];
      const transcript = results
        .map(r => r.alternatives?.[0]?.transcript)
        .filter(Boolean)
        .join(' ')
        .trim();

      if (!transcript) {
        return { success: false, error: 'No transcription result from Google STT', raw: response.data };
      }

      return { success: true, text: transcript, raw: response.data };
    } catch (error) {
      const details = error.response?.data || error.message;
      console.error('Google STT Error:', details);
      return { success: false, error: error.response?.data?.error?.message || error.message };
    }
  }

  _encodingFromMime(mimeType) {
    // Map common mime types to Google encodings; undefined lets Google auto-detect
    if (!mimeType) return undefined;
    const lower = String(mimeType).toLowerCase();
    if (lower.includes('wav') || lower.includes('x-wav')) return 'LINEAR16';
    if (lower.includes('flac')) return 'FLAC';
    if (lower.includes('amr-wb')) return 'AMR_WB';
    if (lower.includes('amr')) return 'AMR';
    // Distinguish containers: WebM -> WEBM_OPUS, OGG -> OGG_OPUS
    if (lower.includes('webm')) return 'WEBM_OPUS';
    if (lower.includes('ogg') || lower.includes('opus')) return 'OGG_OPUS';
    if (lower.includes('mp3') || lower.includes('mpeg')) return 'MP3';
    return undefined; // let API auto-detect
  }
}

module.exports = SpeechToTextService;


