import 'package:flutter/material.dart';

class RoundedTextField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final Color textColor;
  final TextEditingController controller;
  final bool isObscure;
  final bool? readOnly;
  final RegExp? validatorRegex;
  final String? Function(String?)? validatorFunction;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final GestureTapCallback? onTap;
  final AutovalidateMode? autovalidateMode; // Added autovalidateMode

  const RoundedTextField({
    Key? key,
    required this.label,
    required this.textColor,
    required this.controller,
    required this.isObscure,
    this.readOnly,
    this.initialValue,
    this.validatorRegex,
    this.validatorFunction,
    this.keyboardType,
    this.validator,
    this.onTap,
    this.suffixIcon,
    this.autovalidateMode, required bool obscureText,
  }) : super(key: key);

  @override
  _RoundedTextFieldState createState() => _RoundedTextFieldState();
}

class _RoundedTextFieldState extends State<RoundedTextField> {
  late bool _isObscure;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.isObscure;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(color: widget.textColor),
        ),
        SizedBox(
          height: 48, // Adjust the height of the container as needed
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), // Adjust the radius as needed
                  color: Color.fromARGB(255, 199, 173, 162), // Use a suitable background color
                ),
                child: TextFormField(
                  
                  initialValue: widget.initialValue,
                  controller: widget.controller,
                  obscureText: _isObscure,
                  style: TextStyle(color: widget.textColor), // Text color
                  decoration: InputDecoration(
                    border: InputBorder.none, // Remove the border
                    contentPadding: EdgeInsets.symmetric(horizontal: 20), // Adjust padding as needed
                    errorStyle: TextStyle(color: Colors.red),
                    suffixIcon: widget.suffixIcon,
                  ),
                  keyboardType: widget.keyboardType,
                  autovalidateMode: widget.autovalidateMode, // Added autovalidateMode
                  validator: widget.validator,
                  onTap: widget.onTap,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _ErrorText(errorMessage: _getErrorMessage()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _getErrorMessage() {
    final value = widget.controller.text;
    if (widget.validatorRegex != null &&
        value.isNotEmpty &&
        !widget.validatorRegex!.hasMatch(value)) {
      return 'Please enter a valid ${widget.label.toLowerCase()}';
    }
    if (widget.validatorFunction != null) {
      return widget.validatorFunction!(value);
    }
    return null;
  }
}

class _ErrorText extends StatelessWidget {
  final String? errorMessage;

  const _ErrorText({Key? key, this.errorMessage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Text(
        errorMessage!,
        style: const TextStyle(color: Colors.red),
      );
    } else {
      return const SizedBox.shrink(); // Or another invisible widget
    }
  }
}
