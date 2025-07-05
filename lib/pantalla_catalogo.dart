import 'package:flutter/material.dart';

class PantallaCatalogo extends StatelessWidget {
  const PantallaCatalogo({super.key});

  static final List<Map<String, String>> especies = [
    {
      'nombreComun': 'Apamates',
      'nombreCientifico': 'Tabebuia rosea',
      'descripcion': 'Árbol nativo de América tropical, conocido por sus flores rosadas.'
    },
    {
      'nombreComun': 'Araguaney',
      'nombreCientifico': 'Handroanthus chrysanthus',
      'descripcion': 'Árbol nacional de Venezuela, famoso por sus flores amarillas.'
    },
    {
      'nombreComun': 'Araguato',
      'nombreCientifico': 'Alouatta seniculus',
      'descripcion': 'Mono aullador rojo, habitante de los bosques del Amazonas.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Especies'),
      ),
      body: ListView.builder(
        itemCount: especies.length,
        itemBuilder: (context, index) {
          final especie = especies[index];
          return ListTile(
            title: Text(especie['nombreComun']!),
            subtitle: Text(especie['nombreCientifico']!),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(especie['nombreComun']!),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nombre científico: ${especie['nombreCientifico']}'),
                      const SizedBox(height: 10),
                      Text(especie['descripcion']!),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 