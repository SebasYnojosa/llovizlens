import 'package:flutter/material.dart';
import 'dart:io';

class PantallaResultado extends StatelessWidget {
  final String nombreComun;
  final String nombreCientifico;
  final File? foto;
  final Map<String, dynamic>? resultadoCompleto;

  const PantallaResultado({
    super.key,
    required this.nombreComun,
    required this.nombreCientifico,
    this.foto,
    this.resultadoCompleto,
  });

  /// Extrae el valor de confianza del nombre científico
  double _getConfianza() {
    try {
      final match = RegExp(r'Confianza: (\d+\.?\d*)%').firstMatch(nombreCientifico);
      if (match != null) {
        return double.parse(match.group(1)!);
      }
    } catch (e) {
      // Si no se puede parsear, asumir confianza media
    }
    return 50.0;
  }

  /// Retorna el icono apropiado basado en la confianza
  IconData _getConfianzaIcon() {
    final confianza = _getConfianza();
    if (confianza >= 80.0) return Icons.eco;
    if (confianza >= 60.0) return Icons.help_outline;
    return Icons.warning_amber;
  }

  /// Retorna el color apropiado basado en la confianza
  Color _getConfianzaColor() {
    final confianza = _getConfianza();
    if (confianza >= 80.0) return Colors.green[600]!;
    if (confianza >= 60.0) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado - Especies del Amazonas'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagen
              if (foto != null)
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      foto!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              
              const SizedBox(height: 30),
              
              // Resultado principal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Icono basado en confianza
                    Icon(
                      _getConfianzaIcon(),
                      size: 50,
                      color: _getConfianzaColor(),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      nombreComun,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      nombreCientifico,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    // Mostrar consejos si la confianza es baja
                    if (_getConfianza() < 70.0) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.orange[600], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Confianza baja. Intenta tomar la foto con mejor iluminación y enfoque.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              

              
              const SizedBox(height: 30),
              
              // Botón volver
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.popUntil(context, ModalRoute.withName('/'));
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Volver al Inicio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 