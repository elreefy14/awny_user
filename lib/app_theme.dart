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
            seedColor: color ?? primaryColor,
            outlineVariant: borderColor,
            background: primaryLightColor, // خلفية دافئة
            surface: cardColor),
        scaffoldBackgroundColor:
            primaryLightColor, // خلفية دافئة بدلاً من الأبيض الصارخ
        fontFamily: GoogleFonts.inter().fontFamily,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: cardColor, // لون دافئ للشريط السفلي
          selectedItemColor: color ?? primaryColor,
          unselectedItemColor: appTextSecondaryColor.withOpacity(0.7),
          selectedLabelStyle: TextStyle(
            color: color ?? primaryColor,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            color: appTextSecondaryColor.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          elevation: 12.0, // ظل أقوى لمظهر أكثر عمقاً
          type: BottomNavigationBarType.fixed,
        ),
        iconTheme: IconThemeData(color: appTextSecondaryColor),
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: appTextPrimaryColor, // تطبيق لون النص الجديد
          displayColor: appTextPrimaryColor,
        ),
        dialogBackgroundColor: cardColor, // حوارات بخلفية دافئة
        unselectedWidgetColor: appTextSecondaryColor,
        dividerColor: borderColor,
        bottomSheetTheme: BottomSheetThemeData(
          shape: RoundedRectangleBorder(
              borderRadius:
                  radiusOnly(topLeft: defaultRadius, topRight: defaultRadius)),
          backgroundColor: cardColor, // خلفية دافئة للـ bottom sheet
        ),
        cardColor: cardColor,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: color ?? primaryColor,
            foregroundColor: Colors.white),
        appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: cardColor, // خلفية دافئة للـ AppBar
            surfaceTintColor: Colors.transparent,
            iconTheme: IconThemeData(color: appTextPrimaryColor),
            titleTextStyle: TextStyle(
              color: appTextPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: GoogleFonts.inter().fontFamily,
            ),
            systemOverlayStyle: SystemUiOverlayStyle(
                statusBarIconBrightness: Brightness.dark,
                statusBarColor: primaryLightColor)), // شريط الحالة بلون دافئ
        dialogTheme: DialogTheme(
          shape: dialogShape(),
          backgroundColor: cardColor,
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.all(
              primaryTextStyle(size: 10, color: appTextPrimaryColor)),
          backgroundColor: cardColor,
          indicatorColor:
              awnyBrandLightOrange.withOpacity(0.3), // مؤشر بلون البراند
          iconTheme: MaterialStateProperty.all(
            IconThemeData(color: appTextSecondaryColor.withOpacity(0.7)),
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
        dividerColor: awnyDividerDarkColor,
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
