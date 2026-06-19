import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/dialogs/app_confirm_dialog.dart';
import '../../../shared/dialogs/app_modal_sheet.dart';
import '../../../shared/dialogs/pin_confirm_dialog.dart';
import '../../../shared/layouts/admin_shell_layout.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../productos/models/producto_model.dart';
import '../../productos/services/producto_service.dart';
import '../../productos/widgets/producto_form_modal.dart';
import '../../../routes/route_names.dart';

final inventarioProvider = FutureProvider<List<ProductoModel>>((ref) async {
  final res = await ref.watch(productoServiceProvider).listar(perPage: 100);
  return res.data;
});

class InventarioPage extends ConsumerStatefulWidget {
  const InventarioPage({super.key});

  @override
  ConsumerState<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends ConsumerState<InventarioPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inventarioProvider);

    return AdminShellLayout(

      title: 'Inventario',
      currentRoute: RouteNames.inventario,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inventarioProvider);
          await ref.read(inventarioProvider.future);
        },
        child: async.when(
          loading: () => const AppLoading(message: 'Cargando inventario...'),
          error: (e, _) => EmptyState(
            title: 'No se pudo conectar',
            subtitle: '$e\n${ApiConstants.baseUrl}',
            icon: Icons.cloud_off,
          ),
          data: (items) {
          final filteredItems = items.where((p) {
            return p.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          final bajo = items.where((p) => p.stockBajo).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: const InputDecoration(
                          labelText: 'Buscar producto...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () => _openForm(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo Producto'),
                    ),
                  ],
                ),
              ),
              if (bajo.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text('${bajo.length} productos con stock bajo'),
                    ],
                  ),
                ),
              Expanded(
                child: filteredItems.isEmpty
                    ? const EmptyState(
                        title: 'No se encontraron productos',
                        icon: Icons.search_off,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredItems.length,
                        itemBuilder: (_, i) {
                          final p = filteredItems[i];
                          return Card(
                            child: ListTile(
                              onTap: () => _openForm(context, ref, p: p),
                              title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Stock: ${p.stock} / mín ${p.stockMinimo}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Agregar stock',
                                    icon: const Icon(Icons.add_circle_outline, color: AppColors.success),
                                    onPressed: () => _stock(context, ref, p, 'agregar'),
                                  ),
                                  IconButton(
                                    tooltip: 'Descontar stock',
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.warning),
                                    onPressed: () => _stock(context, ref, p, 'descontar'),
                                  ),
                                  const VerticalDivider(),
                                  IconButton(
                                    tooltip: 'Eliminar producto',
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                    onPressed: () => _eliminar(context, ref, p),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref, {ProductoModel? p}) async {
    final ok = await showAppModal<bool>(
      context,
      title: p == null ? 'Crear Producto' : 'Editar Producto',
      child: ProductoFormModal(
        producto: p,
        onSubmit: (model) async {
          try {
            final service = ref.read(productoServiceProvider);
            if (p == null) {
              await service.crear(model.toJson());
            } else {
              await service.actualizar(p.idProducto, model.toJson());
            }
            return true;
          } catch (e) {
            if (context.mounted) SnackbarUtils.error(context, e.toString());
            return false;
          }
        },
      ),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(inventarioProvider);
      SnackbarUtils.success(context, 'Producto guardado');
    }
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref, ProductoModel p) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Eliminar Producto',
      message: '¿Estás seguro de eliminar "${p.nombre}"? Esta acción no se puede deshacer.',
      destructive: true,
    );
    if (ok != true) return;

    try {
      await ref.read(productoServiceProvider).eliminar(p.idProducto);
      ref.invalidate(inventarioProvider);
      if (context.mounted) SnackbarUtils.success(context, 'Producto eliminado');
    } catch (e) {
      if (context.mounted) SnackbarUtils.error(context, e.toString());
    }
  }

  Future<void> _stock(
    BuildContext context,
    WidgetRef ref,
    ProductoModel p,
    String tipo,
  ) async {
    final pin = await showPinConfirmDialog(context);
    if (pin == null || !context.mounted) return;

    final cantidad = await showAppModal<int>(
      context,
      title: tipo == 'agregar' ? 'Agregar stock' : 'Descontar stock',
      child: _CantidadForm(),
    );
    if (cantidad == null || cantidad <= 0) return;

    final body = {...pin, 'cantidad': cantidad};
    try {
      final service = ref.read(productoServiceProvider);
      if (tipo == 'agregar') {
        await service.agregarStock(p.idProducto, body);
      } else {
        await service.descontarStock(p.idProducto, body);
      }
      ref.invalidate(inventarioProvider);
      if (context.mounted) SnackbarUtils.success(context, 'Stock actualizado');
    } catch (e) {
      if (context.mounted) SnackbarUtils.error(context, e.toString());
    }
  }
}

class _CantidadForm extends StatefulWidget {
  @override
  State<_CantidadForm> createState() => _CantidadFormState();
}

class _CantidadFormState extends State<_CantidadForm> {
  final _c = TextEditingController(text: '1');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Cantidad'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            final n = int.tryParse(_c.text);
            if (n != null) Navigator.pop(context, n);
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
