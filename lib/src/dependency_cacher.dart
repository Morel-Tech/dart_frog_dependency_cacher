import 'dart:async';

import 'package:dart_frog/dart_frog.dart';

/// A function that creates a dependency.
typedef DependencyBuilder<T> = FutureOr<T> Function(
  RequestContext context, {
  String? key,
});

final Map<String, DependencyBuilder<dynamic>> _dependencies = {};
final Map<String, dynamic> _cache = {};

/// A [Middleware] that injects a dependency asynchronously and caches it for
/// future use.
Middleware futureProvider<T>(
  DependencyBuilder<T> create, {
  bool shouldCache = true,
  bool Function(T)? cacheValid,
}) {
  return (handler) {
    return (outerContext) {
      final saved = _dependencies[T.toString()];
      if (saved == null) {
        if (shouldCache) {
          _dependencies[T.toString()] = (context, {key}) => _asyncMemo<T>(
                () => create(context, key: key),
                key: key,
                cacheValid: cacheValid,
              );
        } else {
          _dependencies[T.toString()] =
              (context, {key}) => create(context, key: key);
        }
      }
      return handler(outerContext);
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
  final currentCacheValidChecker = cacheValid ?? ((T _) => true);
  if (cachedValue != null && currentCacheValidChecker(cachedValue)) {
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
  Future<T> readAsync<T>({String? key}) async {
    final depBuilder = _dependencies[T.toString()];
    if (depBuilder == null) {
      throw Exception('Missing create function for type $T');
    }
    final dep = await depBuilder(this, key: key);
    if (dep is T) {
      return dep;
    }
    throw Exception(
      'Dependency for key $key was type ${dep.runtimeType.runtimeType}. '
      'Expected $T',
    );
  }
}
