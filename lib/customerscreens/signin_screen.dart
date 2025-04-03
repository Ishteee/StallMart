// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xaviers_market/customerscreens/createaccount_screen.dart';
import 'package:xaviers_market/sellerscreens/sellerForgotPass.dart';
import '/services/auth_services.dart';
import '/consts/rounded_textfield.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  bool rememberMe = false;
  bool _isLoading = false;

  bool _isSecurePassword = true;
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: const BackButton(
          color: Colors.brown,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              height: 1000, // Adjusted height to make the image smaller
              width: double.infinity,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/customer.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: const Color.fromARGB(255, 242, 233, 226).withOpacity(0.70),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Log In',
                      style: TextStyle(
                        color: Color.fromARGB(255, 126, 70, 62),
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RoundedTextField(
                      label: 'Email',
                      textColor: Colors.black,
                      controller: emailController,
                      isObscure: false,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    RoundedTextField(
                      label: 'Password',
                      textColor: Colors.black,
                      controller: passwordController,
                      isObscure: _isSecurePassword,
                      keyboardType: TextInputType.text,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isSecurePassword = !_isSecurePassword;
                            if (!_isSecurePassword) {
                              _timer = Timer(
                                const Duration(seconds: 1),
                                () {
                                  setState(() {
                                    _isSecurePassword = true;
                                    _timer = null; // Reset the timer
                                  });
                                },
                              );
                            } else {
                              _timer
                                  ?.cancel(); // Cancel the timer if password visibility is toggled back
                            }
                          });
                        },
                        icon: _isSecurePassword
                            ? const Icon(Icons.visibility_off)
                            : const Icon(Icons.visibility),
                        color: Colors.grey,
                      ),
                    ),
                    Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('Remember Me',
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ),
                      Checkbox(
                        value: rememberMe,
                        activeColor: Colors.brown,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value!;
                          });
                        },
                      ),
                    ],
                  ),
                    Stack(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : () async {

                            setState(() {
                              _isLoading = true; // Show the loading indicator
                            });

                            try {
                              await signInAsCustomer(emailController.text,
                                passwordController.text, context,rememberMe); // Call your sign-up function
                                
                            } catch (e) {
                              // Handle any errors during sign-up (optional)
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Error'),
                                    content: Text(e.toString()),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } finally {
                              setState(() {
                                _isLoading = false; // Hide the loading indicator
                              });
                            }

                            
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: Colors.brown,
                          ),
                          child: const Text(
                            'Log In',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          20,
                          0,
                          0,
                        ), // Adjusted padding
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: const TextStyle(
                              color: Colors.brown,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: "Create_one",
                                style: const TextStyle(
                                  color: Colors.blue, // Changed to blue
                                  decoration: TextDecoration.underline,
                                  fontSize: 14,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CreateAccountScreen(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ForgotPasswordForm()),
                          );
                          print("Forgot Password tapped");
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoundedTextField extends StatelessWidget {
  final String label;
  final Color textColor;
  final TextEditingController controller;
  final bool isObscure;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  const RoundedTextField({
    super.key,
    required this.label,
    required this.textColor,
    required this.controller,
    required this.isObscure,
    required this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}
