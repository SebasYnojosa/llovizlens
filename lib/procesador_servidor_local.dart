import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class ProcesadorServidorLocal {
  static const String _baseUrl = 'http://localhost:5000';
  
  bool _servidorConectado = false;
  List<String> _labels = [];
  Map<String, dynamic> _modeloInfo = {};

  // Getters
  bool get servidorConectado => _servidorConectado;
  List<String> get labels => _labels;
  Map<String, dynamic> get modeloInfo => _modeloInfo;

  /// Inicializa la conexión con el servidor local
  Future<void> inicializar() async {
    try {
      print('🔄 Conectando con servidor local...');
      
      // Verificar estado del servidor
      final response = await http.get(Uri.parse('$_baseUrl/health'))
          .timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _servidorConectado = data['modelo_cargado'] ?? false;
        
        if (_servidorConectado) {
          // Obtener información del modelo
          await _obtenerInformacionModelo();
          print('✅ Servidor local conectado exitosamente!');
          print('📊 Modelo 5D cargado y listo');
        } else {
          throw Exception('Modelo no cargado en el servidor');
        }
      } else {
        throw Exception('Servidor no responde correctamente');
      }
      
    } catch (e) {
      print('❌ Error conectando con servidor local: $e');
      print('💡 Asegúrate de ejecutar: python backend_flask/servidor_local_5d.py');
      rethrow;
    }
  }

  /// Obtiene información del modelo del servidor
  Future<void> _obtenerInformacionModelo() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/model_info'));
      
      if (response.statusCode == 200) {
        _modeloInfo = json.decode(response.body);
        _labels = List<String>.from(_modeloInfo['etiquetas'] ?? []);
        
        print('📊 Información del modelo:');
        print('   - Input shape: ${_modeloInfo['input_shape']}');
        print('   - Output shape: ${_modeloInfo['output_shape']}');
        print('   - Clases disponibles: ${_labels.length}');
      }
      
    } catch (e) {
      print('❌ Error obteniendo información del modelo: $e');
    }
  }

  /// Procesa una imagen usando el servidor local
  Future<Map<String, dynamic>> procesarImagen(File imagen) async {
    if (!_servidorConectado) {
      throw Exception('Servidor no conectado. Llama a inicializar() primero.');
    }

    try {
      print('🔄 Procesando imagen con servidor local...');
      
      // Crear request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/predict'),
      );
      
      // Agregar imagen al request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imagen.path,
        ),
      );
      
      // Enviar request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final resultado = json.decode(response.body);
        
        print('✅ Procesamiento completado con servidor local');
        
        // Mostrar resultado principal
        final confianza = resultado['confianza'] * 100.0;
        final clase = resultado['clase_predicha'];
        
        if (confianza >= 70.0) {
          print('🌿 Clase identificada: $clase (${confianza.toStringAsFixed(1)}%)');
        } else {
          print('❓ Confianza baja: $clase (${confianza.toStringAsFixed(1)}%) - Considera tomar otra foto');
        }
        
        return resultado;
        
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error en el servidor');
      }
      
    } catch (e) {
      print('❌ Error procesando imagen: $e');
      rethrow;
    }
  }

  /// Verifica el estado de la conexión
  Future<bool> verificarConexion() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'))
          .timeout(Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _servidorConectado = data['modelo_cargado'] ?? false;
        return _servidorConectado;
      }
      
      return false;
      
    } catch (e) {
      _servidorConectado = false;
      return false;
    }
  }

  /// Obtiene información detallada del modelo
  Map<String, dynamic> obtenerInformacionModelo() {
    return {
      'servidor_conectado': _servidorConectado,
      'url_servidor': _baseUrl,
      'modelo_info': _modeloInfo,
      'etiquetas_disponibles': _labels.length,
      'procesador': 'Servidor Local 5D',
    };
  }

  /// Libera recursos
  void dispose() {
    _servidorConectado = false;
    _labels.clear();
    _modeloInfo.clear();
  }
} 