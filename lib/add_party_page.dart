import 'package:flutter/material.dart';

// Stateful widget to add a new party
class AddPartyPage extends StatefulWidget {
  // Callback function to handle the addition of a party
  final void Function(String name, String number, String email) onAddParty;

  const AddPartyPage({super.key, required this.onAddParty});

  @override
  State<AddPartyPage> createState() => _AddPartyPageState();
}

class _AddPartyPageState extends State<AddPartyPage> {
  // Text controllers to handle user input
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _emailController = TextEditingController();

  // Form key to validate the input fields
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _nameController.dispose();
    _numberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Validation for the name field
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name cannot be empty';
    }
    return null;
  }

  // Validation for the number field
  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Number cannot be empty';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Number should contain only digits';
    }
    if (value.length != 10) {
      return 'Number should be 10 digits long';
    }
    return null;
  }

  // Validation for the email field (optional)
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email is optional
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Party',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input field for party name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Party Name',
                  labelStyle: TextStyle(color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 15),
              // Input field for contact number
              TextFormField(
                controller: _numberController,
                decoration: InputDecoration(
                  labelText: 'Number',
                  labelStyle: TextStyle(color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: _validateNumber,
              ),
              const SizedBox(height: 15),
              // Input field for email (optional)
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email ID',
                  labelStyle: TextStyle(color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 30),
              // Button to submit the form
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onAddParty(
                      _nameController.text.trim(),
                      _numberController.text.trim(),
                      _emailController.text.trim().isEmpty
                          ? 'No email address provided'
                          : _emailController.text.trim(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Party added successfully!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'ADD PARTY',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
