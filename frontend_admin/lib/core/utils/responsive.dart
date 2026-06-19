import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

enum ScreenSize { mobile, tablet, desktop }

class Responsive {
  Responsive._();

  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppConstants.breakpointMobile) return ScreenSize.mobile;
    if (width < AppConstants.breakpointTablet) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  static bool isMobile(BuildContext context) =>
      of(context) == ScreenSize.mobile;

  static bool isDesktop(BuildContext context) =>
      of(context) == ScreenSize.desktop;
}
