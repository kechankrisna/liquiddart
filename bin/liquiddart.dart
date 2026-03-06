// ignore_for_file: avoid_print

/// liquiddart CLI — render a Liquid template from stdin or a literal argument.
///
/// Usage:
///   echo "Hello, {{ name }}!" | dart run bin/liquiddart.dart --name=World
///   dart run bin/liquiddart.dart "Hello, {{ name }}!" --name=World
library;

import 'dart:io';
import 'package:liquiddart/liquiddart.dart';

void main(List<String> arguments) {
  final assigns = <String, dynamic>{};
  String? source;

  for (final arg in arguments) {
    if (arg.startsWith('--')) {
      final pair = arg.substring(2).split('=');
      if (pair.length == 2) {
        final key = pair[0];
        final raw = pair[1];
        // Auto-convert numeric values
        assigns[key] = num.tryParse(raw) ?? raw;
      }
    } else {
      source = arg;
    }
  }

  // Fall back to stdin if no inline source was given
  if (source == null) {
    if (stdin.hasTerminal) {
      stderr.writeln('Usage: dart run bin/liquiddart.dart "<template>" [--key=value ...]');
      stderr.writeln('   or: echo "{{ msg }}" | dart run bin/liquiddart.dart --msg=Hello');
      exit(1);
    }
    source = stdin.readLineSync() ?? '';
  }

  final engine = LiquidEngine();
  final result = engine.renderString(source, assigns: assigns);
  print(result);
}

