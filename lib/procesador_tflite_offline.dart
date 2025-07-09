import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ProcesadorTFLiteOffline {
  static const String _modelPath = 'assets/model/modeloV1.tflite';
  static const String _labelsPath = 'assets/model/labels.txt';
  
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _modeloCargado = false;
  int _inputSize = 224; // Tamaño de entrada del modelo
  int _numClasses = 19; // Número de clases (ajustar según tu modelo)

  // Getters
  bool get modeloCargado => _modeloCargado;
  List<String> get labels => _labels;
  int get inputSize => _inputSize;
  int get numClasses => _numClasses;

  /// Inicializa el procesador TensorFlow Lite
  Future<void> inicializar() async {
    try {
      print('🔄 Inicializando procesador TFLite offline...');
      
      // Cargar el modelo TensorFlow Lite
      await _cargarModelo();
      
      // Cargar las etiquetas
      await _cargarEtiquetas();
      
      _modeloCargado = true;
      print('✅ Procesador TFLite offline inicializado exitosamente!');
      print('🌿 Especies disponibles: ${_labels.length}');
      
    } catch (e) {
      print('❌ Error inicializando procesador TFLite: $e');
      rethrow;
    }
  }

  /// Carga el modelo TensorFlow Lite
  Future<void> _cargarModelo() async {
    try {
      print('📥 Cargando modelo TensorFlow Lite...');
      
      // Cargar desde assets
      _interpreter = await Interpreter.fromAsset(_modelPath);
      
      // Obtener información del modelo
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      
      // Configurar parámetros según el modelo
      _inputSize = inputTensor.shape[1]; // Asumiendo formato [1, height, width, 3]
      _numClasses = outputTensor.shape[1]; // Asumiendo formato [1, num_classes]
      
      print('📊 Información del modelo:');
      print('   - Tamaño de entrada:  [32m${_inputSize}x${_inputSize} [0m');
      print('   - Número de clases: $_numClasses');
      print('   - Tipo de entrada: ${inputTensor.type}');
      print('   - Tipo de salida: ${outputTensor.type}');
      
    } catch (e) {
      print('❌ Error cargando modelo: $e');
      rethrow;
    }
  }

  /// Carga las etiquetas desde el archivo
  Future<void> _cargarEtiquetas() async {
    try {
      print('📝 Cargando etiquetas...');
      
      final String labelsString = await rootBundle.loadString(_labelsPath);
      _labels = labelsString
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      
      print('📝 Etiquetas cargadas: ${_labels.length} especies');
      
    } catch (e) {
      print('❌ Error cargando etiquetas: $e');
      // Usar etiquetas por defecto
      _labels = List.generate(_numClasses, (index) => 'Class_$index');
      print('📝 Usando etiquetas por defecto: ${_labels.length} especies');
    }
  }

  /// Procesa una imagen usando TensorFlow Lite
  Future<Map<String, dynamic>> procesarImagen(File imagen) async {
    if (!_modeloCargado || _interpreter == null) {
      throw Exception('Procesador no inicializado. Llama a inicializar() primero.');
    }

    try {
      print('🔄 Procesando imagen con TFLite...');
      
      // Preprocesar la imagen
      final input = await _preprocesarImagen(imagen);
      
      // Preparar tensor de salida
      final output = [List.filled(_numClasses, 0.0)];
      // Ejecutar inferencia
      _interpreter!.run(input, output);
      // Procesar resultados
      final resultado = _procesarResultados(output[0]);
      
      print('✅ Procesamiento completado con TFLite');
      return resultado;
      
    } catch (e) {
      print('❌ Error procesando imagen: $e');
      rethrow;
    }
  }

  /// Preprocesa la imagen para el modelo
  Future<List<List<List<List<double>>>>> _preprocesarImagen(File imagen) async {
    try {
      // Leer la imagen
      final bytes = await imagen.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }
      
      // Redimensionar a la entrada del modelo
      final resizedImage = img.copyResize(
        image,
        width: _inputSize,
        height: _inputSize,
      );
      
      // Convertir a tensor normalizado [0, 1]
      final tensor = List.generate(
        1,
        (_) => List.generate(
          _inputSize,
          (y) => List.generate(
            _inputSize,
            (x) => List.generate(
              3,
              (c) {
                final pixel = resizedImage.getPixel(x, y);
                double value;
                switch (c) {
                  case 0: // R
                    value = pixel.r / 255.0;
                    break;
                  case 1: // G
                    value = pixel.g / 255.0;
                    break;
                  case 2: // B
                    value = pixel.b / 255.0;
                    break;
                  default:
                    value = 0.0;
                }
                return value;
              },
            ),
          ),
        ),
      );
      
      return tensor;
      
    } catch (e) {
      print('❌ Error preprocesando imagen: $e');
      rethrow;
    }
  }

  /// Procesa los resultados de la inferencia
  Map<String, dynamic> _procesarResultados(List<double> output) {
    try {
      // Encontrar la clase con mayor probabilidad
      int maxIndex = 0;
      double maxValue = output[0];
      
      for (int i = 1; i < output.length; i++) {
        if (output[i] > maxValue) {
          maxValue = output[i];
          maxIndex = i;
        }
      }
      
      // Calcular confianza como porcentaje
      final confianza = maxValue * 100.0;
      
      // Obtener nombre de la especie
      final especie = maxIndex < _labels.length 
          ? _labels[maxIndex] 
          : 'Desconocido';
      
      // Crear mapa de todas las predicciones
      final todasPredicciones = <String, double>{};
      for (int i = 0; i < output.length && i < _labels.length; i++) {
        todasPredicciones[_labels[i]] = output[i] * 100.0;
      }
      
      // Obtener top 5 predicciones
      final topPredictions = <Map<String, dynamic>>[];
      final sortedIndices = List<int>.generate(output.length, (i) => i)
        ..sort((a, b) => output[b].compareTo(output[a]));
      
      for (int i = 0; i < 5 && i < sortedIndices.length; i++) {
        final index = sortedIndices[i];
        if (index < _labels.length) {
          topPredictions.add({
            'especie': _labels[index],
            'confianza': output[index] * 100.0,
            'indice': index,
          });
        }
      }
      
      // Crear resultado
      final resultado = {
        'especie': especie,
        'confianza': confianza,
        'indice': maxIndex,
        'todas_predicciones': todasPredicciones,
        'timestamp': DateTime.now().toIso8601String(),
        'total_especies': _labels.length,
        'top_predictions': topPredictions,
        'procesado_por': 'TensorFlow Lite Offline',
      };
      
      // Mostrar resultado principal
      if (confianza >= 70.0) {
        print('🌿 Especie identificada: $especie (${confianza.toStringAsFixed(1)}%)');
      } else {
        print('❓ Confianza baja: $especie (${confianza.toStringAsFixed(1)}%) - Considera tomar otra foto');
      }
      
      return resultado;
      
    } catch (e) {
      print('❌ Error procesando resultados: $e');
      rethrow;
    }
  }

  /// Obtiene información del modelo
  Map<String, dynamic> obtenerInformacionModelo() {
    if (_interpreter == null) {
      return {'error': 'Modelo no cargado'};
    }
    
    try {
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      
      return {
        'modelo_cargado': true,
        'tamaño_entrada': _inputSize,
        'numero_clases': _numClasses,
        'especies_disponibles': _labels.length,
        'detalles_entrada': {
          'shape': inputTensor.shape,
          'type': inputTensor.type,
        },
        'detalles_salida': {
          'shape': outputTensor.shape,
          'type': outputTensor.type,
        },
        'procesador': 'TensorFlow Lite Offline',
      };
    } catch (e) {
      return {
        'error': 'Error obteniendo información: $e',
        'modelo_cargado': false,
      };
    }
  }

  /// Libera recursos
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _modeloCargado = false;
    _labels.clear();
  }
} 