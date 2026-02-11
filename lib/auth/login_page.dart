import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import '../homepage.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  String msg = "";
  bool hidePassword = true;
  final box = Hive.box("database");
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                const Text(
                  'Login',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome back to QuickPay',
                  style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
                ),
                const SizedBox(height: 40),
                CupertinoTextField(
                  controller: _username,
                  placeholder: "Username",
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(CupertinoIcons.person),
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: _password,
                  placeholder: "Password",
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(CupertinoIcons.padlock),
                  ),
                  padding: const EdgeInsets.all(16),
                  obscureText: hidePassword,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffix: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(hidePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton.filled(
                          child: const Text('Sign In'),
                          onPressed: () {
                            if (_username.text.trim() == box.get("username") &&
                                _password.text.trim() == box.get("password")) {
                              setState(() {
                                msg = "";
                              });
                              Navigator.pushReplacement(
                                context,
                                CupertinoPageRoute(builder: (context) => const HomePage()),
                              );
                            } else {
                              setState(() {
                                msg = "Invalid username or password";
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (box.get("biometrics") == true)
                        CupertinoButton(
                          child: Column(
                            children: [
                              Icon(CupertinoIcons.person_crop_circle, size: 50, color: CupertinoColors.activeBlue),
                              SizedBox(height: 8),
                              Text('Face ID', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          onPressed: () async {
                            try {
                              final bool canAuthenticate = await auth.canCheckBiometrics ||
                                  await auth.isDeviceSupported();

                              if (!canAuthenticate) {
                                setState(() {
                                  msg = "Biometrics not available";
                                });
                                return;
                              }

                              final bool didAuthenticate = await auth.authenticate(
                                localizedReason: 'Please authenticate to login to your local account',
                                options: const AuthenticationOptions(
                                  biometricOnly: true,
                                ),
                              );

                              if (didAuthenticate) {
                                if (mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    CupertinoPageRoute(builder: (context) => const HomePage()),
                                  );
                                }
                              } else {
                                setState(() {
                                  msg = "Authentication Failed";
                                });
                              }
                            } catch (e) {
                              setState(() {
                                msg = "Error: ${e.toString()}";
                              });
                            }
                          },
                        ),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Reset Data', style: TextStyle(color: CupertinoColors.destructiveRed)),
                        onPressed: () async {
                          // Show confirmation dialog first (no biometric needed)
                          showCupertinoDialog(
                            context: context,
                            builder: (dialogContext) {
                              return CupertinoAlertDialog(
                                title: const Text("Reset All Data"),
                                content: const Text(
                                    "Are you sure you want to delete all registered local data? This action cannot be undone."),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('Cancel'),
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                    },
                                  ),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    child: const Text('Delete All Data'),
                                    onPressed: () async {
                                      try {
                                        // Close dialog
                                        Navigator.pop(dialogContext);

                                        // Delete all data
                                        await box.delete("username");
                                        await box.delete("password");
                                        await box.delete("biometrics");

                                        // Navigate to signup page
                                        if (mounted) {
                                          Navigator.pushReplacement(
                                            context,
                                            CupertinoPageRoute(
                                                builder: (context) => const SignupPage()),
                                          );
                                        }
                                      } catch (e) {
                                        // Show error if something goes wrong
                                        if (mounted) {
                                          setState(() {
                                            msg = "Error resetting data: ${e.toString()}";
                                          });
                                        }
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      if (msg.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            msg,
                            style: const TextStyle(color: CupertinoColors.destructiveRed),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

