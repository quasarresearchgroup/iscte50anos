import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IscteTheme {
  static Color iscteColor = const Color.fromRGBO(14, 41, 194, 1);
  static Radius appbarRadius = const Radius.circular(20);

  static AppBarTheme get appBarTheme {
    return AppBarTheme(
      //backgroundColor: Color.fromRGBO(14, 41, 194, 1),
      elevation: 0,
      // This removes the shadow from all App Bars.
      centerTitle: true,
      toolbarHeight: 55,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: IscteTheme.appbarRadius,
        ),
      ),
      backgroundColor: iscteColor,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: iscteColor,
        systemNavigationBarColor: iscteColor,
        statusBarIconBrightness: Brightness.light, // For Android (dark icons)
        statusBarBrightness: Brightness.light, // For iOS (dark icons)
      ),
    );
  }

  static ThemeData get lightThemeData {
    return ThemeData.light().copyWith(
      primaryColor: iscteColor,
      errorColor: Colors.deepOrangeAccent,
      appBarTheme: appBarTheme,
      bottomNavigationBarTheme: ThemeData.light()
          .bottomNavigationBarTheme
          .copyWith(backgroundColor: iscteColor),
    );
  }

  static ThemeData get darkThemeData {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      backgroundColor: Colors.black,
      primaryColor: iscteColor,
      errorColor: Colors.deepOrangeAccent,
      appBarTheme: appBarTheme,
      bottomNavigationBarTheme: ThemeData.dark()
          .bottomNavigationBarTheme
          .copyWith(backgroundColor: iscteColor),
    );
  }
}

/*
 AppBarTheme appBarTheme = const AppBarTheme(
      elevation: 0, // This removes the shadow from all App Bars.
      centerTitle: true,
      toolbarHeight: 55,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    );

    var darkTheme = ThemeData.dark();


    ThemeData.light().copyWith(
        primaryColor: const Color.fromRGBO(14, 41, 194, 1),
        appBarTheme: appBarTheme.copyWith(
          backgroundColor: const Color.fromRGBO(14, 41, 194, 1),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Color.fromRGBO(14, 41, 194, 1),
            statusBarIconBrightness:
                Brightness.light, // For Android (dark icons)
            statusBarBrightness: Brightness.light, // For iOS (dark icons)
          ),
        ),
      )

      ThemeData.dark().copyWith(
          appBarTheme: appBarTheme.copyWith(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: darkTheme.bottomAppBarColor,
          statusBarIconBrightness: Brightness.light, // For Android (dark icons)
          statusBarBrightness: Brightness.light, // For iOS (dark icons)
        ),
      ))


 */
