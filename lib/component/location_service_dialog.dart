import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class LocationServiceDialog extends StatefulWidget {
  final Function()? onAccept;

  LocationServiceDialog({this.onAccept});

  @override
  State<LocationServiceDialog> createState() => _LocationServiceDialogState();
}

class _LocationServiceDialogState extends State<LocationServiceDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
                  appStore.isCurrentLocation
                      ? language.msgForLocationOn
                      : language.msgForLocationOff,
                  style: primaryTextStyle())
              .paddingAll(16),
          16.height,
          AppButton(
            text:
                appStore.isCurrentLocation ? language.turnOff : language.turnOn,
            width: context.width(),
            margin: EdgeInsets.all(16),
            color: primaryColor,
            textColor: Colors.white,
            onTap: () async {
              if (widget.onAccept != null) {
                widget.onAccept!.call();
              }

              finish(context, true);
            },
          ),
          8.height,
        ],
      ),
    );
  }
}
