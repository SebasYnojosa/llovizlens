import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

void main() async {
  print('🧪 Iniciando pruebas del modelo...');
  
  // 1. Crear imágenes de prueba
  await _crearImagenesPrueba();
  
  // 2. Cargar modelo
  final interpreter = await Interpreter.fromAsset('assets/model/modelo_amazonas.tflite');
  print('✅ Modelo cargado');
  
  // 3. Obtener información del modelo
  final inputShape = interpreter.getInputTensor(0).shape;
  final outputShape = interpreter.getOutputTensor(0).shape;
  print('📊 Forma de entrada: $inputShape');
  print('📊 Forma de salida: $outputShape');
  
  // 4. Probar con diferentes imágenes
  await _probarImagen('test_imagen_negra.png', interpreter, inputShape, outputShape);
  await _probarImagen('test_imagen_blanca.png', interpreter, inputShape, outputShape);
  await _probarImagen('test_imagen_gris.png', interpreter, inputShape, outputShape);
  await _probarImagen('test_imagen_ruido.png', interpreter, inputShape, outputShape);
  
  interpreter.close();
  print('✅ Pruebas completadas');
}

Future<void> _crearImagenesPrueba() async {
  print('🎨 Creando imágenes de prueba...');
  
  // Imagen negra
  final imagenNegra = img.Image(180, 180);
  img.fill(imagenNegra, color: img.ColorRgb8(0, 0, 0));
  await File('test_imagen_negra.png').writeAsBytes(img.encodePng(imagenNegra));
  
  // Imagen blanca
  final imagenBlanca = img.Image(180, 180);
  img.fill(imagenBlanca, color: img.ColorRgb8(255, 255, 255));
  await File('test_imagen_blanca.png').writeAsBytes(img.encodePng(imagenBlanca));
  
  // Imagen gris
  final imagenGris = img.Image(180, 180);
  img.fill(imagenGris, color: img.ColorRgb8(128, 128, 128));
  await File('test_imagen_gris.png').writeAsBytes(img.encodePng(imagenGris));
  
  // Imagen con ruido aleatorio
  final imagenRuido = img.Image(180, 180);
  for (int y = 0; y < 180; y++) {
    for (int x = 0; x < 180; x++) {
      final r = (DateTime.now().millisecondsSinceEpoch % 256);
      final g = (DateTime.now().microsecondsSinceEpoch % 256);
      final b = (DateTime.now().microseconds % 256);
      imagenRuido.setPixel(x, y, img.ColorRgb8(r, g, b));
    }
  }
  await File('test_imagen_ruido.png').writeAsBytes(img.encodePng(imagenRuido));
  
  print('✅ Imágenes de prueba creadas');
}

Future<void> _probarImagen(String nombreArchivo, Interpreter interpreter, List<int> inputShape, List<int> outputShape) async {
  print('\n🔍 Probando: $nombreArchivo');
  
  try {
    // 1. Cargar imagen
    final file = File(nombreArchivo);
    if (!await file.exists()) {
      print('❌ Archivo no encontrado: $nombreArchivo');
      return;
    }
    
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      print('❌ No se pudo decodificar la imagen');
      return;
    }
    
    // 2. Preprocesar
    final targetSize = inputShape[1];
    final resized = img.copyResize(image, width: targetSize, height: targetSize);
    
    // Convertir a tensor
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
    
    // 3. Calcular estadísticas
    double minVal = 1.0, maxVal = 0.0, sumVal = 0.0;
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
    final contraste = maxVal - minVal;
    
    print('📊 Estadísticas:');
    print('   - Mínimo: ${minVal.toStringAsFixed(3)}');
    print('   - Máximo: ${maxVal.toStringAsFixed(3)}');
    print('   - Promedio: ${promedio.toStringAsFixed(3)}');
    print('   - Contraste: ${contraste.toStringAsFixed(3)}');
    
    // 4. Ejecutar modelo
    final input = [tensor];
    final output = List.filled(outputShape[0] * outputShape[1], 0.0).reshape(outputShape);
    
    interpreter.run(input, output);
    
    // 5. Analizar resultados
    final rawOutput = output[0] as List<double>;
    
    print('🔍 Resultados del modelo:');
    print('   - Mínimo: ${rawOutput.reduce((a, b) => a < b ? a : b).toStringAsFixed(3)}');
    print('   - Máximo: ${rawOutput.reduce((a, b) => a > b ? a : b).toStringAsFixed(3)}');
    print('   - Promedio: ${(rawOutput.reduce((a, b) => a + b) / rawOutput.length).toStringAsFixed(3)}');
    
    // Top 3 predicciones
    List<MapEntry<int, double>> withIndices = [];
    for (int i = 0; i < rawOutput.length; i++) {
      withIndices.add(MapEntry(i, rawOutput[i]));
    }
    withIndices.sort((a, b) => b.value.compareTo(a.value));
    
    print('   - Top 3 predicciones:');
    for (int i = 0; i < 3; i++) {
      final entry = withIndices[i];
      print('     ${i + 1}. Índice ${entry.key}: ${entry.value.toStringAsFixed(3)}');
    }
    
    // 6. Aplicar softmax
    final probabilidades = _aplicarSoftmax(rawOutput);
    final top3Prob = withIndices.take(3).map((e) => MapEntry(e.key, probabilidades[e.key])).toList();
    
    print('   - Top 3 probabilidades:');
    for (int i = 0; i < 3; i++) {
      final entry = top3Prob[i];
      print('     ${i + 1}. Índice ${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}

List<double> _aplicarSoftmax(List<double> logits) {
  final maxLogit = logits.reduce((a, b) => a > b ? a : b);
  final exponenciales = logits.map((logit) => (logit - maxLogit)).map((x) => exp(x)).toList();
  final suma = exponenciales.reduce((a, b) => a + b);
  return exponenciales.map((exp) => exp / suma).toList();
} 