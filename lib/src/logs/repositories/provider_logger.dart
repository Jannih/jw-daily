import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProviderLogger extends ProviderObserver {
  static String _truncate(Object? value, [int maxLen = 70]) {
    final str = value.toString();
    return str.length > maxLen ? '${str.substring(0, maxLen)}...' : str;
  }

  @override
  void didAddProvider(
    ProviderBase<dynamic> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint(
          'didAddProvider: ${provider.name ?? provider.runtimeType} -- value: ${_truncate(value)}');
    }
  }

  @override
  void providerDidFail(ProviderBase<dynamic> provider, Object error,
      StackTrace stackTrace, ProviderContainer container) {
    if (kDebugMode) {
      debugPrint(
          'providerDidFail: ${provider.name ?? provider.runtimeType} -- error: ${_truncate(error)}');
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase<dynamic> provider,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint(
          'didDisposeProvider: ${provider.name ?? provider.runtimeType}');
    }
  }

  @override
  void didUpdateProvider(
    ProviderBase<dynamic> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint(
          'didUpdateProvider: ${provider.name ?? provider.runtimeType} -- newValue: ${_truncate(newValue)}');
    }
  }
}
