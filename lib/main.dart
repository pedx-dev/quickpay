import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

// Add this at the top level for global dark mode state
final ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(false);

void main() {
  runApp(const WalletApp());
}

class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDarkMode, child) {
        return CupertinoApp(
          title: 'QuickPay Wallet',
          debugShowCheckedModeBanner: false,
          theme: CupertinoThemeData(
            brightness: isDarkMode ? Brightness.dark : Brightness.light,
            primaryColor: CupertinoColors.systemPurple,
            scaffoldBackgroundColor: isDarkMode
                ? CupertinoColors.darkBackgroundGray
                : CupertinoColors.systemGroupedBackground,
            barBackgroundColor: isDarkMode
                ? CupertinoColors.darkBackgroundGray
                : CupertinoColors.systemGroupedBackground,
            textTheme: CupertinoTextThemeData(
              navTitleTextStyle: TextStyle(
                color: isDarkMode ? CupertinoColors.white : CupertinoColors.label,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              textStyle: TextStyle(
                color: isDarkMode ? CupertinoColors.white : CupertinoColors.label,
              ),
            ),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // ============================================
  // IMPORTANT: Replace with your actual Xendit Secret Key
  // ============================================
  final String _xenditSecretKey = "xnd_development_z8cNO5PbZB5MRi7yfFxamY53fHyPp1152XyJsQ96OgwzoArEItoogXXeFKHXJGd";

  // App State
  double _walletBalance = 1000.00;
  bool _isLoading = false;
  bool _showWebView = false;
  List<Map<String, dynamic>> _transactions = [];
  String? _currentInvoiceId;
  String? _paymentUrl;
  late StreamController<Map<String, dynamic>> _paymentSuccessController;

  // Mobile load purchase variables
  String _mobileNumber = '';
  String _selectedNetwork = '';
  double _selectedAmount = 0.0;

  // Bottom Navigation
  int _selectedIndex = 0;

  // Settings states
  bool _notificationsEnabled = true;
  String _userPIN = "123456";

  // Mobile network providers
  final List<Map<String, dynamic>> _mobileNetworks = [
    {
      'name': 'Smart',
      'logo': 'S',
      'color': CupertinoColors.systemRed,
      'icon': CupertinoIcons.bolt_fill,
      'prefixes': ['0819', '0908', '0918', '0919', '0920', '0921', '0930', '0931', '0940', '0946', '0947', '0948', '0949', '0951', '0970', '0980', '0981', '0989', '0990', '0991', '0998', '0999'],
    },
    {
      'name': 'TNT',
      'logo': 'T',
      'color': CupertinoColors.systemOrange,
      'icon': CupertinoIcons.flame_fill,
      'prefixes': ['0905', '0906', '0915', '0916', '0917', '0925', '0926', '0927', '0935', '0936', '0937', '0945', '0950', '0955', '0956', '0960', '0961', '0965', '0966', '0967', '0975', '0976', '0977', '0978', '0979'],
    },
    {
      'name': 'Globe',
      'logo': 'G',
      'color': CupertinoColors.systemGreen,
      'icon': CupertinoIcons.globe,
      'prefixes': ['0817', '0905', '0906', '0915', '0916', '0917', '0926', '0927', '0935', '0936', '0937', '0945', '0953', '0954', '0955', '0956', '0965', '0966', '0967', '0975', '0976', '0977', '0978', '0979', '0995', '0996', '0997'],
    },
    {
      'name': 'TM',
      'logo': 'TM',
      'color': CupertinoColors.systemBlue,
      'icon': CupertinoIcons.antenna_radiowaves_left_right,
      'prefixes': ['0895', '0896', '0897', '0898', '0904', '0905', '0906', '0915', '0916', '0926', '0927', '0935', '0936', '0937', '0945', '0953', '0954', '0956', '0965', '0966', '0967', '0975', '0976', '0977', '0978', '0979'],
    },
    {
      'name': 'DITO',
      'logo': 'D',
      'color': CupertinoColors.systemPurple,
      'icon': CupertinoIcons.rocket_fill,
      'prefixes': ['0891', '0892', '0893', '0894', '0895', '0896', '0897', '0898', '0991', '0992', '0993', '0994'],
    },
  ];

  // Load amounts with their actual denominations
  final List<Map<String, dynamic>> _loadAmounts = [
    {'amount': 10, 'label': '₱10'},
    {'amount': 15, 'label': '₱15'},
    {'amount': 20, 'label': '₱20'},
    {'amount': 25, 'label': '₱25'},
    {'amount': 30, 'label': '₱30'},
    {'amount': 50, 'label': '₱50'},
    {'amount': 100, 'label': '₱100'},
    {'amount': 150, 'label': '₱150'},
    {'amount': 200, 'label': '₱200'},
    {'amount': 300, 'label': '₱300'},
    {'amount': 500, 'label': '₱500'},
    {'amount': 1000, 'label': '₱1000'},
  ];

  // Quick top-up amounts for wallet
  final List<Map<String, dynamic>> _topUpAmounts = [
    {'amount': 100, 'label': '₱100'},
    {'amount': 300, 'label': '₱300'},
    {'amount': 500, 'label': '₱500'},
    {'amount': 1000, 'label': '₱1,000'},
    {'amount': 2000, 'label': '₱2,000'},
    {'amount': 5000, 'label': '₱5,000'},
  ];

  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _customLoadAmountController = TextEditingController();
  final TextEditingController _customTopUpAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentSuccessController = StreamController<Map<String, dynamic>>.broadcast();
    _loadInitialData();
    _setupPaymentListener();
  }

  void _setupPaymentListener() {
    _paymentSuccessController.stream.listen((paymentData) {
      _handleSuccessfulTopUp(paymentData);
    });
  }

  void _loadInitialData() {
    _transactions = [
      {
        'id': '1',
        'title': 'Load to 09171234567',
        'subtitle': 'Smart',
        'amount': 50.00,
        'date': 'Today',
        'type': 'debit',
        'status': 'completed',
        'service': 'load'
      },
      {
        'id': '2',
        'title': 'Wallet Top-up',
        'subtitle': 'Credit Card',
        'amount': 500.00,
        'date': 'Yesterday',
        'type': 'credit',
        'status': 'completed',
        'service': 'topup'
      },
      {
        'id': '3',
        'title': 'Load to 09987654321',
        'subtitle': 'Globe',
        'amount': 100.00,
        'date': 'Oct 28',
        'type': 'debit',
        'status': 'completed',
        'service': 'load'
      },
      {
        'id': '4',
        'title': 'Sent to Maria Santos',
        'subtitle': 'Money Transfer',
        'amount': 250.00,
        'date': 'Oct 27',
        'type': 'debit',
        'status': 'completed',
        'service': 'transfer'
      },
      {
        'id': '5',
        'title': 'Electric Bill Payment',
        'subtitle': 'Meralco',
        'amount': 1200.00,
        'date': 'Oct 26',
        'type': 'debit',
        'status': 'completed',
        'service': 'bills'
      },
    ];
  }

  @override
  void dispose() {
    _mobileNumberController.dispose();
    _customLoadAmountController.dispose();
    _customTopUpAmountController.dispose();
    _paymentSuccessController.close();
    super.dispose();
  }

  // ============================================
  // XENDIT API FUNCTIONS (FOR TOP-UP ONLY)
  // ============================================

  Future<Map<String, dynamic>> _createXenditInvoiceForTopUp(double amount) async {
    const String url = "https://api.xendit.co/v2/invoices";

    String basicAuth = base64Encode(utf8.encode('$_xenditSecretKey:'));

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic $basicAuth',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'external_id': 'topup_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'description': 'Wallet Top-up - ₱${amount.toStringAsFixed(2)}',
        'currency': 'PHP',
        'customer': {
          'given_names': 'QuickPay User',
          'email': 'user@quickpay.com',
        },
        'success_redirect_url': 'https://quickpay.com/success',
        'failure_redirect_url': 'https://quickpay.com/failed',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create invoice. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> _checkPaymentStatus(String invoiceId) async {
    String basicAuth = base64Encode(utf8.encode('$_xenditSecretKey:'));

    final response = await http.get(
      Uri.parse('https://api.xendit.co/v2/invoices/$invoiceId'),
      headers: {'Authorization': 'Basic $basicAuth'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to check status');
    }
  }

  // ============================================
  // WALLET TOP-UP FUNCTIONS (USES XENDIT)
  // ============================================

  Future<void> _handleTopUp(double amount) async {
    if (amount < 100) {
      _showErrorDialog('Minimum top-up is ₱100');
      return;
    }

    if (amount > 50000) {
      _showErrorDialog('Maximum top-up is ₱50,000');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final invoice = await _createXenditInvoiceForTopUp(amount);
      final invoiceUrl = invoice['invoice_url'];
      final invoiceId = invoice['id'];

      _currentInvoiceId = invoiceId;

      setState(() {
        _paymentUrl = invoiceUrl;
        _showWebView = true;
        _isLoading = false;
      });

      _startPaymentPolling(invoiceId, amount);

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Payment setup failed. Please try again.');
    }
  }

  void _startPaymentPolling(String invoiceId, double amount) {
    int retryCount = 0;
    const int maxRetries = 60;

    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (retryCount >= maxRetries) {
        timer.cancel();
        _showTimeoutDialog(amount);
        return;
      }

      retryCount++;

      try {
        final data = await _checkPaymentStatus(invoiceId);
        final status = data['status']?.toString().toUpperCase();

        if (status == 'PAID' || status == 'SETTLED') {
          timer.cancel();
          _paymentSuccessController.add({
            'amount': amount,
            'type': 'topup',
          });

        } else if (status == 'EXPIRED' || status == 'FAILED') {
          timer.cancel();
          if (mounted) {
            _showErrorDialog('Payment $status. Please try again.');
            setState(() {
              _showWebView = false;
            });
          }
        }
      } catch (e) {
        // Continue polling on error
      }
    });
  }

  void _handleSuccessfulTopUp(Map<String, dynamic> paymentData) {
    double amount = paymentData['amount'];

    double newBalance = _walletBalance + amount;

    final newTransaction = {
      'id': _currentInvoiceId ?? '${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Wallet Top-up',
      'subtitle': 'Xendit',
      'amount': amount,
      'date': 'Just now',
      'type': 'credit',
      'status': 'completed',
      'service': 'topup'
    };

    setState(() {
      _walletBalance = newBalance;
      _showWebView = false;
      _transactions.insert(0, newTransaction);
      _customTopUpAmountController.clear();
    });

    _showSuccessDialog(
      'Top-up Successful!',
      '₱${amount.toStringAsFixed(2)} has been added to your wallet.\n\nNew Balance: ₱${_walletBalance.toStringAsFixed(2)}',
      CupertinoIcons.checkmark_alt_circle,
      CupertinoColors.systemGreen,
    );
  }

  // ============================================
  // LOAD PURCHASE FUNCTIONS (USES WALLET BALANCE)
  // ============================================

  String? _detectNetwork(String mobileNumber) {
    if (mobileNumber.isEmpty) return null;

    String cleanNumber = mobileNumber.startsWith('0') ? mobileNumber.substring(1) : mobileNumber;
    if (cleanNumber.length < 4) return null;

    String prefix = cleanNumber.substring(0, 4);

    for (var network in _mobileNetworks) {
      if (network['prefixes'].contains(prefix)) {
        return network['name'];
      }
    }

    return null;
  }

  Future<void> _buyLoad(double amount) async {
    if (_mobileNumber.isEmpty) {
      _showErrorDialog('Please enter mobile number');
      return;
    }

    if (_mobileNumber.length < 10) {
      _showErrorDialog('Please enter a valid mobile number');
      return;
    }

    if (_selectedNetwork.isEmpty) {
      _showErrorDialog('Please select a network');
      return;
    }

    if (amount < 10) {
      _showErrorDialog('Minimum load amount is ₱10');
      return;
    }

    if (amount > 1000) {
      _showErrorDialog('Maximum load amount is ₱1,000');
      return;
    }

    if (_walletBalance < amount) {
      _showInsufficientBalanceDialog(amount);
      return;
    }

    _verifyPINForTransaction(() => _processLoadPurchase(amount));
  }

  void _processLoadPurchase(double amount) {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      double newBalance = _walletBalance - amount;

      final newTransaction = {
        'id': 'load_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Load to $_mobileNumber',
        'subtitle': _selectedNetwork,
        'amount': amount,
        'date': 'Just now',
        'type': 'debit',
        'status': 'completed',
        'service': 'load'
      };

      setState(() {
        _walletBalance = newBalance;
        _isLoading = false;
        _transactions.insert(0, newTransaction);

        _mobileNumberController.clear();
        _customLoadAmountController.clear();
        _mobileNumber = '';
        _selectedNetwork = '';
        _selectedAmount = 0;
      });

      _showSuccessDialog(
        'Load Sent Successfully!',
        '₱${amount.toStringAsFixed(2)} has been sent to $_mobileNumber ($_selectedNetwork).\n\nLoad will be credited within 5-10 minutes.\n\nNew Balance: ₱${_walletBalance.toStringAsFixed(2)}',
        CupertinoIcons.checkmark_alt_circle,
        CupertinoColors.systemGreen,
      );
    });
  }

