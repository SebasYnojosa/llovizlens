import 'package:flutter/material.dart';
import 'dart:io';

class PantallaResultado extends StatelessWidget {
  final String nombreComun;
  final String nombreCientifico;
  final File? foto;

  const PantallaResultado({
    super.key,
    required this.nombreComun,
    required this.nombreCientifico,
    this.foto,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado IA Local'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (foto != null)
              Image.file(foto!, width: 200, height: 200),
            const SizedBox(height: 20),
            Text('Nombre común: $nombreComun', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text('Nombre científico: $nombreCientifico', style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
} 