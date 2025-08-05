import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/paymob_service.dart';
import '../../model/paymob_config.dart';

class PayMobWalletExampleScreen extends StatefulWidget {
  @override
  _PayMobWalletExampleScreenState createState() =>
      _PayMobWalletExampleScreenState();
}

class _PayMobWalletExampleScreenState extends State<PayMobWalletExampleScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  String selectedPlanSlug = 'basic-plan';
  File? selectedFile;
  String paymentMethod = 'paymob'; // PayMob with wallet support
  bool isLoading = false;

  // PayMob Configuration - These should come from your backend API
  // Example response from your backend should include:
  // {
  //   "paymob_api_key": "your_api_key",
  //   "paymob_integration_id": "card_integration_id",
  //   "paymob_iframe_id": "card_iframe_id",
  //   "paymob_wallet_integration_id": "wallet_integration_id",
  //   "paymob_wallet_iframe_id": "wallet_iframe_id"
  // }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitWithPayMobWallets() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Step 1: Submit form data to your backend and get PayMob configuration
      final uri =
          Uri.parse('https://yourdomain.com/membership/build-vodafone-charge');
      var request = http.MultipartRequest('POST', uri);

      request.fields['hiddenId'] = selectedPlanSlug;
      request.fields['hiddenName'] = nameController.text;
      request.fields['hiddenTelephone'] = phoneController.text;
      request.fields['hiddenEmail'] = emailController.text;
      request.fields['payment_method'] = paymentMethod;

      if (selectedFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('file', selectedFile!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['paymob_config'] != null) {
        // Step 2: Extract PayMob configuration from response
        final paymobConfig = data['paymob_config'];

        final apiKey = paymobConfig['paymob_api_key'] ?? '';
        final integrationId = paymobConfig['paymob_integration_id'] ?? '';
        final iframeId = paymobConfig['paymob_iframe_id'] ?? '';
        final walletIntegrationId =
            paymobConfig['paymob_wallet_integration_id'] ?? '';
        final walletIframeId = paymobConfig['paymob_wallet_iframe_id'] ?? '';
        final amount = data['amount'] ?? 100.0; // Amount from your backend

        if (apiKey.isEmpty || integrationId.isEmpty || iframeId.isEmpty) {
          throw 'PayMob configuration is incomplete';
        }

        // Step 3: Initialize PayMob service with wallet support
        final payMobService = PayMobService(
          config: PayMobConfig(
            apiKey: apiKey,
            integrationId: integrationId,
            iframeId: iframeId,
            walletIntegrationId:
                walletIntegrationId.isNotEmpty ? walletIntegrationId : null,
            walletIframeId: walletIframeId.isNotEmpty ? walletIframeId : null,
            isTest: true, // Set based on your environment
          ),
        );

        await payMobService.initialize();

        // Step 4: Prepare billing data
        final billingData = {
          'first_name': nameController.text.split(' ').first,
          'last_name': nameController.text.split(' ').length > 1
              ? nameController.text.split(' ').last
              : 'N/A',
          'email': emailController.text,
          'phone_number': phoneController.text,
          'apartment': 'NA',
          'floor': 'NA',
          'street': 'NA',
          'building': 'NA',
          'shipping_method': 'NA',
          'postal_code': 'NA',
          'city': 'NA',
          'country': 'EG',
          'state': 'NA'
        };

        // Step 5: Create payment URL with wallet support
        String paymentUrl;

        if (walletIntegrationId.isNotEmpty) {
          print('Creating PayMob payment with electronic wallet support');

          // Create array of integration IDs as requested by user
          List<String> integrationIds = [integrationId, walletIntegrationId];

          print('Using integration IDs array: $integrationIds');

          // Use the new wallet-enabled method
          paymentUrl = await payMobService.createPaymentUrlWithWallets(
            amount: amount * 100, // Amount in cents
            currency: 'EGP',
            integrationIds: integrationIds, // Send as array as requested
            billingData: billingData,
            primaryIframeId: iframeId, // Use card iframe as primary
          );

          print('PayMob payment URL with wallet support created: $paymentUrl');
        } else {
          print('Creating PayMob payment with cards only');

          // Fallback to original method
          final paymentKey = await payMobService.createPaymentKey(
            amount: amount * 100,
            currency: 'EGP',
            integrationId: integrationId,
            billingData: billingData,
          );

          paymentUrl =
              'https://accept.paymob.com/api/acceptance/iframes/$iframeId?payment_token=$paymentKey';
        }

        // Step 6: Launch PayMob payment page
        print('Launching PayMob URL: $paymentUrl');

        final bool launchResult = await launchUrl(
          Uri.parse(paymentUrl),
          mode: LaunchMode.externalApplication,
        );

        if (!launchResult) {
          throw 'Could not launch PayMob payment page';
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'تم توجيهك لصفحة الدفع - ستظهر البطاقات والمحافظ الإلكترونية')));
      } else if (data['message'] != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'])));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Something went wrong')));
      }
    } catch (e) {
      print('PayMob Wallet Error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PayMob with Electronic Wallets'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.payment, size: 48, color: Colors.blue),
                      SizedBox(height: 8),
                      Text(
                        'الدفع بالبطاقات والمحافظ الإلكترونية',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'سيتم عرض خيارات الدفع بالبطاقات الائتمانية والمحافظ الإلكترونية',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value != null && value.length >= 3
                    ? null
                    : 'Name too short',
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Telephone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) => value != null && value.length >= 10
                    ? null
                    : 'Phone too short',
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) => value != null && value.contains('@')
                    ? null
                    : 'Invalid email',
              ),
              SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: Icon(Icons.attach_file),
                label: Text(selectedFile == null
                    ? 'Upload File (optional)'
                    : 'Change File'),
              ),
              if (selectedFile != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child:
                      Text('Selected: ${selectedFile!.path.split('/').last}'),
                ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isLoading ? null : _submitWithPayMobWallets,
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.payment),
                label: Text(
                    isLoading ? 'Processing...' : 'Pay with Cards & E-Wallets'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملاحظة مهمة:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue[800]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• يجب أن يرجع الباك إند array من iframe IDs\n'
                      '• سيتم عرض خيارات الدفع بالبطاقات والمحافظ الإلكترونية\n'
                      '• تأكد من تكوين PayMob dashboard بشكل صحيح',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
