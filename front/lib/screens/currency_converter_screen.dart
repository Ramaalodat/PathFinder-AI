import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double _exchangeRate = 0.85;
  double _convertedAmount = 0.0;
  bool _isLoading = true;
  String _lastUpdated = '';
  Map<String, double> _liveRates = {};

  // Currency data with flags and names
  final List<Currency> _currencies = [
    // Major Currencies
    Currency(code: 'USD', name: 'US Dollar', flag: '🇺🇸'),
    Currency(code: 'EUR', name: 'Euro', flag: '🇪🇺'),
    Currency(code: 'GBP', name: 'British Pound', flag: '🇬🇧'),
    Currency(code: 'JPY', name: 'Japanese Yen', flag: '🇯🇵'),
    Currency(code: 'CNY', name: 'Chinese Yuan', flag: '🇨🇳'),
    Currency(code: 'CHF', name: 'Swiss Franc', flag: '🇨🇭'),
    Currency(code: 'CAD', name: 'Canadian Dollar', flag: '🇨🇦'),
    Currency(code: 'AUD', name: 'Australian Dollar', flag: '🇦🇺'),
    Currency(code: 'NZD', name: 'New Zealand Dollar', flag: '🇳🇿'),
    
    // Asian Currencies
    Currency(code: 'INR', name: 'Indian Rupee', flag: '🇮🇳'),
    Currency(code: 'KRW', name: 'South Korean Won', flag: '🇰🇷'),
    Currency(code: 'SGD', name: 'Singapore Dollar', flag: '🇸🇬'),
    Currency(code: 'HKD', name: 'Hong Kong Dollar', flag: '🇭🇰'),
    Currency(code: 'TWD', name: 'Taiwan Dollar', flag: '🇹🇼'),
    Currency(code: 'THB', name: 'Thai Baht', flag: '🇹🇭'),
    Currency(code: 'MYR', name: 'Malaysian Ringgit', flag: '🇲🇾'),
    Currency(code: 'IDR', name: 'Indonesian Rupiah', flag: '🇮🇩'),
    Currency(code: 'PHP', name: 'Philippine Peso', flag: '🇵🇭'),
    Currency(code: 'VND', name: 'Vietnamese Dong', flag: '🇻🇳'),
    
    // Middle East & Africa
    Currency(code: 'SAR', name: 'Saudi Riyal', flag: '🇸🇦'),
    Currency(code: 'AED', name: 'UAE Dirham', flag: '🇦🇪'),
    Currency(code: 'JOD', name: 'Jordanian Dinar', flag: '🇯🇴'),
    Currency(code: 'QAR', name: 'Qatari Riyal', flag: '🇶🇦'),
    Currency(code: 'KWD', name: 'Kuwaiti Dinar', flag: '🇰🇼'),
    Currency(code: 'BHD', name: 'Bahraini Dinar', flag: '🇧🇭'),
    Currency(code: 'OMR', name: 'Omani Rial', flag: '🇴🇲'),
    Currency(code: 'ILS', name: 'Israeli Shekel', flag: '🇮🇱'),
    Currency(code: 'TRY', name: 'Turkish Lira', flag: '🇹🇷'),
    Currency(code: 'EGP', name: 'Egyptian Pound', flag: '🇪🇬'),
    Currency(code: 'ZAR', name: 'South African Rand', flag: '🇿🇦'),
    Currency(code: 'NGN', name: 'Nigerian Naira', flag: '🇳🇬'),
    Currency(code: 'KES', name: 'Kenyan Shilling', flag: '🇰🇪'),
    
    // European Currencies
    Currency(code: 'NOK', name: 'Norwegian Krone', flag: '🇳🇴'),
    Currency(code: 'SEK', name: 'Swedish Krona', flag: '🇸🇪'),
    Currency(code: 'DKK', name: 'Danish Krone', flag: '🇩🇰'),
    Currency(code: 'PLN', name: 'Polish Zloty', flag: '🇵🇱'),
    Currency(code: 'CZK', name: 'Czech Koruna', flag: '🇨🇿'),
    Currency(code: 'HUF', name: 'Hungarian Forint', flag: '🇭🇺'),
    Currency(code: 'RON', name: 'Romanian Leu', flag: '🇷🇴'),
    Currency(code: 'BGN', name: 'Bulgarian Lev', flag: '🇧🇬'),
    Currency(code: 'HRK', name: 'Croatian Kuna', flag: '🇭🇷'),
    Currency(code: 'RUB', name: 'Russian Ruble', flag: '🇷🇺'),
    
    // Americas
    Currency(code: 'BRL', name: 'Brazilian Real', flag: '🇧🇷'),
    Currency(code: 'MXN', name: 'Mexican Peso', flag: '🇲🇽'),
    Currency(code: 'ARS', name: 'Argentine Peso', flag: '🇦🇷'),
    Currency(code: 'CLP', name: 'Chilean Peso', flag: '🇨🇱'),
    Currency(code: 'COP', name: 'Colombian Peso', flag: '🇨🇴'),
    Currency(code: 'PEN', name: 'Peruvian Sol', flag: '🇵🇪'),
    Currency(code: 'UYU', name: 'Uruguayan Peso', flag: '🇺🇾'),
    
  ];

  // API Configuration
  static const String _apiKey = 'cur_live_xB2hINulGFCnXj2X67BY6qBLlRPDD6FIVMdeXjCD';
  static const String _baseUrl = 'https://api.currencyapi.com/v3/latest';

  @override
  void initState() {
    super.initState();
    _amountController.text = '1000';
    _fetchLiveRates();
    _amountController.addListener(_convertCurrency);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveRates() async {
    try {
      setState(() => _isLoading = true);
      
      final url = Uri.parse('$_baseUrl?apikey=$_apiKey');
      print('🔄 Fetching live rates from: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Live rates fetched successfully');
        
        if (data['data'] != null) {
          final rates = data['data'] as Map<String, dynamic>;
          final Map<String, double> liveRates = {};
          
          rates.forEach((key, value) {
            if (value is Map && value['value'] != null) {
              liveRates[key] = (value['value'] as num).toDouble();
            }
          });
          
          setState(() {
            _liveRates = liveRates;
            _isLoading = false;
            _lastUpdated = data['meta']?['last_updated_at'] ?? 'Unknown';
            _convertCurrency();
          });
          
          print('🎯 Loaded ${liveRates.length} currency rates');
        } else {
          throw Exception('No data received from API');
        }
      } else {
        throw Exception('Failed to load rates: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching live rates: $e');
      setState(() {
        _isLoading = false;
        _showErrorSnackBar('Failed to load live rates. Using default rates.');
      });
      _convertCurrency(); // Use default rates
    }
  }

  void _convertCurrency() {
    if (_amountController.text.isEmpty) {
      setState(() => _convertedAmount = 0.0);
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    
    // Use live rates if available, otherwise fallback to default
    double fromRate = 1.0;
    double toRate = 1.0;
    
    if (_liveRates.isNotEmpty) {
      fromRate = _liveRates[_fromCurrency] ?? 1.0;
      toRate = _liveRates[_toCurrency] ?? 1.0;
    } else {
      // Fallback rates (USD based)
      final fallbackRates = {
        'USD': 1.0,
        'EUR': 0.857,
        'GBP': 0.750,
        'JPY': 149.88,
        'CNY': 7.135,
        'SAR': 3.748,
        'JOD': 0.71,
        'AED': 3.672,
        'CAD': 1.394,
        'AUD': 1.530,
        'CHF': 0.800,
        'INR': 88.71,
        'KRW': 1408.96,
        'SGD': 1.294,
        'HKD': 7.782,
        'TWD': 30.60,
        'THB': 32.18,
        'MYR': 4.216,
        'IDR': 16738.41,
        'PHP': 58.09,
        'VND': 26384.90,
        'QAR': 3.640,
        'KWD': 0.306,
        'BHD': 0.376,
        'OMR': 0.384,
        'ILS': 3.354,
        'TRY': 41.55,
        'EGP': 48.14,
        'ZAR': 17.43,
        'NGN': 1487.05,
        'KES': 129.33,
        'NOK': 10.03,
        'SEK': 9.462,
        'DKK': 6.400,
        'PLN': 3.660,
        'CZK': 20.83,
        'HUF': 335.49,
        'RON': 4.353,
        'BGN': 1.665,
        'HRK': 6.348,
        'RUB': 84.11,
        'BRL': 5.366,
        'MXN': 18.48,
        'ARS': 1337.57,
        'CLP': 960.52,
        'COP': 3903.70,
        'PEN': 3.504,
        'UYU': 39.94,
      };
      fromRate = fallbackRates[_fromCurrency] ?? 1.0;
      toRate = fallbackRates[_toCurrency] ?? 1.0;
    }

    setState(() {
      _exchangeRate = toRate / fromRate;
      _convertedAmount = amount * _exchangeRate;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convertCurrency();
  }

  void _showCurrencyPicker(bool isFromCurrency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCurrencyPicker(isFromCurrency),
    );
  }

  Widget _buildCurrencyPicker(bool isFromCurrency) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Select Currency',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _currencies.length,
              itemBuilder: (context, index) {
                final currency = _currencies[index];
                final isSelected = isFromCurrency
                    ? currency.code == _fromCurrency
                    : currency.code == _toCurrency;

                return ListTile(
                  leading: Text(
                    currency.flag,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    currency.code,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    currency.name,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppTheme.primaryOrange)
                      : null,
                  onTap: () {
                    setState(() {
                      if (isFromCurrency) {
                        _fromCurrency = currency.code;
                      } else {
                        _toCurrency = currency.code;
                      }
                    });
                    _convertCurrency();
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative background shapes (matching home screen)
          Positioned(
            top: -80,
            left: -60,
            child: _blob(180, AppTheme.primaryOrange.withOpacity(0.15)),
          ),
          Positioned(
            top: 120,
            right: -40,
            child: _blob(120, AppTheme.primaryBlue.withOpacity(0.12)),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: _blob(140, AppTheme.lightBlue.withOpacity(0.10)),
          ),
          Positioned(
            bottom: -60,
            right: -80,
            child: _blob(100, AppTheme.primaryOrange.withOpacity(0.08)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildExchangeRateCard(),
                  const SizedBox(height: 24),
                  _buildConverterCard(),
                  const SizedBox(height: 32),
                  _buildPopularRates(),
                  const SizedBox(height: 24),
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Currency Converter',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                _isLoading ? 'Loading live rates...' : 'Live exchange rates',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _isLoading ? AppTheme.primaryOrange : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.currency_exchange,
            color: AppTheme.primaryOrange,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeRateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.lightBlue.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Mid-market exchange rate',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showInfoDialog(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _fetchLiveRates,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1 $_fromCurrency = ${_exchangeRate.toStringAsFixed(4)} $_toCurrency',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if (_lastUpdated.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Last updated: ${_formatLastUpdated(_lastUpdated)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatLastUpdated(String lastUpdated) {
    try {
      final dateTime = DateTime.parse(lastUpdated);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildConverterCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // From Currency
          _buildCurrencyField(
            label: 'Amount',
            controller: _amountController,
            currency: _fromCurrency,
            isFrom: true,
          ),
          const SizedBox(height: 16),

          // Swap Button
          Center(
            child: GestureDetector(
              onTap: _swapCurrencies,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.swap_vert,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // To Currency
          _buildCurrencyField(
            label: 'Converted to',
            amount: _convertedAmount.toStringAsFixed(2),
            currency: _toCurrency,
            isFrom: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyField({
    required String label,
    TextEditingController? controller,
    String? amount,
    required String currency,
    required bool isFrom,
  }) {
    final currencyData = _currencies.firstWhere((c) => c.code == currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: controller != null
                    ? TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : Text(
                        amount ?? '0.00',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
              ),
              GestureDetector(
                onTap: () => _showCurrencyPicker(isFrom),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyData.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currencyData.code,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPopularRates() {
    final popularCurrencies = ['EUR', 'GBP', 'JPY', 'CNY', 'SAR', 'AED', 'INR', 'KRW'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Rates',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...popularCurrencies.map((code) {
          if (code == _fromCurrency) return const SizedBox.shrink();

          final currency = _currencies.firstWhere((c) => c.code == code);
          
          // Calculate rate using live data or fallback
          double rate = 1.0;
          if (_liveRates.isNotEmpty) {
            final fromRate = _liveRates[_fromCurrency] ?? 1.0;
            final toRate = _liveRates[code] ?? 1.0;
            rate = toRate / fromRate;
          } else {
            // Fallback calculation
            final fallbackRates = {
              'USD': 1.0,
              'EUR': 0.857,
              'GBP': 0.750,
              'JPY': 149.88,
              'CNY': 7.135,
              'SAR': 3.748,
              'AED': 3.672,
              'INR': 88.71,
              'KRW': 1408.96,
            };
            final fromRate = fallbackRates[_fromCurrency] ?? 1.0;
            final toRate = fallbackRates[code] ?? 1.0;
            rate = toRate / fromRate;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(currency.flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currency.code,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        currency.name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${rate.toStringAsFixed(4)}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightBlue.withOpacity(0.1),
            AppTheme.primaryOrange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppTheme.lightBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live rates from CurrencyAPI',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rates update in real-time. For informational purposes only.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mid-market Rate',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'The mid-market rate is the exchange rate between two currencies at the midpoint between the buy and sell rates. It\'s often used as a reference rate.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.inter(
                color: AppTheme.primaryOrange,
                fontWeight: FontWeight.w600,
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

class Currency {
  final String code;
  final String name;
  final String flag;

  Currency({
    required this.code,
    required this.name,
    required this.flag,
  });
}
