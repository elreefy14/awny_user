import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../main.dart';
import '../utils/colors.dart';
import '../utils/constant.dart';
import '../network/rest_apis.dart';

class PhoneNumberCollectionDialog extends StatefulWidget {
  final String? currentPhoneNumber;

  PhoneNumberCollectionDialog({
    this.currentPhoneNumber,
  });

  @override
  _PhoneNumberCollectionDialogState createState() =>
      _PhoneNumberCollectionDialogState();
}

class _PhoneNumberCollectionDialogState
    extends State<PhoneNumberCollectionDialog> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController phoneController = TextEditingController();
  bool _isSaving = false;

  List<SimpleCountry> availableCountries = [
    SimpleCountry(
      name: 'Egypt',
      phoneCode: '20',
      countryCode: 'EG',
      flag: '🇪🇬',
    ),
    SimpleCountry(
      name: 'Saudi Arabia',
      phoneCode: '966',
      countryCode: 'SA',
      flag: '🇸🇦',
    ),
  ];

  SimpleCountry? selectedCountry;

  @override
  void initState() {
    super.initState();
    selectedCountry = availableCountries[0];

    if (widget.currentPhoneNumber.validate().isNotEmpty) {
      String phone = widget.currentPhoneNumber!;
      if (phone.contains('-')) {
        String phoneCode = phone.split('-').first;
        String phoneNumber = phone.split('-').last;

        if (phoneCode == '20') {
          selectedCountry = availableCountries[0];
        } else if (phoneCode == '966') {
          selectedCountry = availableCountries[1];
        }

        phoneController.text = phoneNumber;
      } else {
        phoneController.text = phone;
      }
    }
  }

  String buildFullPhoneNumber() {
    return '${selectedCountry?.phoneCode ?? '20'}-${phoneController.text.trim()}';
  }

  void savePhoneNumber() async {
    if (formKey.currentState!.validate()) {
      hideKeyboard(context);
      String fullPhoneNumber = buildFullPhoneNumber();

      setState(() {
        _isSaving = true;
      });

      try {
        await updateUserPhoneNumber(fullPhoneNumber);
        await setValue(CONTACT_NUMBER, fullPhoneNumber);
        await appStore.setContactNumber(fullPhoneNumber);

        toast('تم حفظ رقم الهاتف بنجاح');

        finish(context, fullPhoneNumber);
      } catch (e) {
        log('Error saving phone number: $e');
        toast('حدث خطأ في حفظ رقم الهاتف');
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> updateUserPhoneNumber(String phoneNumber) async {
    Map<String, String> request = {
      'id': appStore.userId.toString(),
      'contact_number': phoneNumber,
    };
    await updateProfile(request);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone, color: primaryColor, size: 24),
                12.width,
                Text(
                  'رقم الهاتف مطلوب',
                  style: boldTextStyle(size: 18),
                ).expand(),
              ],
            ),
            16.height,
            Text(
              'يرجى إدخال رقم الهاتف لإتمام عملية الحجز. سيتم حفظ الرقم في ملفك الشخصي.',
              style: secondaryTextStyle(size: 14),
            ),
            20.height,
            Form(
              key: formKey,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SimpleCountry>(
                        value: selectedCountry,
                        items: availableCountries.map((country) {
                          return DropdownMenuItem(
                            value: country,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(country.flag,
                                    style: TextStyle(fontSize: 16)),
                                4.width,
                                Text('+${country.phoneCode}',
                                    style: primaryTextStyle(size: 14)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCountry = value;
                          });
                        },
                      ),
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 15,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        hintText: selectedCountry?.countryCode == 'EG'
                            ? '1012345678'
                            : '501234567',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال رقم الهاتف';
                        }
                        if (selectedCountry?.countryCode == 'EG') {
                          if (value.length < 10 || value.length > 11) {
                            return 'رقم الهاتف المصري يجب أن يكون 10-11 رقم';
                          }
                        } else if (selectedCountry?.countryCode == 'SA') {
                          if (value.length != 9) {
                            return 'رقم الهاتف السعودي يجب أن يكون 9 أرقام';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            24.height,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => finish(context),
                    child: Text('إلغاء'),
                  ),
                ),
                12.width,
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : savePhoneNumber,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('حفظ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleCountry {
  final String name;
  final String phoneCode;
  final String countryCode;
  final String flag;

  SimpleCountry({
    required this.name,
    required this.phoneCode,
    required this.countryCode,
    required this.flag,
  });
}
