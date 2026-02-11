import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final box = Hive.box("database");
  bool hidePassword = true;
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
                  'Create Account',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a local account for QuickPay',
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
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      child: const Text('Sign Up'),
                      onPressed: () {
                        if (_username.text.trim().isEmpty || _password.text.trim().isEmpty) {
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text("Error"),
                              content: const Text("Please fill in all fields"),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('OK'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        box.put("username", _username.text.trim());
                        box.put("password", _password.text.trim());
                        box.put("biometrics", false);

                        Navigator.pushReplacement(
                          context,
                          CupertinoPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                    ),
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

