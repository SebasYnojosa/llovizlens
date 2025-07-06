import 'package:flutter/material.dart';

class PantallaCatalogo extends StatelessWidget {
  const PantallaCatalogo({super.key});

  static final List<Map<String, String>> especies = [
    {
      'nombreComun': 'Apamates',
      'nombreCientifico': 'Tabebuia rosea',
      'descripcion': 'Árbol nativo de América tropical, conocido por sus flores rosadas y corteza medicinal.'
    },
    {
      'nombreComun': 'Araguaney',
      'nombreCientifico': 'Handroanthus chrysanthus',
      'descripcion': 'Árbol nacional de Venezuela, famoso por sus flores amarillas que florecen en primavera.'
    },
    {
      'nombreComun': 'Araguato',
      'nombreCientifico': 'Alouatta seniculus',
      'descripcion': 'Mono aullador rojo, habitante de los bosques del Amazonas. Se caracteriza por su fuerte aullido.'
    },
    {
      'nombreComun': 'Ave del paraíso',
      'nombreCientifico': 'Strelitzia reginae',
      'descripcion': 'Planta ornamental con flores exóticas que se asemejan a un pájaro en vuelo.'
    },
    {
      'nombreComun': 'Azulejo',
      'nombreCientifico': 'Thraupis episcopus',
      'descripcion': 'Ave pequeña de color azul, común en jardines y áreas urbanas del Amazonas.'
    },
    {
      'nombreComun': 'Baba',
      'nombreCientifico': 'Caiman crocodilus',
      'descripcion': 'Cocodrilo de tamaño mediano, habitante de ríos y lagunas del Amazonas.'
    },
    {
      'nombreComun': 'Baquiro',
      'nombreCientifico': 'Tayassu pecari',
      'descripcion': 'Cerdo salvaje del Amazonas, vive en grupos y se alimenta de frutos y raíces.'
    },
    {
      'nombreComun': 'Cachicamo',
      'nombreCientifico': 'Dasypus novemcinctus',
      'descripcion': 'Armadillo de nueve bandas, mamífero con caparazón óseo característico.'
    },
    {
      'nombreComun': 'Cari cari',
      'nombreCientifico': 'Caracara cheriway',
      'descripcion': 'Ave rapaz carroñera, se alimenta de carroña y pequeños animales.'
    },
    {
      'nombreComun': 'Cereza',
      'nombreCientifico': 'Malpighia emarginata',
      'descripcion': 'Árbol frutal que produce cerezas ricas en vitamina C.'
    },
    {
      'nombreComun': 'Chiguire',
      'nombreCientifico': 'Hydrochoerus hydrochaeris',
      'descripcion': 'El roedor más grande del mundo, habita en ríos y lagunas del Amazonas.'
    },
    {
      'nombreComun': 'Culebra',
      'nombreCientifico': 'Serpentes spp.',
      'descripcion': 'Reptil sin patas, importante para el control de plagas en el ecosistema.'
    },
    {
      'nombreComun': 'Curí',
      'nombreCientifico': 'Cavia porcellus',
      'descripcion': 'Conejillo de indias, roedor doméstico originario de América del Sur.'
    },
    {
      'nombreComun': 'Falsa coral',
      'nombreCientifico': 'Lampropeltis triangulum',
      'descripcion': 'Serpiente no venenosa que imita el patrón de color de las serpientes coral.'
    },
    {
      'nombreComun': 'Indio desnudo (Arbol)',
      'nombreCientifico': 'Bursera simaruba',
      'descripcion': 'Árbol con corteza lisa y rojiza, conocido por sus propiedades medicinales.'
    },
    {
      'nombreComun': 'Lapa',
      'nombreCientifico': 'Agouti paca',
      'descripcion': 'Roedor grande del Amazonas, apreciado por su carne y piel.'
    },
    {
      'nombreComun': 'Lora',
      'nombreCientifico': 'Amazona spp.',
      'descripcion': 'Ave psitácida colorida, conocida por su capacidad de imitar sonidos.'
    },
    {
      'nombreComun': 'Loro real',
      'nombreCientifico': 'Amazona ochrocephala',
      'descripcion': 'Loro de tamaño mediano con plumaje verde y amarillo en la cabeza.'
    },
    {
      'nombreComun': 'Monos capuchino',
      'nombreCientifico': 'Cebus spp.',
      'descripcion': 'Monos inteligentes con pelaje oscuro y cara clara, muy sociales.'
    },
    {
      'nombreComun': 'Morocoto',
      'nombreCientifico': 'Piaractus brachypomus',
      'descripcion': 'Pez de agua dulce del Amazonas, importante para la pesca comercial.'
    },
    {
      'nombreComun': 'Morrocoy',
      'nombreCientifico': 'Chelonoidis carbonaria',
      'descripcion': 'Tortuga terrestre del Amazonas, se alimenta de frutos y vegetación.'
    },
    {
      'nombreComun': 'Nutria gigante',
      'nombreCientifico': 'Pteronura brasiliensis',
      'descripcion': 'La nutria más grande del mundo, excelente nadadora y pescadora.'
    },
    {
      'nombreComun': 'Orquídeas',
      'nombreCientifico': 'Orchidaceae spp.',
      'descripcion': 'Familia de plantas con flores exóticas, muy diversas en el Amazonas.'
    },
    {
      'nombreComun': 'Pavón',
      'nombreCientifico': 'Crax alector',
      'descripcion': 'Ave galliforme grande, conocida por su cresta y plumaje oscuro.'
    },
    {
      'nombreComun': 'Payara',
      'nombreCientifico': 'Hydrolycus scomberoides',
      'descripcion': 'Pez depredador del Amazonas, conocido por sus largos colmillos.'
    },
    {
      'nombreComun': 'Pereza',
      'nombreCientifico': 'Bradypus spp.',
      'descripcion': 'Mamífero arbóreo de movimiento lento, se alimenta principalmente de hojas.'
    },
    {
      'nombreComun': 'Roble',
      'nombreCientifico': 'Quercus spp.',
      'descripcion': 'Árbol de madera dura, importante para la construcción y ecosistema.'
    },
    {
      'nombreComun': 'Sapito minero',
      'nombreCientifico': 'Dendrobates spp.',
      'descripcion': 'Rana pequeña y colorida, algunas especies son venenosas.'
    },
    {
      'nombreComun': 'Tucan',
      'nombreCientifico': 'Ramphastos spp.',
      'descripcion': 'Ave con pico grande y colorido, símbolo de la biodiversidad amazónica.'
    },
    {
      'nombreComun': 'Turpial',
      'nombreCientifico': 'Icterus icterus',
      'descripcion': 'Ave nacional de Venezuela, de color negro y amarillo brillante.'
    },
    {
      'nombreComun': 'Uva playera',
      'nombreCientifico': 'Coccoloba uvifera',
      'descripcion': 'Árbol costero que produce frutos similares a uvas, resistente a la sal.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo - Especies del Amazonas'),
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${especies.length} Especies del Amazonas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: especies.length,
                itemBuilder: (context, index) {
                  final especie = especies[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Text(
                          especie['nombreComun']![0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        especie['nombreComun']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        especie['nombreCientifico']!,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: Text(
                                    especie['nombreComun']![0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    especie['nombreComun']!,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nombre científico:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  especie['nombreCientifico']!,
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 16,
                                    color: Colors.green[700],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Descripción:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  especie['descripcion']!,
                                  style: const TextStyle(fontSize: 14),
                                ),
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 