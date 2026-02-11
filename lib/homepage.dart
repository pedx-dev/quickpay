
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

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
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  String _userPIN = "123456";

// Mobile network providers
  final List<Map<String, dynamic>> _mobileNetworks = [
    {
      'name': 'Smart',
      'logo': 'S',
      'color': CupertinoColors.systemRed,
      'icon': CupertinoIcons.bolt_fill,
      'prefixes': [
        '0819',
        '0908',
        '0918',
        '0919',
        '0920',
        '0921',
        '0930',
        '0931',
        '0940',
        '0946',
        '0947',
        '0948',
        '0949',
        '0951',
        '0970',
        '0980',
        '0981',
        '0989',
        '0990',
        '0991',
        '0998',
        '0999'
      ],
    },
    {
      'name': 'TNT',
      'logo': 'T',
      'color': CupertinoColors.systemOrange,
      'icon': CupertinoIcons.flame_fill,
      'prefixes': [
        '0905',
        '0906',
        '0915',
        '0916',
        '0917',
        '0925',
        '0926',
        '0927',
        '0935',
        '0936',
        '0937',
        '0945',
        '0950',
        '0955',
        '0956',
        '0960',
        '0961',
        '0965',
        '0966',
        '0967',
        '0975',
        '0976',
        '0977',
        '0978',
        '0979'
      ],
    },
    {
      'name': 'Globe',
      'logo': 'G',
      'color': CupertinoColors.systemGreen,
      'icon': CupertinoIcons.globe,
      'prefixes': [
        '0817',
        '0905',
        '0906',
        '0915',
        '0916',
        '0917',
        '0926',
        '0927',
        '0935',
        '0936',
        '0937',
        '0945',
        '0953',
        '0954',
        '0955',
        '0956',
        '0965',
        '0966',
        '0967',
        '0975',
        '0976',
        '0977',
        '0978',
        '0979',
        '0995',
        '0996',
        '0997'
      ],
    },
    {
      'name': 'TM',
      'logo': 'TM',
      'color': CupertinoColors.systemBlue,
      'icon': CupertinoIcons.antenna_radiowaves_left_right,
      'prefixes': [
        '0895',
        '0896',
        '0897',
        '0898',
        '0904',
        '0905',
        '0906',
        '0915',
        '0916',
        '0926',
        '0927',
        '0935',
        '0936',
        '0937',
        '0945',
        '0953',
        '0954',
        '0956',
        '0965',
        '0966',
        '0967',
        '0975',
        '0976',
        '0977',
        '0978',
        '0979'
      ],
    },
    {
      'name': 'DITO',
      'logo': 'D',
      'color': CupertinoColors.systemPurple,
      'icon': CupertinoIcons.rocket_fill,
      'prefixes': [
        '0891',
        '0892',
        '0893',
        '0894',
        '0895',
        '0896',
        '0897',
        '0898',
        '0991',
        '0992',
        '0993',
        '0994'
      ],
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
    _paymentSuccessController =
    StreamController<Map<String, dynamic>>.broadcast();
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

  Future<Map<String, dynamic>> _createXenditInvoiceForTopUp(
      double amount) async {
    const String url = "https://api.xendit.co/v2/invoices";

    String basicAuth = base64Encode(utf8.encode('$_xenditSecretKey:'));

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic $basicAuth',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'external_id': 'topup_${DateTime
            .now()
            .millisecondsSinceEpoch}',
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
      throw Exception(
          'Failed to create invoice. Status: ${response.statusCode}');
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
      'id': _currentInvoiceId ?? '${DateTime
          .now()
          .millisecondsSinceEpoch}',
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
      '₱${amount.toStringAsFixed(
          2)} has been added to your wallet.\n\nNew Balance: ₱${_walletBalance
          .toStringAsFixed(2)}',
      CupertinoIcons.check_mark_circled,
      CupertinoColors.systemGreen,
    );
  }

// ============================================
// LOAD PURCHASE FUNCTIONS (USES WALLET BALANCE)
// ============================================

  String? _detectNetwork(String mobileNumber) {
    if (mobileNumber.isEmpty) return null;

    String cleanNumber = mobileNumber.startsWith('0') ? mobileNumber.substring(
        1) : mobileNumber;
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
        'id': 'load_${DateTime
            .now()
            .millisecondsSinceEpoch}',
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
        '₱${amount.toStringAsFixed(
            2)} has been sent to $_mobileNumber ($_selectedNetwork).\n\nLoad will be credited within 5-10 minutes.\n\nNew Balance: ₱${_walletBalance
            .toStringAsFixed(2)}',
        CupertinoIcons.check_mark_circled,
        CupertinoColors.systemGreen,
      );
    });
  }

