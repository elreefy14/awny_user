import 'package:flutter/material.dart';

/// A simple country code model
class CountryCode {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  factory CountryCode.fromDialCode(String dialCode) {
    switch (dialCode) {
      case '+966':
        return CountryCode(
          name: 'Saudi Arabia',
          code: 'SA',
          dialCode: '966',
          flag: '🇸🇦',
        );
      case '+20':
        return CountryCode(
          name: 'Egypt',
          code: 'EG',
          dialCode: '20',
          flag: '🇪🇬',
        );
      default:
        return CountryCode(
          name: 'Saudi Arabia',
          code: 'SA',
          dialCode: '966',
          flag: '🇸🇦',
        );
    }
  }

  @override
  String toString() => dialCode;
}

/// A simplified country code picker widget
class CountryCodePicker extends StatefulWidget {
  final ValueChanged<CountryCode> onChanged;
  final String initialSelection;
  final bool showCountryOnly;
  final bool showFlag;
  final bool showDropDownButton;
  final EdgeInsetsGeometry padding;
  final bool showOnlyCountryWhenClosed;
  final bool alignLeft;
  final TextStyle textStyle;
  final TextStyle dialogTextStyle;

  const CountryCodePicker({
    Key? key,
    required this.onChanged,
    required this.initialSelection,
    this.showCountryOnly = false,
    this.showFlag = true,
    this.showDropDownButton = true,
    this.padding = EdgeInsets.zero,
    this.showOnlyCountryWhenClosed = false,
    this.alignLeft = false,
    required this.textStyle,
    required this.dialogTextStyle,
  }) : super(key: key);

  @override
  _CountryCodePickerState createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  CountryCode? selectedCountry;
  final List<CountryCode> countryCodes = [
    CountryCode(
      name: 'Saudi Arabia',
      code: 'SA',
      dialCode: '966',
      flag: '🇸🇦',
    ),
    CountryCode(
      name: 'Egypt',
      code: 'EG',
      dialCode: '20',
      flag: '🇪🇬',
    ),
    CountryCode(
      name: 'UAE',
      code: 'AE',
      dialCode: '971',
      flag: '🇦🇪',
    ),
    CountryCode(
      name: 'Kuwait',
      code: 'KW',
      dialCode: '965',
      flag: '🇰🇼',
    ),
    CountryCode(
      name: 'Bahrain',
      code: 'BH',
      dialCode: '973',
      flag: '🇧🇭',
    ),
    CountryCode(
      name: 'Qatar',
      code: 'QA',
      dialCode: '974',
      flag: '🇶🇦',
    ),
    CountryCode(
      name: 'Oman',
      code: 'OM',
      dialCode: '968',
      flag: '🇴🇲',
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedCountry = countryCodes.firstWhere(
      (country) => country.code == widget.initialSelection,
      orElse: () => countryCodes.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showCountryPicker,
      child: Container(
        padding: widget.padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showFlag) ...[
              Text(
                selectedCountry!.flag,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              widget.showOnlyCountryWhenClosed
                  ? selectedCountry!.name
                  : '+${selectedCountry!.dialCode}',
              style: widget.textStyle,
            ),
            if (widget.showDropDownButton) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down,
                color: Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Country'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: countryCodes.length,
            itemBuilder: (context, index) {
              final country = countryCodes[index];
              return ListTile(
                leading: Text(
                  country.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  country.name,
                  style: widget.dialogTextStyle,
                ),
                subtitle: Text(
                  '+${country.dialCode}',
                  style: widget.dialogTextStyle.copyWith(
                    color: Colors.grey,
                    fontSize: widget.dialogTextStyle.fontSize! - 2,
                  ),
                ),
                onTap: () {
                  setState(() {
                    selectedCountry = country;
                  });
                  widget.onChanged(country);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
