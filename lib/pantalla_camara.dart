import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'pantalla_resultado.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'procesador_ia_amazonas.dart';

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
  final ProcesadorIAAmazonas _procesador = ProcesadorIAAmazonas();
  List<String> _categorias = [];

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    try {
      // Cargar modelo del Amazonas
      await _procesador.cargarModelo();
      
      // Obtener categorías
      _categorias = _procesador.categorias;
      
      // Verificar permisos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verificarPermisos();
      });
      
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el modelo del Amazonas: $e';
      });
      print('❌ Error inicializando app: $e');
    }
  }

  Future<void> _verificarPermisos() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          _mostrarError(
            'Permiso de cámara requerido',
            'La aplicación necesita acceso a la cámara para identificar especies del Amazonas. Por favor, concede el permiso en la configuración.',
          );
        }
        return;
      }
    }
    
    // Si los permisos están concedidos, mostrar mensaje de éxito
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cámara lista! Toca el botón para tomar una foto'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _solicitarPermisoYTomarFoto() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        _mostrarError(
          'Permiso de cámara requerido',
          'La aplicación necesita acceso a la cámara para identificar especies del Amazonas. Por favor, concede el permiso en la configuración.',
        );
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
      
      // Mostrar mensaje de preparación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abriendo cámara...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (imagen != null) {
        setState(() {
          _foto = File(imagen.path);
        });
        
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Foto tomada! Procesando con IA...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Procesar automáticamente la foto
        await _procesarFotoIA(_foto!);
      } else {
        setState(() {
          _cargando = false;
        });
        // Mostrar mensaje si se canceló
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se tomó ninguna foto'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _cargando = false;
        _error = 'Error al abrir la cámara: $e';
      });
      _mostrarError(
        'Error al abrir la cámara',
        'No se pudo acceder a la cámara. Verifica los permisos de la aplicación o reinicia la app.',
      );
    }
  }

  Future<void> _procesarFotoIA(File foto) async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    
    try {
      if (!_procesador.modeloCargado) {
        throw Exception('Modelo del Amazonas no está cargado.');
      }

      // Procesar con IA real
      final resultado = await _procesador.procesarImagen(foto);
      
      // Navegar a la pantalla de resultado
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaResultado(
              nombreComun: resultado['especie'],
              nombreCientifico: 'Confianza: ${resultado['confianza'].toStringAsFixed(1)}%',
              foto: foto,
              resultadoCompleto: resultado,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
      
      _mostrarError('Error de IA del Amazonas', e.toString());
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
            const Text('• Verifica que model.tflite esté en assets/model/'),
            const Text('• Verifica que labels.txt esté en assets/model/'),
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
                      GestureDetector(
                        onTap: _solicitarPermisoYTomarFoto,
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.green[200]!,
                              width: 3,
                            ),
                          ),
                          child: _foto != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Stack(
                                    children: [
                                      Image.file(
                                        _foto!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Toca para nueva foto',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 80,
                                        color: Colors.green[600],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Toca para identificar',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'una especie del Amazonas',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
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
                                    'Modelo IA del Amazonas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Especies disponibles: ${_categorias.length}',
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

  @override
  void dispose() {
    _procesador.dispose();
    super.dispose();
  }
}
