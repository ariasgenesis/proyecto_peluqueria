import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SitioContactoPage extends StatelessWidget {
  const SitioContactoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/sitio'),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Visítanos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.location_on_outlined),
              title: Text('Dirección'),
              subtitle: Text('Calle Principal #123'),
            ),
            ListTile(
              leading: Icon(Icons.phone_outlined),
              title: Text('Teléfono'),
              subtitle: Text('+57 300 000 0000'),
            ),
            ListTile(
              leading: Icon(Icons.schedule_outlined),
              title: Text('Horario'),
              subtitle: Text('Lun - Sáb · 8:00 - 18:00'),
            ),
          ],
        ),
      ),
    );
  }
}
