import 'dart:convert';

import 'package:flutter/foundation.dart';

class PrettyPrint {
  static void print(Map<String, dynamic> message) {
    String prettyJson = const JsonEncoder.withIndent('  ').convert(message);
    debugPrint(prettyJson);
  }
}
