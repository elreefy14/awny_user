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
          backgroundColor: bottomNavBarLightBgColor,
          selectedItemColor: orangePrimaryColor,
          unselectedItemColor: unselectedNavItemLightColor,
          selectedLabelStyle: TextStyle(color: orangePrimaryColor),
          unselectedLabelStyle: TextStyle(color: unselectedNavItemLightColor),
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
        floatingActionButtonTheme:
            FloatingActionButtonThemeData(backgroundColor: orangePrimaryColor),
        appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: orangePrimaryColor,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            systemOverlayStyle: SystemUiOverlayStyle(
                statusBarIconBrightness: Brightness.light,
                statusBarColor: orangePrimaryColor)),
        dialogTheme: DialogTheme(shape: dialogShape()),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.all(primaryTextStyle(size: 10)),
          backgroundColor: bottomNavBarLightBgColor,
          indicatorColor: orangePrimaryColor.withOpacity(0.2),
          iconTheme: MaterialStateProperty.all(
            IconThemeData(color: unselectedNavItemLightColor),
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
          backgroundColor: bottomNavBarDarkBgColor,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: Brightness.light,
              statusBarColor: bottomNavBarDarkBgColor),
        ),
        scaffoldBackgroundColor: scaffoldColorDark,
        fontFamily: GoogleFonts.inter().fontFamily,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: bottomNavBarDarkBgColor,
          selectedItemColor: orangePrimaryDarkColor,
          unselectedItemColor: unselectedNavItemDarkColor,
          selectedLabelStyle: TextStyle(color: orangePrimaryDarkColor),
          unselectedLabelStyle: TextStyle(color: unselectedNavItemDarkColor),
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
            backgroundColor: orangePrimaryDarkColor),
        cardColor: scaffoldSecondaryDark,
        dialogTheme: DialogTheme(shape: dialogShape()),
        navigationBarTheme: NavigationBarThemeData(
            backgroundColor: bottomNavBarDarkBgColor,
            indicatorColor: orangePrimaryDarkColor.withOpacity(0.2),
            iconTheme: MaterialStateProperty.all(
              IconThemeData(color: unselectedNavItemDarkColor),
            ),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: MaterialStateProperty.all(
                primaryTextStyle(size: 10, color: orangePrimaryDarkColor))),
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
