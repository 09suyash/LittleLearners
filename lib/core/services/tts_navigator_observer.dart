import 'package:flutter/widgets.dart';
import 'tts_service.dart';
import 'sound_service.dart';

class TtsNavigatorObserver extends NavigatorObserver {
  TtsNavigatorObserver();

  Route<dynamic>? currentRoute;

  static void stopAllAudio() {
    TtsService().stop();
    SoundService().stop();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    currentRoute = previousRoute;
    stopAllAudio();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    currentRoute = route;
    stopAllAudio();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    currentRoute = newRoute;
    stopAllAudio();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    currentRoute = previousRoute;
    stopAllAudio();
  }
}
