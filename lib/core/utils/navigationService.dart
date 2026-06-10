import 'package:flutter/material.dart';

/// NavigatorService help navigation 
class NavigatorService {
  NavigatorService._();
  /// navigation key
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// push to new route name
  static Future<dynamic> pushNamed(String routeName,
      {dynamic arguments}) async {
    return navigatorKey.currentState
        ?.pushNamed(routeName, arguments: arguments);
  }
/// back to previous page
  static void goBack() {
    return navigatorKey.currentState?.pop();
  }

/// push and remove all others
  static Future<dynamic> pushNamedAndRemoveUntil(String routeName,
      {bool routePredicate = false, dynamic arguments}) async {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
        routeName, (route) => routePredicate,
        arguments: arguments);
  }

/// push and replaced
  static Future<dynamic> popAndPushNamed(String routeName,
      {dynamic arguments}) async {
    return navigatorKey.currentState
        ?.popAndPushNamed(routeName, arguments: arguments);
  }
}
