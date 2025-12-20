// Platform-specific restart implementation
import 'package:flutter/services.dart';
import 'restart_helper_stub.dart'
    if (dart.library.html) 'restart_helper_web.dart'
    if (dart.library.io) 'restart_helper_io.dart';

void restartApp() {
  restartAppPlatform();
}
