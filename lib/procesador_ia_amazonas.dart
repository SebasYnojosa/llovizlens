import 'dart:io';
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

  /// Método de inicialización (alias para cargarModelo)
  Future<void> inicializar() async {
    await cargarModelo();
  }

  /// Carga el modelo TFLite y las etiquetas
  Future<void> cargarModelo() async {
    try {
      print('🔄 Cargando modelo del Amazonas...');
      _interpreter = await Interpreter.fromAsset('assets/model/model.tflite');
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;
      print('📊 Forma de entrada: [32m$_inputShape[0m');
      print('📊 Forma de salida: [32m$_outputShape[0m');
      await _cargarEtiquetas();
      _verificarCompatibilidad();
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
      final String labelsString = await rootBundle.loadString('assets/model/labels.txt');
      _categorias = labelsString
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      print('📝 Etiquetas cargadas: ${_categorias.length} especies');
      for (int i = 0; i < _categorias.length; i++) {
        print('   ${i + 1}. ${_categorias[i]}');
      }
      if (_outputShape != null && _categorias.length != _outputShape![1]) {
        print('⚠️  ADVERTENCIA: Número de etiquetas (${_categorias.length}) no coincide con la salida del modelo (${_outputShape![1]})');
      }
    } catch (e) {
      print('❌ Error cargando etiquetas: $e');
      _categorias = [
        'Apamates', 'Araguaney', 'Araguato', 'Ave del paraíso', 'Azulejo',
        'Baba', 'Baquiro', 'Cachicamo', 'Cari cari', 'Cereza',
        'Chiguire', 'Culebra', 'Curí', 'Falsa coral', 'Indio desnudo (Arbol)',
        'Lapa', 'Lora', 'Loro real', 'Monos capuchino', 'Morocoto',
        'Morrocoy', 'Nutria gigante', 'Orquídeas', 'Pavón', 'Payara',
        'Pereza', 'Roble', 'Sapito minero', 'Tucan', 'Turpial', 'Uva playera'
      ];
      print('📝 Usando etiquetas por defecto: ${_categorias.length} especies');
    }
  }

  /// Procesa una imagen y retorna la predicción
  Future<Map<String, dynamic>> procesarImagen(File imagen) async {
    if (!_modeloCargado || _interpreter == null) {
      throw Exception('Modelo no cargado. Llama a cargarModelo() primero.');
    }
    try {
      print('🔄 Procesando imagen...');
      final tensor = await _preprocesarImagen(imagen);
      final input = [tensor];
      final output = List.generate(_outputShape![0], (i) => List.generate(_outputShape![1], (j) => 0.0));
      _interpreter!.run(input, output);
      final rawOutput = (output[0] as List).cast<double>();
      print('🔍 Valores raw del modelo:');
      print('   - Mínimo: ${rawOutput.reduce((a, b) => a < b ? a : b).toStringAsFixed(3)}');
      print('   - Máximo: ${rawOutput.reduce((a, b) => a > b ? a : b).toStringAsFixed(3)}');
      print('   - Promedio: ${(rawOutput.reduce((a, b) => a + b) / rawOutput.length).toStringAsFixed(3)}');
      List<MapEntry<int, double>> rawWithIndices = [];
      for (int i = 0; i < rawOutput.length; i++) {
        rawWithIndices.add(MapEntry(i, rawOutput[i]));
      }
      rawWithIndices.sort((a, b) => b.value.compareTo(a.value));
      print('   - Top 5 valores raw:');
      for (int i = 0; i < 5 && i < rawWithIndices.length; i++) {
        final entry = rawWithIndices[i];
        final nombreEspecie = entry.key < _categorias.length 
            ? _categorias[entry.key] 
            : 'Especie_${entry.key}';
        print('     ${i + 1}. $nombreEspecie: ${entry.value.toStringAsFixed(3)}');
      }
      final resultados = _procesarResultados(rawOutput);
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
      final bytes = await imagen.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('No se pudo decodificar la imagen');
      print('📸 Imagen original: ${image.width}x${image.height}');
      final targetSize = _inputShape![1];
      final resized = img.copyResize(image, width: targetSize, height: targetSize);
      List<List<List<double>>> tensor = List.generate(
        targetSize,
        (y) => List.generate(
          targetSize,
                      (x) {
              final pixel = resized.getPixel(x, y);
              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
        ),
      );
      double minVal = 1.0;
      double maxVal = 0.0;
      double sumVal = 0.0;
      int totalPixels = 0;
      for (int y = 0; y < targetSize; y++) {
        for (int x = 0; x < targetSize; x++) {
          for (int c = 0; c < 3; c++) {
            final val = tensor[y][x][c];
            if (val < minVal) minVal = val;
            if (val > maxVal) maxVal = val;
            sumVal += val;
            totalPixels++;
          }
        }
      }
      final promedio = sumVal / totalPixels;
      print('📐 Imagen redimensionada a ${targetSize}x${targetSize}');
      print('📊 Estadísticas de píxeles:');
      print('   - Mínimo: ${minVal.toStringAsFixed(3)}');
      print('   - Máximo: ${maxVal.toStringAsFixed(3)}');
      print('   - Promedio: ${promedio.toStringAsFixed(3)}');
      if (promedio < 0.1) {
        print('⚠️  ADVERTENCIA: Imagen muy oscura (promedio < 0.1)');
      } else if (promedio > 0.9) {
        print('⚠️  ADVERTENCIA: Imagen muy clara (promedio > 0.9)');
      }
      final contraste = maxVal - minVal;
      if (contraste < 0.1) {
        print('⚠️  ADVERTENCIA: Imagen con poco contraste (${contraste.toStringAsFixed(3)})');
      }
      return tensor;
    } catch (e) {
      print('❌ Error preprocesando imagen: $e');
      rethrow;
    }
  }

  /// Procesa los resultados de la inferencia
  Map<String, dynamic> _procesarResultados(List<double> predicciones) {
    try {
      final probabilidades = _aplicarSoftmax(predicciones);
      List<MapEntry<int, double>> prediccionesConIndices = [];
      for (int i = 0; i < probabilidades.length; i++) {
        prediccionesConIndices.add(MapEntry(i, probabilidades[i]));
      }
      prediccionesConIndices.sort((a, b) => b.value.compareTo(a.value));
      final top3 = prediccionesConIndices.take(3).toList();
      final especiePrincipal = top3[0].key < _categorias.length 
          ? _categorias[top3[0].key] 
          : 'Especie_${top3[0].key}';
      final confianzaPrincipal = top3[0].value * 100;
      final resultado = {
        'especie': especiePrincipal,
        'confianza': confianzaPrincipal,
        'indice': top3[0].key,
        'top3_predicciones': top3.map((pred) {
          final nombreEspecie = pred.key < _categorias.length 
              ? _categorias[pred.key] 
              : 'Especie_${pred.key}';
          return {
            'especie': nombreEspecie,
            'confianza': pred.value * 100,
            'indice': pred.key,
          };
        }).toList(),
        'todas_predicciones': probabilidades.asMap().map(
          (i, conf) {
            final nombreEspecie = i < _categorias.length 
                ? _categorias[i] 
                : 'Especie_$i';
            return MapEntry(nombreEspecie, conf * 100);
          }
        ),
        'timestamp': DateTime.now().toIso8601String(),
        'total_especies': _categorias.length,
        'total_clases_modelo': probabilidades.length,
      };
      print('🌿 Especie identificada: $especiePrincipal (${confianzaPrincipal.toStringAsFixed(1)}%)');
      print('🏆 Top 3 predicciones:');
      for (int i = 0; i < top3.length; i++) {
        final pred = top3[i];
        final nombreEspecie = pred.key < _categorias.length 
            ? _categorias[pred.key] 
            : 'Especie_${pred.key}';
        print('   ${i + 1}. $nombreEspecie (${(pred.value * 100).toStringAsFixed(1)}%)');
      }
      return resultado;
    } catch (e) {
      print('❌ Error procesando resultados: $e');
      rethrow;
    }
  }

  /// Verifica la compatibilidad entre el modelo y las etiquetas
  void _verificarCompatibilidad() {
    if (_outputShape == null || _categorias.isEmpty) {
      throw Exception('Modelo o etiquetas no cargados correctamente');
    }
    final numClases = _outputShape![1];
    final numEtiquetas = _categorias.length;
    print('🔍 Verificando compatibilidad:');
    print('   - Clases del modelo: $numClases');
    print('   - Etiquetas disponibles: $numEtiquetas');
    if (numClases != numEtiquetas) {
      print('⚠️  ADVERTENCIA: El número de clases del modelo ($numClases) no coincide con el número de etiquetas ($numEtiquetas)');
      print('   - Esto puede causar errores en las predicciones');
      if (numClases < numEtiquetas) {
        print('   - Recortando etiquetas a $numClases');
        _categorias = _categorias.take(numClases).toList();
      } else if (numClases > numEtiquetas) {
        print('   - Agregando etiquetas faltantes');
        for (int i = numEtiquetas; i < numClases; i++) {
          _categorias.add('Especie_$i');
        }
      }
    } else {
      print('✅ Compatibilidad verificada correctamente');
    }
  }

  /// Aplica softmax para normalizar las probabilidades
  List<double> _aplicarSoftmax(List<double> logits) {
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final exponenciales = logits.map((logit) => (logit - maxLogit)).map((x) => exp(x)).toList();
    final suma = exponenciales.reduce((a, b) => a + b);
    return exponenciales.map((exp) => exp / suma).toList();
  }

  /// Libera recursos del modelo
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _modeloCargado = false;
  }
} 