import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main() async {
  const baseUrl = 'http://127.0.0.1:5000';

  while (true) {
    final response = await http.get(Uri.parse('$baseUrl/state'));
    if (response.statusCode != 200) {
      throw Exception('El backend respondio ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final estado = data['hand_state'];
    final autoMoviendose = data['car_moving'];
    final dedos = data['fingers_up'];

    stdout.writeln(
      'Estado mano: $estado | dedos: $dedos | auto: $autoMoviendose',
    );

    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
