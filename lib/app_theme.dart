import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';

class AppTheme {
  //
  AppTheme._();

  static ThemeData lightTheme({Color? color}) => ThemeData(
        useMaterial3: true,
        primarySwatch: createMaterialColor(color ?? primaryColor),
        primaryColor: color ?? primaryColor,
        colorScheme: ColorScheme.fromSeed(
            seedColor: color ?? primaryColor, outlineVariant: borderColor),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: GoogleFonts.inter().fontFamily,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: color ?? primaryColor,
          unselectedItemColor: appTextSecondaryColor.withOpacity(0.6),
          selectedLabelStyle: TextStyle(color: color ?? primaryColor),
          unselectedLabelStyle:
              TextStyle(color: appTextSecondaryColor.withOpacity(0.6)),
          elevation: 8.0,
          type: BottomNavigationBarType.fixed,
        ),
        iconTheme: IconThemeData(color: appTextSecondaryColor),
        textTheme: GoogleFonts.interTextTheme(),
        dialogBackgroundColor: Colors.white,
        unselectedWidgetColor: Colors.black,
        dividerColor: borderColor,
        bottomSheetTheme: BottomSheetThemeData(
          shape: RoundedRectangleBorder(
              borderRadius:
                  radiusOnly(topLeft: defaultRadius, topRight: defaultRadius)),
          backgroundColor: Colors.white,
        ),
        cardColor: cardColor,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: color ?? primaryColor),
        appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: appTextPrimaryColor),
            titleTextStyle: TextStyle(
              color: appTextPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            systemOverlayStyle: SystemUiOverlayStyle(
                statusBarIconBrightness: Brightness.dark,
                statusBarColor: Colors.white)),
        dialogTheme: DialogTheme(shape: dialogShape()),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.all(primaryTextStyle(size: 10)),
          backgroundColor: Colors.white,
          indicatorColor: (color ?? primaryColor).withOpacity(0.1),
          iconTheme: MaterialStateProperty.all(
            IconThemeData(color: appTextSecondaryColor.withOpacity(0.6)),
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );

  static ThemeData darkTheme({Color? color}) => ThemeData(
        useMaterial3: true,
        primarySwatch: createMaterialColor(color ?? primaryColor),
        primaryColor: color ?? primaryColor,
        colorScheme: ColorScheme.fromSeed(
            seedColor: color ?? primaryColor, outlineVariant: borderColor),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: scaffoldSecondaryDark,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: Brightness.light,
              statusBarColor: scaffoldSecondaryDark),
        ),
        scaffoldBackgroundColor: scaffoldColorDark,
        fontFamily: GoogleFonts.inter().fontFamily,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: scaffoldSecondaryDark,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: TextStyle(color: Colors.white),
          unselectedLabelStyle: TextStyle(color: Colors.white70),
          elevation: 8.0,
          type: BottomNavigationBarType.fixed,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        textTheme: GoogleFonts.interTextTheme(),
        dialogBackgroundColor: scaffoldSecondaryDark,
        unselectedWidgetColor: Colors.white60,
        bottomSheetTheme: BottomSheetThemeData(
          shape: RoundedRectangleBorder(
              borderRadius:
                  radiusOnly(topLeft: defaultRadius, topRight: defaultRadius)),
          backgroundColor: scaffoldSecondaryDark,
        ),
        dividerColor: dividerDarkColor,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: color ?? primaryColor),
        cardColor: scaffoldSecondaryDark,
        dialogTheme: DialogTheme(shape: dialogShape()),
        navigationBarTheme: NavigationBarThemeData(
            backgroundColor: scaffoldSecondaryDark,
            indicatorColor: (color ?? primaryColor).withOpacity(0.2),
            iconTheme: MaterialStateProperty.all(
              IconThemeData(color: Colors.white70),
            ),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: MaterialStateProperty.all(
                primaryTextStyle(size: 10, color: Colors.white))),
      ).copyWith(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );
}
