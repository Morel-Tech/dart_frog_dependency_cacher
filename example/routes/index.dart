// ignore_for_file: avoid_print

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_dependency_cacher/dart_frog_dependency_cacher.dart';

Future<Response> onRequest(RequestContext context) async {
  final string = context.readAsync<String>();
  print(string);
  return Response(body: 'Welcome to Dart Frog!');
}