// ============================================
// SECURITY FUNCTIONS
// ============================================

  void _showChangePINDialog() {
    String currentPIN = '';
    String newPIN = '';
    String confirmPIN = '';
    bool changingPIN = false;

    showCupertinoDialog(
      context: context,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setState) {
              return CupertinoAlertDialog(
                title: const Text('Change PIN'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      if (!changingPIN)
                        CupertinoTextField(
                          obscureText: true,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          placeholder: 'Enter current 6-digit PIN',
                          onChanged: (value) => currentPIN = value,
                        ),

                      if (changingPIN) ...[
                        CupertinoTextField(
                          obscureText: true,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          placeholder: 'Enter new 6-digit PIN',
                          onChanged: (value) => newPIN = value,
                        ),
                        const SizedBox(height: 16),
                        CupertinoTextField(
                          obscureText: true,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          placeholder: 'Confirm new 6-digit PIN',
                          onChanged: (value) => confirmPIN = value,
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () {
                      if (!changingPIN) {
                        if (currentPIN != _userPIN) {
                          _showErrorDialog('Incorrect current PIN');
                          return;
                        }
                        setState(() {
                          changingPIN = true;
                        });
                      } else {
                        if (newPIN.length != 6) {
                          _showErrorDialog('PIN must be 6 digits');
                          return;
                        }
                        if (newPIN != confirmPIN) {
                          _showErrorDialog('PINs do not match');
                          return;
                        }

                        this.setState(() {
                          _userPIN = newPIN;
                        });

                        Navigator.pop(context);
                        _showSuccessDialog(
                          'PIN Changed',
                          'Your PIN has been successfully updated.',
                          CupertinoIcons.check_mark_circled,
                          CupertinoColors.systemGreen,
                        );
                      }
                    },
                    child: Text(changingPIN ? 'Change PIN' : 'Continue'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _verifyPINForTransaction(Function() onSuccess) {
    String enteredPIN = '';

    showCupertinoDialog(
      context: context,
      builder: (context) =>
          CupertinoAlertDialog(
            title: const Text('Enter PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text('Please enter your 6-digit PIN to continue'),
                const SizedBox(height: 16),
                CupertinoTextField(
                  obscureText: true,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 10),
                  onChanged: (value) {
                    enteredPIN = value;
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
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery
                .of(context)
                .size
                .height * 0.8,
            decoration: BoxDecoration(
              color: _darkModeEnabled
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transaction History',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Icon(CupertinoIcons.xmark),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.doc_text, size: 60,
                            color: CupertinoColors.systemGrey),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                              color: CupertinoColors.systemGrey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionItem(_transactions[index]);
                    },
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
      builder: (context) =>
          CupertinoAlertDialog(
            title: const Text('Scan QR Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 200,
                  height: 200,
                  color: CupertinoColors.systemGrey5,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.qrcode, size: 60,
                            color: CupertinoColors.systemGrey),
                        const SizedBox(height: 16),
                        const Text('QR Code Scanner'),
                        const Text('(Simulated)'),
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
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _showSuccessDialog(
                    'Payment Successful',
                    'You have successfully paid ₱150.00 to Maria\'s Store.',
                    CupertinoIcons.check_mark_circled,
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
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery
                .of(context)
                .size
                .height * 0.7,
            decoration: BoxDecoration(
              color: _darkModeEnabled
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Send Money',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Icon(CupertinoIcons.xmark),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: recipientController,
                  placeholder: '09171234567',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(CupertinoIcons.person, size: 20),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  placeholder: '₱0.00',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(CupertinoIcons.money_dollar, size: 20),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: () {
                      final recipient = recipientController.text.trim();
                      final amount = double.tryParse(
                          amountController.text.trim());

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
                            'id': 'transfer_${DateTime
                                .now()
                                .millisecondsSinceEpoch}',
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
                          '₱${amount.toStringAsFixed(
                              2)} has been sent to $recipient.\n\nNew Balance: ₱${_walletBalance
                              .toStringAsFixed(2)}',
                          CupertinoIcons.check_mark_circled,
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
    );
  }

  void _showBillsPaymentScreen() {
    List<Map<String, dynamic>> billers = [
      {
        'name': 'Meralco',
        'icon': CupertinoIcons.bolt,
        'color': CupertinoColors.systemBlue
      },
      {
        'name': 'Maynilad',
        'icon': CupertinoIcons.drop,
        'color': CupertinoColors.systemBlue
      },
      {
        'name': 'PLDT',
        'icon': CupertinoIcons.phone,
        'color': CupertinoColors.systemRed
      },
      {
        'name': 'Converge',
        'icon': CupertinoIcons.wifi,
        'color': CupertinoColors.systemOrange
      },
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery
                .of(context)
                .size
                .height * 0.7,
            decoration: BoxDecoration(
              color: _darkModeEnabled
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pay Bills',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Icon(CupertinoIcons.xmark),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Select a biller to pay:'),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: billers.length,
                    itemBuilder: (context, index) {
                      final biller = billers[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showBillPaymentForm(biller['name']);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _darkModeEnabled ? CupertinoColors
                                .darkBackgroundGray : CupertinoColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CupertinoColors
                                .systemGrey5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(biller['icon'], size: 40,
                                  color: biller['color']),
                              const SizedBox(height: 8),
                              Text(biller['name']),
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
      builder: (context) =>
          CupertinoAlertDialog(
            title: Text('Pay $biller Bill'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: accountController,
                  placeholder: 'Account Number',
                  padding: const EdgeInsets.all(12),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  placeholder: 'Amount',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text('₱'),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
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
                        'id': 'bill_${DateTime
                            .now()
                            .millisecondsSinceEpoch}',
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
                      'Your $biller bill of ₱${amount.toStringAsFixed(
                          2)} has been paid.\n\nNew Balance: ₱${_walletBalance
                          .toStringAsFixed(2)}',
                      CupertinoIcons.check_mark_circled,
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

  void _logout() {
    showCupertinoDialog(
      context: context,
      builder: (context) =>
          CupertinoAlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _showSuccessDialog(
                    'Logged Out',
                    'You have been successfully logged out.',
                    CupertinoIcons.arrow_right_square,
                    CupertinoColors.systemBlue,
                  );
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

// ============================================
// UI HELPER FUNCTIONS
// ============================================

  void _showSuccessDialog(String title, String message, IconData icon,
      Color color) {
    showCupertinoDialog(
      context: context,
      builder: (context) =>
          CupertinoAlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 10),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
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
      builder: (context) =>
          CupertinoAlertDialog(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.exclamationmark_circle,
                    color: CupertinoColors.systemRed, size: 30),
                SizedBox(width: 10),
                Text('Error'),
              ],
            ),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
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
      builder: (context) =>
          CupertinoAlertDialog(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.exclamationmark_triangle,
                    color: CupertinoColors.systemOrange, size: 30),
                SizedBox(width: 10),
                Text('Insufficient Balance'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text(
                    'Your wallet balance is insufficient for this purchase.'),
                const SizedBox(height: 15),
                Text(
                  'Required: ₱${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Current: ₱${_walletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 15),
                Text(
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
                isDefaultAction: true,
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
      builder: (context) =>
          CupertinoAlertDialog(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.time, color: CupertinoColors.systemOrange,
                    size: 30),
                SizedBox(width: 10),
                Text('Payment Taking Too Long'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 8),
                Text('Your payment is still being processed.'),
                SizedBox(height: 10),
                Text(
                  'Please check your email or return to the dashboard.',
                  style: TextStyle(
                      fontSize: 12, color: CupertinoColors.systemGrey),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
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
    return CupertinoIcons.device_phone_portrait;
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
    final Color color = isCredit ? CupertinoColors.systemGreen : CupertinoColors
        .systemRed;
    final IconData icon = transaction['service'] == 'load'
        ? CupertinoIcons.device_phone_portrait
        : transaction['service'] == 'transfer'
        ? CupertinoIcons.arrow_right_circle
        : transaction['service'] == 'bills'
        ? CupertinoIcons.doc_text
        : CupertinoIcons.money_dollar_circle;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _darkModeEnabled
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.white,
        border: Border.all(color: CupertinoColors.systemGrey5, width: 0.5),
      ),
      child: CupertinoListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          transaction['title'],
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: _darkModeEnabled ? CupertinoColors.white : CupertinoColors
                .black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction['subtitle'] ?? '',
              style: TextStyle(
                color: _darkModeEnabled
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              transaction['date'],
              style: TextStyle(
                fontSize: 12,
                color: _darkModeEnabled
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+₱' : '-₱'}${transaction['amount'].toStringAsFixed(
                  2)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: transaction['status'] == 'completed'
                    ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
                    : CupertinoColors.systemOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                transaction['status'],
                style: TextStyle(
                  fontSize: 10,
                  color: transaction['status'] == 'completed'
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final size = MediaQuery.of(context).size;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.all(size.width * 0.05),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemPurple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.money_dollar_circle,
                  color: CupertinoColors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'WALLET BALANCE',
                style: TextStyle(
                    color: Color(0xB3FFFFFF), fontSize: 12, letterSpacing: 1),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _selectedIndex = 3; // Go to Settings
                  });
                },
                child: const Icon(CupertinoIcons.ellipsis_vertical,
                    color: CupertinoColors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₱${_walletBalance.toStringAsFixed(2)}',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: size.width * 0.1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionButton(
                icon: CupertinoIcons.qrcode_viewfinder,
                label: 'Scan & Pay',
                onTap: _showQRCodeScanner,
              ),
              _buildQuickActionButton(
                icon: CupertinoIcons.arrow_right_circle,
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

  Widget _buildQuickActionButton(
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return Flexible(
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: CupertinoColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: CupertinoColors.white.withValues(alpha: 0.3), width: 1),
              ),
              child: Icon(icon, color: CupertinoColors.white, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: CupertinoColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80,
          top: 16,
        ),
        child: Column(
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showTransactionHistory,
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: _darkModeEnabled
                      ? CupertinoColors.darkBackgroundGray
                      : CupertinoColors.white,
                  border: Border.all(
                      color: CupertinoColors.systemGrey5, width: 0.5),
                ),
                child: _transactions.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.doc_text, size: 60,
                          color: _darkModeEnabled
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey2),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          color: _darkModeEnabled
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey2,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your transactions will appear here',
                        style: TextStyle(
                          color: _darkModeEnabled
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey3,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _transactions
                        .take(3)
                        .map(_buildTransactionItem)
                        .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: _darkModeEnabled
                      ? CupertinoColors.darkBackgroundGray
                      : CupertinoColors.white,
                  border: Border.all(
                      color: CupertinoColors.systemGrey5, width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkModeEnabled
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildServiceButton(
                            icon: CupertinoIcons.device_phone_portrait,
                            label: 'Buy Load',
                            color: CupertinoColors.systemPurple,
                            onTap: () {
                              setState(() {
                                _selectedIndex = 1; // Go to Buy Load screen
                              });
                            },
                          ),
                          _buildServiceButton(
                            icon: CupertinoIcons.money_dollar_circle,
                            label: 'Top-up',
                            color: CupertinoColors.systemGreen,
                            onTap: () {
                              setState(() {
                                _selectedIndex = 2; // Go to Top-up screen
                              });
                            },
                          ),
                          _buildServiceButton(
                            icon: CupertinoIcons.time,
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
            ),
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
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBuyLoadScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
// Header
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0; // Go back to home
                    });
                  },
                  child: const Icon(CupertinoIcons.back, size: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Buy Mobile Load',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

// Mobile Number Input
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: _darkModeEnabled
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              border: Border.all(
                  color: CupertinoColors.systemGrey5, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mobile Number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _mobileNumberController,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    onChanged: (value) {
                      setState(() {
                        _mobileNumber = value;
                        if (value.length >= 4) {
                          String? detectedNetwork = _detectNetwork(value);
                          if (detectedNetwork != null &&
                              _selectedNetwork.isEmpty) {
                            _selectedNetwork = detectedNetwork;
                          }
                        }
                      });
                    },
                    style: TextStyle(
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                    placeholder: '09171234567',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(CupertinoIcons.phone, size: 20,
                          color: CupertinoColors.systemPurple),
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _darkModeEnabled ? CupertinoColors
                          .darkBackgroundGray : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  if (_selectedNetwork.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getNetworkColor(_selectedNetwork).withValues(
                            alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(_getNetworkIcon(_selectedNetwork),
                              color: _getNetworkColor(_selectedNetwork)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedNetwork,
                              style: TextStyle(
                                color: _getNetworkColor(_selectedNetwork),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) =>
                                    _buildNetworkSelectionSheet(),
                              );
                            },
                            child: const Text(
                              'Change',
                              style: TextStyle(
                                color: CupertinoColors.activeBlue,
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
          ),

          const SizedBox(height: 20),

// Network Selection (if no number entered)
          if (_mobileNumber.isEmpty) ...[
            Text(
              'Select Network',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _darkModeEnabled
                    ? CupertinoColors.white
                    : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mobileNetworks.length,
                itemBuilder: (context, index) {
                  final network = _mobileNetworks[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedNetwork = network['name'];
                      });
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedNetwork == network['name']
                            ? network['color'].withOpacity(0.1)
                            : _darkModeEnabled
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _selectedNetwork == network['name']
                              ? network['color']
                              : const Color(0x00000000),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(network['icon'], color: network['color'],
                              size: 30),
                          const SizedBox(width: 8),
                          Text(
                            network['name'],
                            style: TextStyle(
                              color: network['color'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

// Load Amounts
          Text(
            'Select Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _darkModeEnabled ? CupertinoColors.white : CupertinoColors
                  .black,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            mainAxisSpacing: 5,
            crossAxisSpacing: 10,
            children: _loadAmounts.map((item) {
              bool isSelected = _selectedAmount == item['amount'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedAmount = item['amount'].toDouble()),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CupertinoColors.systemPurple.withValues(alpha: 0.1)
                        : _darkModeEnabled
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? CupertinoColors.systemPurple
                          : const Color(0x00000000),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['label'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? CupertinoColors.systemPurple
                              : _darkModeEnabled
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

// Custom Amount
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: _darkModeEnabled
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              border: Border.all(
                  color: CupertinoColors.systemGrey5, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter any amount between ₱10 - ₱1,000',
                    style: TextStyle(
                      color: _darkModeEnabled
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _customLoadAmountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: _darkModeEnabled
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _selectedAmount = double.tryParse(value) ?? 0;
                              });
                            }
                          },
                          placeholder: 'Enter amount',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(CupertinoIcons.money_dollar, size: 20,
                                color: CupertinoColors.systemPurple),
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _darkModeEnabled ? CupertinoColors
                                .darkBackgroundGray : CupertinoColors
                                .systemGrey6,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CupertinoButton.filled(
                        onPressed: () {
                          if (_selectedAmount > 0) {
                            _buyLoad(_selectedAmount);
                          }
                        },
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.arrow_right_circle, size: 18),
                            SizedBox(width: 4),
                            Text('Buy'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

// Buy Button
          if (_selectedAmount > 0 && _mobileNumber.isNotEmpty &&
              _selectedNetwork.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 20),
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: _isLoading ? null : () => _buyLoad(_selectedAmount),
                child: _isLoading
                    ? const CupertinoActivityIndicator(
                    color: CupertinoColors.white)
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.device_phone_portrait, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Buy ₱${_selectedAmount.toStringAsFixed(
                          2)} Load to $_mobileNumber',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUpScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
// Header
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0; // Go back to home
                    });
                  },
                  child: const Icon(CupertinoIcons.back, size: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Top-up Wallet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

// Balance Info
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: _darkModeEnabled
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              border: Border.all(
                  color: CupertinoColors.systemGrey5, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.money_dollar_circle, size: 40,
                      color: CupertinoColors.systemPurple),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Balance',
                          style: TextStyle(
                            color: _darkModeEnabled
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.systemGrey2,
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
          ),

          const SizedBox(height: 20),

// Quick Top-up
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: _darkModeEnabled
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              border: Border.all(
                  color: CupertinoColors.systemGrey5, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Top-up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Select an amount to add to your wallet',
                    style: TextStyle(
                      color: _darkModeEnabled
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _topUpAmounts.map((item) {
                      return CupertinoButton.filled(
                        onPressed: () =>
                            _handleTopUp(item['amount'].toDouble()),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
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
          ),

          const SizedBox(height: 20),

// Custom Amount
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: _darkModeEnabled
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              border: Border.all(
                  color: CupertinoColors.systemGrey5, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter any amount between ₱100 - ₱50,000',
                    style: TextStyle(
                      color: _darkModeEnabled
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _customTopUpAmountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: _darkModeEnabled
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                          placeholder: 'Enter amount',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(CupertinoIcons.money_dollar, size: 20,
                                color: CupertinoColors.systemPurple),
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _darkModeEnabled ? CupertinoColors
                                .darkBackgroundGray : CupertinoColors
                                .systemGrey6,
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                        child: const Text('Top-up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

// Payment Methods
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: _darkModeEnabled
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              border: Border.all(
                  color: CupertinoColors.systemGrey5, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Methods',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.creditcard,
                        color: CupertinoColors.systemPurple),
                    title: Text(
                      'Credit/Debit Card',
                      style: TextStyle(
                        color: _darkModeEnabled
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                    subtitle: Text(
                      'Visa, Mastercard, JCB',
                      style: TextStyle(
                        color: _darkModeEnabled
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2,
                      ),
                    ),
                  ),
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.building_2_fill,
                        color: CupertinoColors.systemPurple),
                    title: Text(
                      'Bank Transfer',
                      style: TextStyle(
                        color: _darkModeEnabled
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                    subtitle: Text(
                      'BDO, BPI, UnionBank, etc.',
                      style: TextStyle(
                        color: _darkModeEnabled
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2,
                      ),
                    ),
                  ),
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.qrcode,
                        color: CupertinoColors.systemPurple),
                    title: Text(
                      'E-Wallets',
                      style: TextStyle(
                        color: _darkModeEnabled
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                    subtitle: Text(
                      'GCash, Maya, GrabPay',
                      style: TextStyle(
                        color: _darkModeEnabled
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSettingsScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
// Header
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0; // Go back to home
                    });
                  },
                  child: const Icon(CupertinoIcons.back, size: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

// User Info Card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: _darkModeEnabled
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              border: Border.all(
                  color: CupertinoColors.systemGrey5, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.systemPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                        CupertinoIcons.person, color: CupertinoColors.white,
                        size: 30),
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
                            fontWeight: FontWeight.bold,
                            color: _darkModeEnabled
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'user@quickpay.com',
                          style: TextStyle(
                            color: _darkModeEnabled
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.systemGrey2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Balance: ₱${_walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
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
          ),

          const SizedBox(height: 20),

// Settings Options
          Text(
            'Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _darkModeEnabled
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: _darkModeEnabled
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              border: Border.all(
                  color: CupertinoColors.systemGrey5, width: 0.5),
            ),
            child: Column(
              children: [
                CupertinoListTile(
                  leading: const Icon(
                      CupertinoIcons.bell, color: CupertinoColors.systemPurple),
                  title: Text(
                    'Notifications',
                    style: TextStyle(
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  trailing: CupertinoSwitch(
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _showSuccessDialog(
                        'Notifications',
                        value
                            ? 'Notifications enabled'
                            : 'Notifications disabled',
                        CupertinoIcons.bell,
                        CupertinoColors.systemBlue,
                      );
                    },
                  ),
                ),
                Container(height: 1, color: CupertinoColors.separator),
                CupertinoListTile(
                  leading: const Icon(
                      CupertinoIcons.moon, color: CupertinoColors.systemPurple),
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  trailing: CupertinoSwitch(
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                    },
                  ),
                ),
                Container(height: 1, color: CupertinoColors.separator),
                CupertinoListTile(
                  leading: const Icon(
                      CupertinoIcons.time, color: CupertinoColors.systemPurple),
                  title: Text(
                    'Transaction History',
                    style: TextStyle(
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  trailing: const Icon(CupertinoIcons.right_chevron,
                      color: CupertinoColors.systemPurple),
                  onTap: _showTransactionHistory,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Security',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _darkModeEnabled
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: _darkModeEnabled
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              border: Border.all(
                  color: CupertinoColors.systemGrey5, width: 0.5),
            ),
            child: Column(
              children: [
                CupertinoListTile(
                  leading: const Icon(
                      CupertinoIcons.lock, color: CupertinoColors.systemPurple),
                  title: Text(
                    'Change PIN',
                    style: TextStyle(
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  trailing: const Icon(CupertinoIcons.right_chevron,
                      color: CupertinoColors.systemPurple),
                  onTap: _showChangePINDialog,
                ),
                Container(height: 1, color: CupertinoColors.separator),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.hand_raised,
                      color: CupertinoColors.systemPurple),
                  title: Text(
                    'Biometric Login',
                    style: TextStyle(
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  trailing: CupertinoSwitch(
                    value: _biometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        _biometricEnabled = value;
                      });
                      _showSuccessDialog(
                        'Biometric Login',
                        value
                            ? 'Biometric login enabled'
                            : 'Biometric login disabled',
                        CupertinoIcons.hand_raised,
                        CupertinoColors.systemBlue,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Support',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _darkModeEnabled
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: _darkModeEnabled
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              border: Border.all(
                  color: CupertinoColors.systemGrey5, width: 0.5),
            ),
            child: Column(
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.question_circle,
                      color: CupertinoColors.systemPurple),
                  title: Text(
                    'Help Center',
                    style: TextStyle(
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  trailing: const Icon(CupertinoIcons.right_chevron,
                      color: CupertinoColors.systemPurple),
                  onTap: () {
                    _showSuccessDialog(
                      'Help Center',
                      'Access our help center and FAQs.',
                      CupertinoIcons.question_circle,
                      CupertinoColors.systemBlue,
                    );
                  },
                ),
                Container(height: 1, color: CupertinoColors.separator),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.chat_bubble_2,
                      color: CupertinoColors.systemPurple),
                  title: Text(
                    'Contact Support',
                    style: TextStyle(
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  trailing: const Icon(CupertinoIcons.right_chevron,
                      color: CupertinoColors.systemPurple),
                  onTap: () {
                    _showSuccessDialog(
                      'Contact Support',
                      'Reach out to our customer support team.',
                      CupertinoIcons.chat_bubble_2,
                      CupertinoColors.systemBlue,
                    );
                  },
                ),
                Container(height: 1, color: CupertinoColors.separator),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.doc_text,
                      color: CupertinoColors.systemPurple),
                  title: Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      color: _darkModeEnabled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  trailing: const Icon(CupertinoIcons.right_chevron,
                      color: CupertinoColors.systemPurple),
                  onTap: () {
                    _showSuccessDialog(
                      'Terms & Conditions',
                      'View our terms and conditions.',
                      CupertinoIcons.doc_text,
                      CupertinoColors.systemBlue,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

// Logout Button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: CupertinoColors.destructiveRed,
              onPressed: _logout,
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildNetworkSelectionSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        color: _darkModeEnabled
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Network',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _darkModeEnabled ? CupertinoColors.white : CupertinoColors
                  .black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Choose your mobile network',
            style: TextStyle(
              color: _darkModeEnabled
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
            ),
          ),
          const SizedBox(height: 20),
          ..._mobileNetworks.map((network) {
            return CupertinoListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: network['color'].withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(network['icon'], color: network['color'], size: 20),
              ),
              title: Text(
                network['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _selectedNetwork == network['name']
                      ? network['color']
                      : _darkModeEnabled
                      ? CupertinoColors.white
                      : CupertinoColors.black,
                ),
              ),
              subtitle: Text(
                'Prefixes: ${network['prefixes'].take(3).join(', ')}...',
                style: TextStyle(
                  color: _darkModeEnabled
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey2,
                ),
              ),
              trailing: _selectedNetwork == network['name']
                  ? Icon(
                  CupertinoIcons.check_mark_circled, color: network['color'])
                  : null,
              onTap: () {
                Navigator.pop(context);
                this.setState(() {
                  _selectedNetwork = network['name'];
                });
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Complete Payment'),
        backgroundColor: _darkModeEnabled
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.white,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () {
            showCupertinoDialog(
              context: context,
              builder: (context) =>
                  CupertinoAlertDialog(
                    title: const Text('Cancel Payment?'),
                    content: const Text(
                        'Are you sure you want to cancel this payment?'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('No'),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _showWebView = false;
                          });
                        },
                        child: const Text('Yes, Cancel'),
                      ),
                    ],
                  ),
            );
          },
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
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.device_phone_portrait),
            label: 'Buy Load',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.money_dollar_circle),
            label: 'Top-up',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        activeColor: CupertinoColors.activeBlue,
        inactiveColor: CupertinoColors.systemGrey,
        backgroundColor: _darkModeEnabled
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.white,
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoPageScaffold(
          navigationBar: _selectedIndex == 0
              ? CupertinoNavigationBar(
            middle: const Text('QuickPay Wallet'),
            backgroundColor: CupertinoColors.systemBackground.withValues(alpha: 0),
            border: null,
            trailing: _isLoading
                ? const CupertinoActivityIndicator()
                : null,
          )
              : null,
          backgroundColor: _darkModeEnabled
              ? CupertinoColors.black
              : CupertinoColors.systemGroupedBackground,
          child: _buildCurrentScreen(),
        );
      },
    );
  }
}
