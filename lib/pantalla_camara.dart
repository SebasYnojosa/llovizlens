import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'pantalla_resultado.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PantallaCamara extends StatefulWidget {
  const PantallaCamara({super.key});

  @override
  State<PantallaCamara> createState() => _PantallaCamaraState();
}

class _PantallaCamaraState extends State<PantallaCamara> {
  File? _foto;
  final ImagePicker _picker = ImagePicker();
  bool _cargando = false;

  // Opciones de backend
  String _backendUrl = 'http://10.0.2.2:5000/predict';
  final TextEditingController _ipController = TextEditingController();
  final List<Map<String, String>> _opciones = [
    {'label': 'Emulador Android', 'url': 'http://10.0.2.2:5000/predict'},
    {'label': 'Dispositivo físico (localhost)', 'url': 'http://localhost:5000/predict'},
    {'label': 'IP personalizada', 'url': ''},
  ];
  int _opcionSeleccionada = 0;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.camera);
    if (imagen != null) {
      setState(() {
        _foto = File(imagen.path);
      });
      await _enviarFotoAlBackend(_foto!);
    }
  }

  Future<void> _enviarFotoAlBackend(File foto) async {
    setState(() {
      _cargando = true;
    });
    try {
      String url = _backendUrl;
      if (_opcionSeleccionada == 2) {
        // IP personalizada
        final ip = _ipController.text.trim();
        if (ip.isEmpty) {
          _mostrarError('Debes ingresar la IP del backend');
          setState(() { _cargando = false; });
          return;
        }
        url = 'http://$ip:5000/predict';
      }
      var uri = Uri.parse(url);
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', foto.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        var data = json.decode(respStr);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaResultado(
              nombreComun: data['nombre_comun'] ?? 'Desconocido',
              nombreCientifico: data['nombre_cientifico'] ?? '',
              foto: foto,
            ),
          ),
        );
      } else {
        _mostrarError('Error del backend: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarError('Error de conexión: $e');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cámara'),
      ),
      body: Center(
        child: _cargando
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Selector de backend
                    const Text('Selecciona el entorno del backend:', style: TextStyle(fontWeight: FontWeight.bold)),
                    for (int i = 0; i < _opciones.length; i++)
                      ListTile(
                        title: Text(_opciones[i]['label']!),
                        leading: Radio<int>(
                          value: i,
                          groupValue: _opcionSeleccionada,
                          onChanged: (int? value) {
                            setState(() {
                              _opcionSeleccionada = value!;
                              if (i < 2) {
                                _backendUrl = _opciones[i]['url']!;
                              }
                            });
                          },
                        ),
                        trailing: i == 2
                            ? SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: _ipController,
                                  enabled: _opcionSeleccionada == 2,
                                  decoration: const InputDecoration(
                                    hintText: 'IP del backend',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              )
                            : null,
                      ),
                    const Divider(),
                    _foto != null
                        ? Image.file(_foto!, width: 200, height: 200)
                        : const Icon(Icons.camera_alt, size: 100),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _tomarFoto,
                      child: const Text('Tomar foto'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
