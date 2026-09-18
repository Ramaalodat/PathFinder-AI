import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/price_advisor_service.dart';
import '../config/api_config.dart';
import '../utils/text_formatter.dart';
import '../theme/app_theme.dart';

class PriceAdvisorScreen extends StatefulWidget {
  const PriceAdvisorScreen({super.key});

  @override
  State<PriceAdvisorScreen> createState() => _PriceAdvisorScreenState();
}

class _PriceAdvisorScreenState extends State<PriceAdvisorScreen> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  bool _isLoading = false;
  String? _priceAdvice;
  String? _errorMessage;

  @override
  void dispose() {
    _cityController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _checkPrice() async {
    if (_cityController.text.trim().isEmpty || 
        _itemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both city and item'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _priceAdvice = null;
    });

    try {
      final result = await PriceAdvisorService.getSafetyAdvice(
        query: 'What are typical prices for ${_itemController.text.trim()} in ${_cityController.text.trim()}? Please provide price ranges and advice on fair pricing.',
        location: _cityController.text.trim(),
        chatflowId: ApiConfig.defaultPriceAdvisorChatflowId,
        adviceType: 'price',
      );

      setState(() {
        _isLoading = false;
        if (result['success']) {
          _priceAdvice = result['data']['data']['advice'] ?? 'No advice available';
        } else {
          _errorMessage = result['error'] ?? 'Failed to get price advice';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final Color accentOrange = AppTheme.primaryOrange;
    final Color accentBlue = const Color(0xFF1C2F69);

    return Scaffold(
      backgroundColor: Colors.white, // match homepage scaffold
      appBar: AppBar(
        backgroundColor: accentBlue,
        title: const Text('Price Advisor'),
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // decorative blobs to mirror homepage style
          Positioned(
            top: -80,
            left: -60,
            child: _blob(180, accentOrange.withOpacity(0.15)),
          ),
          Positioned(
            top: 120,
            right: -40,
            child: _blob(120, accentBlue.withOpacity(0.12)),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: _blob(140, AppTheme.lightBlue.withOpacity(0.10)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Price Advisor Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            'Price Advisor',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter a city and item to get price advice and typical market rates.',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // City Input
                          Text(
                            'City',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              hintText: 'Enter city name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: accentOrange, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Item Input
                          Text(
                            'Item',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _itemController,
                            decoration: InputDecoration(
                              hintText: 'Enter item name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: accentOrange, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Don't know the name section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.lightBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.lightBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.help_outline,
                                      color: AppTheme.primaryBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Don't know the name of the item?",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Take a picture of it or scan the barcode",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // TODO: Implement camera functionality
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Camera feature coming soon!'),
                                          backgroundColor: AppTheme.primaryOrange,
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      color: AppTheme.primaryBlue,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Take Picture / Scan Barcode',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      side: BorderSide(
                                        color: AppTheme.primaryBlue.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Check Price Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _checkPrice,
                              icon: _isLoading 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.search, color: Colors.white),
                              label: Text(
                                _isLoading ? 'Checking...' : 'Check Price',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isLoading ? Colors.grey : accentBlue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Price Advice Display Section
                  if (_priceAdvice != null || _errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price Advice',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_priceAdvice != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primaryOrange!),
                                ),
                                child: TextFormatter.createFormattedText(
                                  _priceAdvice!,
                                  textColor: AppTheme.primaryOrange!,
                                  fontSize: 14,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.red[800],
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 6,
          ),
        ],
      ),
    );
  }
}