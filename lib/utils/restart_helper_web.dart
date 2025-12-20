// Web-specific restart implementation
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void restartAppPlatform() {
  html.window.location.reload();
}
