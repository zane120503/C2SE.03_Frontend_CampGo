import 'package:CampGo/models/card_model.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:CampGo/config/config.dart';

class UpdateCreditCardPage extends StatefulWidget {
  final CardModel card;

  const UpdateCreditCardPage({super.key, required this.card});

  @override
  State<UpdateCreditCardPage> createState() => _UpdateCreditCardPageState();
}

class _UpdateCreditCardPageState extends State<UpdateCreditCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  bool _isLoading = false;
  bool _isDefaultCard = false;
  final String baseUrl = Config.baseUrl;

  @override
  void initState() {
    super.initState();
    // Điền thông tin thẻ hiện tại vào form
    _cardNumberController.text = widget.card.cardNumber;
    _expiryMonthController.text = widget.card.expiryMonth ?? '';
    _expiryYearController.text = widget.card.expiryYear ?? '';
    _cvvController.text = widget.card.cvv;
    _cardHolderController.text = widget.card.cardHolderName;
    _isDefaultCard = widget.card.isDefault;
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _submitCardDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Prepare card data theo format của backend
        final cardData = {
          'card_name': _cardHolderController.text.trim(),
          'card_number': _cardNumberController.text.replaceAll(' ', ''),
          'card_exp_month': _expiryMonthController.text.padLeft(2, '0'),
          'card_exp_year': _expiryYearController.text,
          'card_cvc': _cvvController.text,
          'card_type': widget.card.cardType ?? 'VISA',
          'is_default': _isDefaultCard
        };

        print('Updating card data: ${json.encode(cardData)}');

        // Kiểm tra đăng nhập và token
        bool isLoggedIn = await AuthService.isLoggedIn();
        if (!isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final authService = AuthService();
        String? token = await authService.getToken();
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Token not found',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Gọi API cập nhật thẻ
        final response = await http.put(
          Uri.parse('$baseUrl/api/UpdateCards/${widget.card.id}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(cardData),
        );

        print('Update card response status: ${response.statusCode}');
        print('Update card response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Update card successfully',
              textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true); // Return true to indicate success
          } else {
            // Show error message from response
            final errorMessage = responseData['message'] ?? 'Update card failed';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage,
              textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Show error message
          String errorMessage;
          try {
            final responseData = json.decode(response.body);
            errorMessage = responseData['message'] ?? 'Update card failed';
          } catch (e) {
            errorMessage = 'Update card failed';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage,
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Update Credit Card',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFEDECF2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Card details',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCardDetailsSection(),
                  const SizedBox(height: 24),
                  _buildUpdateButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardDetailsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Card number',
              border: UnderlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter card number';
              }
              if (value.length < 16) {
                return 'Please enter valid card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryMonthController,
                  decoration: const InputDecoration(
                    labelText: 'Month (MM)',
                    border: UnderlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter month';
                    }
                    int? month = int.tryParse(value);
                    if (month == null || month < 1 || month > 12) {
                      return 'Invalid month';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _expiryYearController,
                  decoration: const InputDecoration(
                    labelText: 'Year (YY)',
                    border: UnderlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter year';
                    }
                    int? year = int.tryParse(value);
                    if (year == null || year < 23) {
                      // Assuming current year is 2023
                      return 'Invalid year';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardHolderController,
            decoration: const InputDecoration(
              labelText: 'Cardholder\'s full name',
              border: UnderlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter cardholder name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cvvController,
            decoration: const InputDecoration(
              labelText: 'CVV',
              border: UnderlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            obscureText: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter CVV';
              }
              if (value.length < 3) {
                return 'CVV must be 3 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Set as default card',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Switch(
                  value: _isDefaultCard,
                  onChanged: (value) {
                    setState(() {
                      _isDefaultCard = value;
                    });
                  },
                  activeColor: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitCardDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 255, 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Update',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
