import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../citas/models/cita_model.dart';
import '../../citas/services/cita_service.dart';
import '../models/horario_model.dart';
import '../services/horario_service.dart';

final horarioListProvider = FutureProvider<List<HorarioModel>>((ref) async {
  final res = await ref.watch(horarioServiceProvider).listar();
  return res.data;
});

final horarioCitasProvider = FutureProvider<List<CitaModel>>((ref) async {
  final res = await ref.watch(citaServiceProvider).listar(perPage: 100);
  return res.data;
});
