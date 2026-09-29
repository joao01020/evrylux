import 'package:flutter/services.dart';

enum ChannelMode {
  bidirectional,
}

class WindowMethodChannel {
  const WindowMethodChannel(
    this.name, {
    this.mode = ChannelMode.bidirectional,
  });

  final String name;
  final ChannelMode mode;

  Future<void> setMethodCallHandler(
    Future<dynamic> Function(MethodCall call)? handler,
  ) async {
    // No Web a lousa usa o mapa mental inline.
  }

  Future<T?> invokeMethod<T>(
    String method, [
    dynamic arguments,
  ]) async {
    return null;
  }
}

class WindowConfiguration {
  const WindowConfiguration({
    this.hiddenAtLaunch = false,
    this.arguments = '',
  });

  final bool hiddenAtLaunch;
  final String arguments;
}

class WindowController {
  WindowController._({
    this.arguments = '',
  });

  final String arguments;

  static Future<List<WindowController>> getAll() async {
    return const <WindowController>[];
  }

  static Future<WindowController> create(
    WindowConfiguration configuration,
  ) async {
    return WindowController._(
      arguments: configuration.arguments,
    );
  }

  Future<void> show() async {
    // No-op no Web. RoutineScreen intercepta antes de chegar aqui.
  }
}
