import 'dart:io';

import 'parser_extension.dart';

class CustomEnv {
  static Map<String, String> _map = {};
  static String _file = '.env';

  CustomEnv._();

  factory CustomEnv.fromFile(String file) {
    _file = file;
    return CustomEnv._();
  }

  static Future<T> get<T>({required String key}) async {
    if (_map.isEmpty) {
      await _load();
    }

    return _map[key]!.toType(T);
  }

  static Future<void> _load() async {
    List<String> lines = (await _readFile()).split('\n').where((line) => line.isNotEmpty).toList();

    _map = {for (var l in lines) l.split('=')[0]: l.split('=')[1]};
  }

  static Future<String> _readFile() async {
    return await File(_file).readAsString();
  }
}
