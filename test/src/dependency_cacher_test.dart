import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_dependency_cacher/dart_frog_dependency_cacher.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequest extends Mock implements Request {}

class _TestRequestContext implements RequestContext {
  final dependencies = <String, dynamic>{};
  @override
  RequestContext provide<T extends Object?>(T Function() create) {
    dependencies['$T'] = create();
    return this;
  }

  @override
  T read<T>() {
    return dependencies['$T'] as T;
  }

  @override
  Request get request => _MockRequest();
}

void main() {
  test('readAsync calls read on Future of type', () {
    final context = _TestRequestContext();
    final newContext = context.provide(() => Future.value('__value__'));

    expect(newContext.readAsync<String>(), completion('__value__'));
  });
}
