import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class ProcesadorIAAmazonas {
  Interpreter? _interpreter;
  List<String> _categorias = [];
  bool _modeloCargado = false;
  List<int>? _inputShape;
  List<int>? _outputShape;

  // Getters
  bool get modeloCargado => _modeloCargado;
  List<String> get categorias => _categorias;
  List<int>? get inputShape => _inputShape;
  List<int>? get outputShape => _outputShape;

  /// Carga el modelo TFLite y las etiquetas
  Future<void> cargarModelo() async {
    try {
      print('🔄 Cargando modelo del Amazonas...');
      
      // 1. Cargar el modelo TFLite
      _interpreter = await Interpreter.fromAsset('assets/model/model.tflite');
      
      // 2. Obtener información del modelo
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;
      
      print('📊 Forma de entrada: $_inputShape');
      print('📊 Forma de salida: $_outputShape');
      
      // 3. Cargar etiquetas
      await _cargarEtiquetas();
      
      _modeloCargado = true;
      print('✅ Modelo del Amazonas cargado exitosamente!');
      print('🌿 Especies disponibles: ${_categorias.length}');
      
    } catch (e) {
      print('❌ Error cargando modelo: $e');
      _modeloCargado = false;
      rethrow;
    }
  }

  /// Carga las etiquetas desde labels.txt
  Future<void> _cargarEtiquetas() async {
    try {
      // Leer el archivo labels.txt
      final String labelsString = await rootBundle.loadString('assets/model/labels.txt');
      
      // Dividir por líneas y limpiar espacios en blanco
      _categorias = labelsString
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      
      print('📝 Etiquetas cargadas: ${_categorias.length} especies');
      for (int i = 0; i < _categorias.length; i++) {
        print('   ${i + 1}. ${_categorias[i]}');
      }
      
    } catch (e) {
      print('❌ Error cargando etiquetas: $e');
      // Usar etiquetas por defecto si hay error
      _categorias = [
        'Apamates', 'Araguaney', 'Araguato', 'Ave del paraíso', 'Azulejo',
        'Baba', 'Baquiro', 'Cachicamo', 'Cari cari', 'Cereza',
        'Chiguire', 'Culebra', 'Curí', 'Falsa coral', 'Indio desnudo',
        'Lapa', 'Lora', 'Loro real', 'Monos capuchino', 'Morocoto',
        'Morrocoy', 'Nutria gigante', 'Orquídeas', 'Pavón', 'Payara',
        'Pereza', 'Roble', 'Sapito minero', 'Tucan', 'Turpial', 'Uva playera'
      ];
    }
  }

  /// Procesa una imagen y retorna la predicción
  Future<Map<String, dynamic>> procesarImagen(File imagen) async {
    if (!_modeloCargado || _interpreter == null) {
      throw Exception('Modelo no cargado. Llama a cargarModelo() primero.');
    }

    try {
      print('🔄 Procesando imagen...');
      
      // 1. Preprocesar la imagen
      final tensor = await _preprocesarImagen(imagen);
      
      // 2. Preparar tensores de entrada y salida
      final input = [tensor];
      final output = List.filled(_outputShape![0] * _outputShape![1], 0.0).reshape(_outputShape!);
      
      // 3. Ejecutar inferencia
      _interpreter!.run(input, output);
      
      // 4. Procesar resultados
      final resultados = _procesarResultados(output[0] as List<double>);
      
      print('✅ Procesamiento completado');
      return resultados;
      
    } catch (e) {
      print('❌ Error procesando imagen: $e');
      rethrow;
    }
  }

  /// Preprocesa la imagen para el modelo
  Future<List<List<List<double>>>> _preprocesarImagen(File imagen) async {
    try {
      // 1. Leer bytes de la imagen
      final bytes = await imagen.readAsBytes();
      
      // 2. Decodificar imagen
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('No se pudo decodificar la imagen');
      
      // 3. Obtener tamaño objetivo del modelo
      final targetSize = _inputShape![1]; // Asumiendo forma [1, height, width, 3]
      
      // 4. Redimensionar imagen
      final resized = img.copyResize(image, width: targetSize, height: targetSize);
      
      // 5. Convertir a tensor normalizado
      List<List<List<double>>> tensor = List.generate(
        targetSize,
        (y) => List.generate(
          targetSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0, // R
              pixel.g / 255.0, // G
              pixel.b / 255.0, // B
            ];
          },
        ),
      );
      
      print('📐 Imagen redimensionada a ${targetSize}x${targetSize}');
      return tensor;
      
    } catch (e) {
      print('❌ Error preprocesando imagen: $e');
      rethrow;
    }
  }

  /// Procesa los resultados de la inferencia
  Map<String, dynamic> _procesarResultados(List<double> predicciones) {
    try {
      // Aplicar softmax para normalizar las probabilidades
      final probabilidades = _aplicarSoftmax(predicciones);
      
      // Encontrar las 3 predicciones con mayor confianza
      List<MapEntry<int, double>> prediccionesConIndices = [];
      
      for (int i = 0; i < probabilidades.length; i++) {
        prediccionesConIndices.add(MapEntry(i, probabilidades[i]));
      }
      
      // Ordenar por confianza descendente
      prediccionesConIndices.sort((a, b) => b.value.compareTo(a.value));
      
      // Obtener top 3 predicciones
      final top3 = prediccionesConIndices.take(3).toList();
      
      // Especie principal
      final especiePrincipal = _categorias[top3[0].key];
      final confianzaPrincipal = top3[0].value * 100;
      
      // Crear resultado detallado
      final resultado = {
        'especie': especiePrincipal,
        'confianza': confianzaPrincipal,
        'indice': top3[0].key,
        'top3_predicciones': top3.map((pred) => {
          'especie': _categorias[pred.key],
          'confianza': pred.value * 100,
          'indice': pred.key,
        }).toList(),
        'todas_predicciones': probabilidades.asMap().map(
          (i, conf) => MapEntry(_categorias[i], conf * 100)
        ),
        'timestamp': DateTime.now().toIso8601String(),
        'total_especies': _categorias.length,
      };
      
      print('🌿 Especie identificada: $especiePrincipal (${confianzaPrincipal.toStringAsFixed(1)}%)');
      print('🏆 Top 3 predicciones:');
      for (int i = 0; i < top3.length; i++) {
        final pred = top3[i];
        print('   ${i + 1}. ${_categorias[pred.key]} (${(pred.value * 100).toStringAsFixed(1)}%)');
      }
      
      return resultado;
      
    } catch (e) {
      print('❌ Error procesando resultados: $e');
      rethrow;
    }
  }

  /// Aplica softmax para normalizar las probabilidades
  List<double> _aplicarSoftmax(List<double> logits) {
    // Encontrar el máximo para evitar overflow
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    
    // Calcular exponenciales
    final exponenciales = logits.map((logit) => (logit - maxLogit)).map((x) => exp(x)).toList();
    
    // Calcular suma
    final suma = exponenciales.reduce((a, b) => a + b);
    
    // Normalizar
    return exponenciales.map((exp) => exp / suma).toList();
  }

  /// Libera recursos del modelo
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _modeloCargado = false;
  }
} 