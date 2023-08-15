import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_dependency_cacher/dart_frog_dependency_cacher.dart';

Handler middleware(Handler handler) {
  return handler.use(
    futureProvider<String>(
      (context, {key}) async => 'fun_string',
    ),
  );
}
