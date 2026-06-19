import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../servicios/models/servicio_model.dart';

final sitioServiciosProvider = FutureProvider<List<ServicioModel>>((ref) async {
  final client = ref.read(apiClientProvider);
  final res = await client.get<Map<String, dynamic>>(
    ApiConstants.publicoServicios,
    queryParameters: {'page': 1, 'per_page': 100},
    fromJson: (j) => j as Map<String, dynamic>,
  );
  final page = PaginatedResponse.fromJson(res.data!, ServicioModel.fromJson);
  return page.data.where((s) => s.activo).toList();
});

class SitioServiciosPage extends ConsumerWidget {
  const SitioServiciosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sitioServiciosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/sitio'),
        ),
      ),
      body: async.when(
        data: (items) => GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 380,
            mainAxisExtent: 228,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _ServicioCard(servicio: items[i]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Servicios no disponibles')),
      ),
    );
  }
}

class _ServicioCard extends StatelessWidget {
  const _ServicioCard({required this.servicio});

  final ServicioModel servicio;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _abrirReserva(context),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.content_cut,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      servicio.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Text(
                  servicio.descripcion?.isNotEmpty == true
                      ? servicio.descripcion!
                      : '${servicio.duracion} min',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    Formatters.currency(servicio.precio),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _abrirReserva(context),
                    icon: const Icon(Icons.event_available),
                    label: const Text('Reservar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirReserva(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DisponibilidadSheet(servicio: servicio),
    );
  }
}

class _DisponibilidadSheet extends ConsumerStatefulWidget {
  const _DisponibilidadSheet({required this.servicio});

  final ServicioModel servicio;

  @override
  ConsumerState<_DisponibilidadSheet> createState() =>
      _DisponibilidadSheetState();
}

class _DisponibilidadSheetState extends ConsumerState<_DisponibilidadSheet> {
  final _fecha = TextEditingController();
  final _hora = TextEditingController(text: '09:00');
  bool _checking = false;
  String? _message;
  bool _available = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(days: 1));
    _fecha.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _fecha.dispose();
    _hora.dispose();
    super.dispose();
  }

  Future<void> _consultar() async {
    setState(() {
      _checking = true;
      _message = null;
      _available = false;
    });
    try {
      await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>(
            ApiConstants.publicoDisponibilidad,
            queryParameters: {
              'servicio_id': widget.servicio.idServicio,
              'fecha': _fecha.text.trim(),
              'hora': _hora.text.trim(),
            },
            fromJson: (j) => j as Map<String, dynamic>,
          );
      setState(() {
        _available = true;
        _message = 'Horario disponible';
      });
    } catch (_) {
      setState(() {
        _message = 'No hay disponibilidad para ese horario';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.servicio.nombre,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fecha,
            decoration: const InputDecoration(
              labelText: 'Fecha',
              prefixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hora,
            decoration: const InputDecoration(
              labelText: 'Hora',
              prefixIcon: Icon(Icons.schedule),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 14),
            Text(
              _message!,
              style: TextStyle(
                color: _available
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _checking ? null : _consultar,
              icon: Icon(_checking ? Icons.hourglass_empty : Icons.search),
              label: Text(
                _checking ? 'Consultando...' : 'Consultar disponibilidad',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
