// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:dart_frog/dart_frog.dart';

/// A function that creates a dependency.
typedef DependencyBuilder<T> = FutureOr<T> Function(
  RequestContext context, {
  String? key,
});

/// A function that finds a caching key given a context
typedef KeyFinder = FutureOr<String?> Function(RequestContext context);

final Map<String, dynamic> _cache = {};

/// A [Middleware] that injects a dependency asynchronously and caches it for
/// future use.
Middleware futureProvider<T>(
  DependencyBuilder<T> create, {
  KeyFinder? keyFinder,
  bool shouldCache = true,
  bool Function(T)? cacheValid,
}) {
  return (handler) {
    return (context) async {
      final newContext = shouldCache
          ? context.provide<Future<T>>(() async {
              final key = await keyFinder?.call(context);
              return _asyncMemo<T>(
                () => create(context, key: key),
                key: key,
                cacheValid: cacheValid,
              );
            })
          : context.provide<Future<T>>(() => Future.value(create(context)));

      return handler(newContext);
    };
  };
}

Future<T> _asyncMemo<T>(
  FutureOr<T> Function() create, {
  String? key,
  bool Function(T)? cacheValid,
}) async {
  final cacheKey = key ?? T.toString();
  final cachedValue = _cache[cacheKey] as T?;
  if (cachedValue != null &&
      (cacheValid == null || cacheValid.call(cachedValue))) {
    return cachedValue;
  }
  final value = await create();
  return _cache[cacheKey] = value;
}

/// Extension providing [readAsync]
extension RequestContextAsync on RequestContext {
  /// Lookup an instance of [T] from the [request] context if [T] is
  /// provided asynchronously.
  ///
  /// An [Exception] is thrown if [T] is not available within
  /// the provided [request] context.
  Future<T> readAsync<T>() => read<Future<T>>();
}
