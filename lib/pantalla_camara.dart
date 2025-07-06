import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'pantalla_resultado.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class PantallaCamara extends StatefulWidget {
  const PantallaCamara({super.key});

  @override
  State<PantallaCamara> createState() => _PantallaCamaraState();
}

class _PantallaCamaraState extends State<PantallaCamara> {
  File? _foto;
  final ImagePicker _picker = ImagePicker();
  bool _cargando = false;
  String? _error;
  Interpreter? _interpreter;
  List<String> _categorias = [];
  Map<String, dynamic>? _metadata;

  @override
  void initState() {
    super.initState();
    _cargarModelo();
  }

  Future<void> _cargarModelo() async {
    try {
      // Cargar metadata del modelo
      await _cargarMetadata();
      
      // Por ahora, simulamos que el modelo está cargado
      // En producción, cargarías el modelo real:
      // _interpreter = await Interpreter.fromAsset('model/tu_modelo.tflite');
      
      print('Metadata cargada exitosamente');
      print('Categorías disponibles: $_categorias');
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el modelo IA: $e';
      });
      print('Error cargando modelo: $e');
    }
  }

  Future<void> _cargarMetadata() async {
    try {
      // Cargar metadata desde assets
      final metadataString = await DefaultAssetBundle.of(context)
          .loadString('model/metadata_modelo.json');
      _metadata = json.decode(metadataString);
      _categorias = List<String>.from(_metadata!['categorias']);
    } catch (e) {
      print('Error cargando metadata: $e');
      // Usar categorías por defecto si no se puede cargar metadata
      _categorias = ['rosa', 'girasol', 'tulipan', 'margarita', 'lirio'];
    }
  }

  Future<void> _solicitarPermisoYTomarFoto() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        _mostrarError('Permiso denegado', 'La app necesita acceso a la cámara para funcionar.');
        return;
      }
    }
    await _tomarFoto();
  }

  Future<void> _tomarFoto() async {
    try {
      setState(() {
        _error = null;
        _cargando = true;
      });
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (imagen != null) {
        setState(() {
          _foto = File(imagen.path);
          _cargando = false;
        });
        await _procesarFotoIA(_foto!);
      } else {
        setState(() {
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _cargando = false;
        _error = 'Error al abrir la cámara: $e';
      });
      _mostrarError('Error al abrir la cámara', 'No se pudo acceder a la cámara. Verifica los permisos de la aplicación.');
    }
  }

  Future<void> _procesarFotoIA(File foto) async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    
    try {
      if (_categorias.isEmpty) {
        throw Exception('No se pudieron cargar las categorías del modelo.');
      }

      // Simular procesamiento de IA
      await Future.delayed(const Duration(seconds: 2));
      
      // Simular resultado aleatorio
      final random = DateTime.now().millisecondsSinceEpoch;
      final indiceAleatorio = random % _categorias.length;
      final categoria = _categorias[indiceAleatorio];
      final confianza = 70.0 + (random % 30); // Entre 70% y 100%
      
      // Navegar a la pantalla de resultado
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaResultado(
              nombreComun: categoria.toUpperCase(),
              nombreCientifico: 'Confianza: ${confianza.toStringAsFixed(1)}% (Simulado)',
              foto: foto,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
      
      String titulo = 'Error de IA';
      String mensaje = e.toString();
      
      if (e.toString().contains('categorías')) {
        titulo = 'Error de configuración';
        mensaje = 'No se pudieron cargar las categorías del modelo. Verifica el archivo metadata_modelo.json';
      }
      
      _mostrarError(titulo, mensaje);
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<List<List<List<double>>>> _prepararImagen(File imagen) async {
    // Cargar imagen usando dart:io
    final bytes = await imagen.readAsBytes();
    
    // Convertir bytes a imagen y redimensionar
    // Nota: Esta es una implementación simplificada
    // En producción, deberías usar un paquete como image para procesar la imagen
    
    // Por ahora, creamos un tensor de ejemplo
    // En realidad, deberías:
    // 1. Cargar la imagen
    // 2. Redimensionar a 224x224
    // 3. Normalizar valores (dividir por 255)
    // 4. Convertir a tensor
    
    // Tensor de ejemplo (224x224x3)
    List<List<List<double>>> tensor = List.generate(
      224,
      (i) => List.generate(
        224,
        (j) => List.generate(3, (k) => 0.5), // Valores normalizados
      ),
    );
    
    return tensor;
  }

  void _mostrarError(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensaje),
            const SizedBox(height: 10),
            const Text(
              'Sugerencias:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Verifica que metadata_modelo.json esté en assets/model/'),
            const Text('• Para IA real, ejecuta crear_modelo_ejemplo.py'),
            const Text('• Intenta tomar otra foto'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Llovizlens - Cámara'),
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
        child: Center(
          child: _cargando
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    const Text(
                      'Procesando imagen...',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Esto puede tomar unos segundos',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                        child: _foto != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  _foto!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 80,
                                    color: Colors.green[400],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Toca para tomar una foto',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: _solicitarPermisoYTomarFoto,
                          icon: const Icon(Icons.camera_alt, size: 24),
                          label: const Text(
                            'Tomar Foto',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_categorias.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue[600]),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Modelo IA Simulado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Categorías: ${_categorias.join(', ')}',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[600]),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red[800]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
