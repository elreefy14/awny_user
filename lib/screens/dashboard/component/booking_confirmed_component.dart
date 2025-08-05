import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/booking/booking_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../model/booking_data_model.dart';
import '../../../utils/colors.dart';
import '../../../utils/common.dart';
import '../../../utils/constant.dart';

class PendingBookingComponent extends StatefulWidget {
  final BookingData? upcomingConfirmedBooking;

  PendingBookingComponent({this.upcomingConfirmedBooking});

  @override
  State<PendingBookingComponent> createState() =>
      _PendingBookingComponentState();
}

class _PendingBookingComponentState extends State<PendingBookingComponent> {
  @override
  Widget build(BuildContext context) {
    if (widget.upcomingConfirmedBooking == null) return Offstage();

    if (getBoolAsync(
        '$BOOKING_ID_CLOSED_${widget.upcomingConfirmedBooking!.id}')) {
      return Offstage();
    }

    if (widget.upcomingConfirmedBooking!.status != BOOKING_STATUS_PENDING &&
        widget.upcomingConfirmedBooking!.status != BOOKING_STATUS_ACCEPT) {
      return Offstage();
    }

    return Container(
      margin: EdgeInsets.all(12), // Reduced from 16 to 12
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 20), // Reduced top and bottom padding
      decoration: boxDecorationRoundedWithShadow(defaultRadius.toInt(),
          backgroundColor: primaryColor),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    height: 18, // Reduced from 20 to 18
                    width: 3,
                    decoration: boxDecorationRoundedWithShadow(
                        defaultRadius.toInt(),
                        backgroundColor: Colors.white.withOpacity(0.6)),
                  ),
                  6.width, // Reduced from 8 to 6
                  Marquee(
                          child: Text(language.bookingConfirmedMsg,
                              style: primaryTextStyle(
                                  color: Colors.white,
                                  size: LABEL_TEXT_SIZE,
                                  fontStyle: FontStyle.italic)))
                      .expand(),
                ],
              ).expand(),
              SizedBox(
                width: 28, // Reduced from 30 to 28
                height: 20, // Reduced from 22 to 20
                child: IconButton(
                  icon:
                      Icon(Icons.cancel, color: Colors.white.withOpacity(0.6)),
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    await setValue(
                        '$BOOKING_ID_CLOSED_${widget.upcomingConfirmedBooking!.id}',
                        true);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          12.height, // Reduced from 16 to 12
          Row(
            children: [
              Container(
                height: 38, // Reduced from 42 to 38
                width: 38, // Reduced from 42 to 38
                decoration:
                    boxDecorationRoundedWithShadow(19, // Reduced from 21 to 19
                        backgroundColor: Colors.white.withOpacity(0.2)),
                child: Icon(Icons.library_add_check_outlined,
                    size: 16, color: Colors.white), // Reduced from 18 to 16
              ),
              6.width, // Reduced from 8 to 6
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.upcomingConfirmedBooking!.serviceName.validate(),
                      style: boldTextStyle(color: Colors.white)),
                  1.height, // Reduced from 2 to 1
                  Text(
                      formatDate(
                          widget.upcomingConfirmedBooking!.date.validate(),
                          showDateWithTime: true),
                      style: primaryTextStyle(
                          color: Colors.white,
                          size: 13)), // Reduced from 14 to 13
                ],
              ).flexible(),
            ],
          )
        ],
      ).onTap(() {
        BookingDetailScreen(bookingId: widget.upcomingConfirmedBooking!.id!)
            .launch(context);
      }),
    );
  }
}