  // ============================================
  // SECURITY FUNCTIONS
  // ============================================

  void _verifyPINForTransaction(Function() onSuccess) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Enter PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter your 6-digit PIN to continue'),
            const SizedBox(height: 16),
            CupertinoTextField(
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 10),
              placeholder: '••••••',
              onChanged: (value) {
                if (value.length == 6) {
                  if (value == _userPIN) {
                    Navigator.pop(context);
                    onSuccess();
                  } else {
                    _showErrorDialog('Incorrect PIN');
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // OTHER FUNCTIONALITIES
  // ============================================

  void _showTransactionHistory() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Icon(CupertinoIcons.xmark, size: 24, color: CupertinoTheme.of(context).textTheme.textStyle.color),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _transactions.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.doc_text, size: 60, color: CupertinoColors.systemGrey),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
                  : CupertinoScrollbar(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionItem(_transactions[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCodeScanner() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Scan QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              color: CupertinoColors.systemGrey6,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.qrcode_viewfinder, size: 60, color: CupertinoColors.systemGrey),
                    SizedBox(height: 16),
                    Text('QR Code Scanner'),
                    Text('(Simulated)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Point your camera at a QR code to scan'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessDialog(
                'Payment Successful',
                'You have successfully paid ₱150.00 to Maria\'s Store.',
                CupertinoIcons.checkmark_alt_circle,
                CupertinoColors.systemGreen,
              );
            },
            child: const Text('Simulate Payment'),
          ),
        ],
      ),
    );
  }

  void _showSendMoneyScreen() {
    TextEditingController recipientController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Send Money',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Icon(CupertinoIcons.xmark, size: 24, color: CupertinoTheme.of(context).textTheme.textStyle.color),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CupertinoTextField(
                    controller: recipientController,
                    keyboardType: TextInputType.phone,
                    placeholder: 'Recipient Mobile Number',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(CupertinoIcons.person, size: 20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    placeholder: 'Amount',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(CupertinoIcons.money_dollar, size: 20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: () {
                        final recipient = recipientController.text.trim();
                        final amount = double.tryParse(amountController.text.trim());

                        if (recipient.isEmpty) {
                          _showErrorDialog('Please enter recipient number');
                          return;
                        }

                        if (amount == null || amount <= 0) {
                          _showErrorDialog('Please enter a valid amount');
                          return;
                        }

                        if (amount > _walletBalance) {
                          _showInsufficientBalanceDialog(amount);
                          return;
                        }

                        Navigator.pop(context);
                        _verifyPINForTransaction(() {
                          setState(() {
                            _walletBalance -= amount;
                            _transactions.insert(0, {
                              'id': 'transfer_${DateTime.now().millisecondsSinceEpoch}',
                              'title': 'Sent to $recipient',
                              'subtitle': 'Money Transfer',
                              'amount': amount,
                              'date': 'Just now',
                              'type': 'debit',
                              'status': 'completed',
                              'service': 'transfer'
                            });
                          });

                          _showSuccessDialog(
                            'Money Sent!',
                            '₱${amount.toStringAsFixed(2)} has been sent to $recipient.\n\nNew Balance: ₱${_walletBalance.toStringAsFixed(2)}',
                            CupertinoIcons.checkmark_alt_circle,
                            CupertinoColors.systemGreen,
                          );
                        });
                      },
                      child: const Text('Send Money'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBillsPaymentScreen() {
    List<Map<String, dynamic>> billers = [
      {'name': 'Meralco', 'icon': CupertinoIcons.bolt_fill, 'color': CupertinoColors.systemBlue},
      {'name': 'Maynilad', 'icon': CupertinoIcons.drop_fill, 'color': CupertinoColors.systemBlue},
      {'name': 'PLDT', 'icon': CupertinoIcons.phone_fill, 'color': CupertinoColors.systemRed},
      {'name': 'Converge', 'icon': CupertinoIcons.wifi, 'color': CupertinoColors.systemOrange},
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pay Bills',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Icon(CupertinoIcons.xmark, size: 24, color: CupertinoTheme.of(context).textTheme.textStyle.color),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select a biller to pay:', style: TextStyle(color: CupertinoTheme.of(context).textTheme.textStyle.color)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                ),
                itemCount: billers.length,
                itemBuilder: (context, index) {
                  final biller = billers[index];
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.pop(context);
                      _showBillPaymentForm(biller['name']);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CupertinoColors.separator),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(biller['icon'], size: 40, color: biller['color']),
                          const SizedBox(height: 8),
                          Text(biller['name'], style: TextStyle(color: CupertinoTheme.of(context).textTheme.textStyle.color)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBillPaymentForm(String biller) {
    TextEditingController accountController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Pay $biller Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoTextField(
              controller: accountController,
              placeholder: 'Account Number',
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              placeholder: 'Amount',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('₱'),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final account = accountController.text.trim();
              final amount = double.tryParse(amountController.text.trim());

              if (account.isEmpty) {
                _showErrorDialog('Please enter account number');
                return;
              }

              if (amount == null || amount <= 0) {
                _showErrorDialog('Please enter a valid amount');
                return;
              }

              if (amount > _walletBalance) {
                _showInsufficientBalanceDialog(amount);
                return;
              }

              Navigator.pop(context);
              _verifyPINForTransaction(() {
                setState(() {
                  _walletBalance -= amount;
                  _transactions.insert(0, {
                    'id': 'bill_${DateTime.now().millisecondsSinceEpoch}',
                    'title': '$biller Bill Payment',
                    'subtitle': 'Account: $account',
                    'amount': amount,
                    'date': 'Just now',
                    'type': 'debit',
                    'status': 'completed',
                    'service': 'bills'
                  });
                });

                _showSuccessDialog(
                  'Bill Paid!',
                  'Your $biller bill of ₱${amount.toStringAsFixed(2)} has been paid.\n\nNew Balance: ₱${_walletBalance.toStringAsFixed(2)}',
                  CupertinoIcons.checkmark_alt_circle,
                  CupertinoColors.systemGreen,
                );
              });
            },
            child: const Text('Pay Bill'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI HELPER FUNCTIONS
  // ============================================

  void _showSuccessDialog(String title, String message, IconData icon, Color color) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_circle, color: CupertinoColors.systemRed, size: 30),
            SizedBox(width: 10),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientBalanceDialog(double amount) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.systemOrange, size: 30),
            SizedBox(width: 10),
            Text('Insufficient Balance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your wallet balance is insufficient for this purchase.'),
            const SizedBox(height: 15),
            Text(
              'Required: ₱${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Current: ₱${_walletBalance.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15),
            const Text(
              'Please top-up your wallet first.',
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 2; // Switch to Top-up screen
              });
            },
            child: const Text('Top-up Now'),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog(double amount) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          children: [
            Icon(CupertinoIcons.timer, color: CupertinoColors.systemOrange, size: 30),
            SizedBox(width: 10),
            Text('Payment Taking Too Long'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your payment is still being processed.'),
            SizedBox(height: 10),
            Text(
              'Please check your email or return to the dashboard.',
              style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showWebView = false;
              });
            },
            child: const Text('Return to Dashboard'),
          ),
        ],
      ),
    );
  }

  Color _getNetworkColor(String network) {
    for (var net in _mobileNetworks) {
      if (net['name'] == network) {
        return net['color'];
      }
    }
    return CupertinoColors.systemGrey;
  }

  IconData _getNetworkIcon(String network) {
    for (var net in _mobileNetworks) {
      if (net['name'] == network) {
        return net['icon'];
      }
    }
    return CupertinoIcons.phone;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ============================================
  // UI WIDGETS
  // ============================================

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final bool isCredit = transaction['type'] == 'credit';
    final Color color = isCredit ? CupertinoColors.systemGreen : CupertinoColors.systemRed;
    final IconData icon = transaction['service'] == 'load'
        ? CupertinoIcons.phone
        : transaction['service'] == 'transfer'
        ? CupertinoIcons.paperplane_fill
        : transaction['service'] == 'bills'
        ? CupertinoIcons.doc_text
        : CupertinoIcons.creditcard_fill;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: CupertinoColors.systemGrey5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction['subtitle'] ?? '',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction['date'],
                  style: TextStyle(
                    color: CupertinoColors.tertiaryLabel,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+₱' : '-₱'}${transaction['amount'].toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: transaction['status'] == 'completed'
                      ? CupertinoColors.systemGreen.withOpacity(0.1)
                      : CupertinoColors.systemOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  transaction['status'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: transaction['status'] == 'completed'
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemOrange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6A11CB).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.creditcard_fill, color: CupertinoColors.white, size: 28),
              const SizedBox(width: 10),
              const Text(
                'WALLET BALANCE',
                style: TextStyle(color: CupertinoColors.white, fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _selectedIndex = 3; // Go to Settings
                  });
                },
                child: const Icon(CupertinoIcons.ellipsis, color: CupertinoColors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₱${_walletBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionButton(
                icon: CupertinoIcons.qrcode_viewfinder,
                label: 'Scan & Pay',
                onTap: _showQRCodeScanner,
              ),
              _buildQuickActionButton(
                icon: CupertinoIcons.paperplane_fill,
                label: 'Send Money',
                onTap: _showSendMoneyScreen,
              ),
              _buildQuickActionButton(
                icon: CupertinoIcons.doc_text,
                label: 'Pay Bills',
                onTap: _showBillsPaymentScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: CupertinoColors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Icon(icon, color: CupertinoColors.white, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen() {
    return CupertinoScrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    onPressed: _showTransactionHistory,
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: CupertinoColors.systemBlue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CupertinoColors.systemGrey5),
                ),
                child: _transactions.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.doc_text, size: 64, color: CupertinoColors.systemGrey3),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your transactions will appear here',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey2,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _transactions.take(3).map(_buildTransactionItem).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CupertinoColors.systemGrey5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Services',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: CupertinoTheme.of(context).textTheme.textStyle.color,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildServiceButton(
                          icon: CupertinoIcons.phone,
                          label: 'Buy Load',
                          color: CupertinoColors.systemPurple,
                          onTap: () {
                            setState(() {
                              _selectedIndex = 1; // Go to Buy Load screen
                            });
                          },
                        ),
                        _buildServiceButton(
                          icon: CupertinoIcons.creditcard_fill,
                          label: 'Top-up',
                          color: CupertinoColors.systemGreen,
                          onTap: () {
                            setState(() {
                              _selectedIndex = 2; // Go to Top-up screen
                            });
                          },
                        ),
                        _buildServiceButton(
                          icon: CupertinoIcons.clock,
                          label: 'History',
                          color: CupertinoColors.systemOrange,
                          onTap: _showTransactionHistory,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyLoadScreen() {
    return CupertinoScrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            CupertinoNavigationBar(
              middle: const Text('Buy Mobile Load'),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0; // Go back to home
                  });
                },
                child: const Icon(CupertinoIcons.arrow_left),
              ),
            ),
            const SizedBox(height: 20),

            // Mobile Number Input
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CupertinoColors.systemGrey5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mobile Number',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _mobileNumberController,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    onChanged: (value) {
                      setState(() {
                        _mobileNumber = value;
                        if (value.length >= 4) {
                          String? detectedNetwork = _detectNetwork(value);
                          if (detectedNetwork != null && _selectedNetwork.isEmpty) {
                            _selectedNetwork = detectedNetwork;
                          }
                        }
                      });
                    },
                    placeholder: '09171234567',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(CupertinoIcons.phone, size: 20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  if (_selectedNetwork.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getNetworkColor(_selectedNetwork).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(_getNetworkIcon(_selectedNetwork),
                              color: _getNetworkColor(_selectedNetwork), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedNetwork,
                              style: TextStyle(
                                color: _getNetworkColor(_selectedNetwork),
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            onPressed: () {
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) => _buildNetworkSelectionSheet(),
                              );
                            },
                            child: Text(
                              'Change',
                              style: TextStyle(
                                color: CupertinoColors.systemBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Network Selection (if no number entered)
            if (_mobileNumber.isEmpty) ...[
              Text(
                'Select Network',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoTheme.of(context).textTheme.textStyle.color,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mobileNetworks.length,
                  itemBuilder: (context, index) {
                    final network = _mobileNetworks[index];
                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _selectedNetwork = network['name'];
                        });
                      },
                      child: Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedNetwork == network['name']
                              ? network['color'].withOpacity(0.1)
                              : CupertinoTheme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedNetwork == network['name']
                                ? network['color']
                                : CupertinoColors.systemGrey5,
                            width: _selectedNetwork == network['name'] ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(network['icon'], color: network['color'], size: 32),
                            const SizedBox(height: 8),
                            Text(
                              network['name'],
                              style: TextStyle(
                                color: network['color'],
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Load Amounts
            Text(
              'Select Amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: _loadAmounts.map((item) {
                bool isSelected = _selectedAmount == item['amount'];
                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _selectedAmount = item['amount'].toDouble()),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CupertinoColors.systemPurple.withOpacity(0.1)
                          : CupertinoTheme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? CupertinoColors.systemPurple : CupertinoColors.systemGrey5,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        item['label'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? CupertinoColors.systemPurple
                              : CupertinoTheme.of(context).textTheme.textStyle.color,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Custom Amount
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CupertinoColors.systemGrey5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter any amount between ₱10 - ₱1,000',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _customLoadAmountController,
                    keyboardType: TextInputType.number,
                    placeholder: 'Enter amount',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(CupertinoIcons.money_dollar, size: 20),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _selectedAmount = double.tryParse(value) ?? 0;
                        });
                      }
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),

            // Buy Button
            if (_selectedAmount > 0 && _mobileNumber.isNotEmpty && _selectedNetwork.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 24),
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _isLoading ? null : () => _buyLoad(_selectedAmount),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  borderRadius: BorderRadius.circular(16),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CupertinoActivityIndicator(color: CupertinoColors.white),
                  )
                      : Text(
                    'Buy ₱${_selectedAmount.toStringAsFixed(2)} Load',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUpScreen() {
    return CupertinoScrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            CupertinoNavigationBar(
              middle: const Text('Top-up Wallet'),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0; // Go back to home
                  });
                },
                child: const Icon(CupertinoIcons.arrow_left),
              ),
            ),
            const SizedBox(height: 20),

            // Balance Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CupertinoColors.separator),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.creditcard_fill, size: 40, color: CupertinoColors.systemPurple),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Balance',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        Text(
                          '₱${_walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.systemPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Top-up
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CupertinoColors.separator),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Top-up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Select an amount to add to your wallet',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _topUpAmounts.map((item) {
                      return CupertinoButton.filled(
                        onPressed: () => _handleTopUp(item['amount'].toDouble()),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          item['label'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Custom Amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CupertinoColors.separator),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter any amount between ₱100 - ₱50,000',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _customTopUpAmountController,
                          keyboardType: TextInputType.number,
                          placeholder: 'Enter amount',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(CupertinoIcons.money_dollar, size: 20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CupertinoButton.filled(
                        onPressed: () {
                          final text = _customTopUpAmountController.text.trim();
                          if (text.isEmpty) {
                            _showErrorDialog('Please enter an amount');
                            return;
                          }
                          final amount = double.tryParse(text);
                          if (amount == null) {
                            _showErrorDialog('Please enter a valid amount');
                            return;
                          }
                          _handleTopUp(amount);
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: const Text('Top-up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return CupertinoScrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            CupertinoNavigationBar(
              middle: const Text('Settings'),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0; // Go back to home
                  });
                },
                child: const Icon(CupertinoIcons.arrow_left),
              ),
            ),
            const SizedBox(height: 30),

            // User Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CupertinoColors.separator),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.systemPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.person_fill, color: CupertinoColors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QuickPay User',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: CupertinoTheme.of(context).textTheme.textStyle.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'user@quickpay.com',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Balance: ₱${_walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.systemPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Settings Options
            Text(
              'Preferences',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CupertinoColors.separator),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: CupertinoIcons.bell_fill,
                    title: 'Notifications',
                    trailing: CupertinoSwitch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _showSuccessDialog(
                          'Notifications',
                          value ? 'Notifications enabled' : 'Notifications disabled',
                          CupertinoIcons.bell_fill,
                          CupertinoColors.systemBlue,
                        );
                      },
                    ),
                  ),
                  _buildSettingsDivider(),
                  _buildSettingsItem(
                    icon: CupertinoIcons.moon_fill,
                    title: 'Dark Mode',
                    trailing: CupertinoSwitch(
                      value: darkModeNotifier.value,
                      onChanged: (value) {
                        darkModeNotifier.value = value;
                      },
                    ),
                  ),
                  _buildSettingsDivider(),
                  _buildSettingsItem(
                    icon: CupertinoIcons.clock_fill,
                    title: 'Transaction History',
                    trailing: const Icon(CupertinoIcons.chevron_right, size: 20),
                    onTap: _showTransactionHistory,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Support',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CupertinoColors.separator),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: CupertinoIcons.question_circle_fill,
                    title: 'Help Center',
                    trailing: const Icon(CupertinoIcons.chevron_right, size: 20),
                    onTap: () {
                      _showSuccessDialog(
                        'Help Center',
                        'Access our help center and FAQs.',
                        CupertinoIcons.question_circle_fill,
                        CupertinoColors.systemBlue,
                      );
                    },
                  ),
                  _buildSettingsDivider(),
                  _buildSettingsItem(
                    icon: CupertinoIcons.chat_bubble_fill,
                    title: 'Contact Support',
                    trailing: const Icon(CupertinoIcons.chevron_right, size: 20),
                    onTap: () {
                      _showSuccessDialog(
                        'Contact Support',
                        'Reach out to our customer support team.',
                        CupertinoIcons.chat_bubble_fill,
                        CupertinoColors.systemBlue,
                      );
                    },
                  ),
                  _buildSettingsDivider(),
                  _buildSettingsItem(
                    icon: CupertinoIcons.doc_text_fill,
                    title: 'Terms & Conditions',
                    trailing: const Icon(CupertinoIcons.chevron_right, size: 20),
                    onTap: () {
                      _showSuccessDialog(
                        'Terms & Conditions',
                        'View our terms and conditions.',
                        CupertinoIcons.doc_text_fill,
                        CupertinoColors.systemBlue,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, color: CupertinoColors.systemPurple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSettingsDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 52),
      height: 0.5,
      color: CupertinoColors.separator,
    );
  }

  Widget _buildNetworkSelectionSheet() {
    return Container(
      height: 400,
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(color: CupertinoColors.separator),
              ),
            ),
            child: Text(
              'Select Network',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Choose your mobile network',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _mobileNetworks.length,
              itemBuilder: (context, index) {
                final network = _mobileNetworks[index];
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedNetwork = network['name'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedNetwork == network['name']
                          ? network['color'].withOpacity(0.1)
                          : CupertinoTheme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedNetwork == network['name']
                            ? network['color']
                            : CupertinoColors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: network['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(network['icon'], color: network['color']),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                network['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _selectedNetwork == network['name']
                                      ? network['color']
                                      : CupertinoTheme.of(context).textTheme.textStyle.color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Prefixes: ${network['prefixes'].take(3).join(', ')}...',
                                style: TextStyle(
                                  color: CupertinoColors.secondaryLabel,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedNetwork == network['name'])
                          Icon(CupertinoIcons.checkmark, color: network['color']),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Complete Payment'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Cancel Payment?'),
                content: const Text('Are you sure you want to cancel this payment?'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No'),
                  ),
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _showWebView = false;
                      });
                    },
                    isDestructiveAction: true,
                    child: const Text('Yes, Cancel'),
                  ),
                ],
              ),
            );
          },
          child: const Icon(CupertinoIcons.arrow_left),
        ),
      ),
      child: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (request) {
                if (request.url.contains('quickpay.com/success') ||
                    request.url.contains('quickpay.com/failed')) {
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onPageStarted: (url) {},
              onPageFinished: (url) {},
            ),
          )
          ..loadRequest(Uri.parse(_paymentUrl!)),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildBuyLoadScreen();
      case 2:
        return _buildTopUpScreen();
      case 3:
        return _buildSettingsScreen();
      default:
        return _buildHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _showWebView
        ? _buildWebView()
        : CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home, size: 26),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.phone, size: 26),
            label: 'Buy Load',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.creditcard, size: 26),
            label: 'Top-up',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings, size: 26),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        activeColor: CupertinoColors.systemPurple,
        inactiveColor: CupertinoColors.systemGrey,
        backgroundColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
        height: 65,
        iconSize: 26,
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return _selectedIndex == 0
                ? CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: const Text(
                  'QuickPay Wallet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: _isLoading
                    ? const CupertinoActivityIndicator()
                    : null,
              ),
              child: _buildHomeScreen(),
            )
                : _buildCurrentScreen();
          },
        );
      },
    );
  }
}