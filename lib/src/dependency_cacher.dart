import 'dart:async';

import 'package:dart_frog/dart_frog.dart';

/// A function that creates a dependency.
typedef DependencyBuilder<T> = FutureOr<T> Function(
  RequestContext context, {
  String? key,
});

/// A function that finds a caching key given a context
typedef KeyFinder = FutureOr<String> Function(RequestContext context);

typedef _CachedDependencyBuilder<T> = FutureOr<T> Function(
  RequestContext context,
);

final Map<String, _CachedDependencyBuilder<dynamic>> _dependencyBuilders = {};
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
    return (outerContext) async {
      final key = await keyFinder?.call(
        outerContext,
      );
      final saved = _dependencyBuilders[T.toString()];
      if (saved == null) {
        if (shouldCache) {
          _dependencyBuilders[T.toString()] = (context) async {
            return _asyncMemo<T>(
              () => create(context, key: key),
              key: key,
              cacheValid: cacheValid,
            );
          };
        } else {
          _dependencyBuilders[T.toString()] = (context) => create(context);
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
  Future<T> readAsync<T>() async {
    final depBuilder = _dependencyBuilders[T.toString()];
    if (depBuilder == null) {
      throw Exception('Missing create function for type $T');
    }
    final dep = await depBuilder(this);
    if (dep is T) {
      return dep;
    }
    throw Exception(
      'Dependency for $T was type ${dep.runtimeType.runtimeType}. '
      'Expected $T',
    );
  }
}
