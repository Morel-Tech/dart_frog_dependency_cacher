# Dependency Cacher for Dart Frog

An opinionated caching and dependency injection suite for Dart Frog.

This packaged supports:

- Only creating dependencies the first time they are requested.
- Caching dependencies so they are only built once.
- Allows for dependencies to be built asynchronously.
- Allows caching and requesting via a unique key if you need to cache dependencies of the same type.

## Providing a dependency

```dart
Handler middleware(Handler handler) {
  return handler
      .use(
        futureProvider<MyDependency>(
          (context, {key}) => makeMyDependencyAsync();
        )
      );
}
```

## Using a dependency

```dart
Response onRequest(RequestContext context) async {
  final myDependency = await context.readAsync<MyDependency>();
  /// use myDependency...
}
```

---

Made with 💙 by Morel Technology
