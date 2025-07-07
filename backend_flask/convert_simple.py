#!/usr/bin/env python3
"""
Script simplificado para convertir modelos .h5 a TensorFlow Lite
Usa rutas específicas dentro de backend_flask
"""

import os
import sys
import subprocess
import shutil

def verificar_dependencias():
    """Verifica si las dependencias necesarias están instaladas"""
    try:
        import tensorflow as tf
        print(f"✅ TensorFlow encontrado: {tf.__version__}")
        return True
    except ImportError:
        print("❌ TensorFlow no está instalado")
        return False

def instalar_tensorflow():
    """Instala TensorFlow usando pip"""
    print("📦 Instalando TensorFlow...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "tensorflow==2.16.1"])
        print("✅ TensorFlow instalado exitosamente")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Error instalando TensorFlow: {e}")
        return False

def convertir_modelo_h5_a_tflite(modelo_h5, modelo_tflite, optimizar=True):
    """
    Convierte un modelo .h5 a .tflite usando TensorFlow Lite Converter
    """
    try:
        import tensorflow as tf
        from tensorflow import keras
        import numpy as np
        
        print(f"🔄 Convirtiendo {modelo_h5} a {modelo_tflite}")
        
        # Cargar el modelo .h5
        print("📥 Cargando modelo desde .h5...")
        model = keras.models.load_model(modelo_h5)
        
        # Mostrar información del modelo
        print(f"📊 Información del modelo:")
        print(f"   - Capas: {len(model.layers)}")
        print(f"   - Parámetros: {model.count_params():,}")
        print(f"   - Tamaño de entrada: {model.input_shape}")
        print(f"   - Tamaño de salida: {model.output_shape}")
        
        # Crear el convertidor
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        
        # Configurar optimizaciones si se solicita
        if optimizar:
            print("⚡ Aplicando optimizaciones...")
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            
            # Configurar representación cuantizada
            def representative_dataset_gen():
                for _ in range(100):
                    # Generar datos de ejemplo para cuantización
                    # Ajustar según las dimensiones de tu modelo
                    data = np.random.random((1, 224, 224, 3)).astype(np.float32)
                    yield [data]
            
            converter.representative_dataset = representative_dataset_gen
            converter.target_spec.supported_ops = [
                tf.lite.OpsSet.TFLITE_BUILTINS_INT8,
                tf.lite.OpsSet.TFLITE_BUILTINS,
            ]
            converter.inference_input_type = tf.uint8
            converter.inference_output_type = tf.uint8
        
        # Convertir el modelo
        print("🔄 Convirtiendo a TensorFlow Lite...")
        tflite_model = converter.convert()
        
        # Guardar el modelo
        with open(modelo_tflite, 'wb') as f:
            f.write(tflite_model)
        
        # Mostrar información del archivo resultante
        file_size = os.path.getsize(modelo_tflite) / (1024 * 1024)  # MB
        print(f"✅ Modelo convertido exitosamente!")
        print(f"📁 Archivo guardado: {modelo_tflite}")
        print(f"📏 Tamaño: {file_size:.2f} MB")
        
        return True
        
    except Exception as e:
        print(f"❌ Error convirtiendo modelo: {e}")
        return False

def validar_modelo_tflite(modelo_tflite):
    """Valida el modelo TensorFlow Lite convertido"""
    try:
        import tensorflow as tf
        import numpy as np
        
        print("🔍 Validando modelo convertido...")
        
        # Cargar el modelo TensorFlow Lite
        interpreter = tf.lite.Interpreter(model_path=modelo_tflite)
        interpreter.allocate_tensors()
        
        # Obtener detalles de entrada y salida
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"📊 Detalles del modelo TFLite:")
        print(f"   - Entrada: {input_details[0]['shape']}")
        print(f"   - Salida: {output_details[0]['shape']}")
        
        # Crear datos de prueba
        test_input = np.random.random((1, 224, 224, 3)).astype(np.float32)
        
        # Ejecutar inferencia
        interpreter.set_tensor(input_details[0]['index'], test_input)
        interpreter.invoke()
        
        # Obtener resultado
        output_data = interpreter.get_tensor(output_details[0]['index'])
        
        print(f"✅ Validación exitosa!")
        print(f"   - Forma de salida: {output_data.shape}")
        print(f"   - Rango de valores: [{output_data.min():.4f}, {output_data.max():.4f}]")
        
        return True
        
    except Exception as e:
        print(f"❌ Error validando modelo: {e}")
        return False

def crear_estructura_flutter():
    """Crea la estructura de carpetas para Flutter"""
    print("📁 Creando estructura para Flutter...")
    
    # Crear carpeta assets/model si no existe
    assets_dir = "assets"
    model_dir = os.path.join(assets_dir, "model")
    
    os.makedirs(model_dir, exist_ok=True)
    print(f"✅ Carpeta creada: {model_dir}")
    
    return model_dir

def copiar_archivos_flutter(modelo_tflite, labels_txt, model_dir):
    """Copia los archivos necesarios para Flutter"""
    try:
        # Copiar modelo .tflite
        tflite_dest = os.path.join(model_dir, "model.tflite")
        shutil.copy2(modelo_tflite, tflite_dest)
        print(f"📋 Modelo copiado: {tflite_dest}")
        
        # Copiar etiquetas
        labels_dest = os.path.join(model_dir, "labels.txt")
        shutil.copy2(labels_txt, labels_dest)
        print(f"📋 Etiquetas copiadas: {labels_dest}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error copiando archivos: {e}")
        return False

def crear_pubspec_yaml():
    """Crea un ejemplo de pubspec.yaml para Flutter"""
    pubspec_content = """# Ejemplo de pubspec.yaml para TensorFlow Lite

name: llovizlens_offline
description: Aplicación Flutter con reconocimiento offline

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  tflite_flutter: ^0.10.4
  image: ^4.1.3
  camera: ^0.10.5+9
  path_provider: ^2.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  assets:
    - assets/model/
"""
    
    with open("pubspec_example.yaml", "w", encoding="utf-8") as f:
        f.write(pubspec_content)
    
    print("📄 Archivo pubspec_example.yaml creado")

def main():
    """Función principal"""
    print("🚀 Iniciando conversión de modelo .h5 a .tflite")
    print("=" * 50)
    
    # Definir rutas
    modelo_h5 = "model_pruebas.h5"
    modelo_tflite = "model_pruebas.tflite"
    labels_txt = "labels.txt"
    
    # Verificar que el modelo existe
    if not os.path.exists(modelo_h5):
        print(f"❌ Error: El archivo {modelo_h5} no existe")
        return
    
    if not os.path.exists(labels_txt):
        print(f"❌ Error: El archivo {labels_txt} no existe")
        return
    
    # Verificar dependencias
    if not verificar_dependencias():
        print("🔧 Intentando instalar TensorFlow...")
        if not instalar_tensorflow():
            print("❌ No se pudo instalar TensorFlow. Instálalo manualmente:")
            print("   pip install tensorflow==2.16.1")
            return
    
    # Convertir modelo
    print("\n🔄 Paso 1: Convirtiendo modelo...")
    if not convertir_modelo_h5_a_tflite(modelo_h5, modelo_tflite, optimizar=True):
        print("❌ Error en la conversión")
        return
    
    # Validar modelo
    print("\n🔍 Paso 2: Validando modelo...")
    if not validar_modelo_tflite(modelo_tflite):
        print("⚠️  Advertencia: El modelo no se pudo validar completamente")
    
    # Crear estructura Flutter
    print("\n📁 Paso 3: Preparando para Flutter...")
    model_dir = crear_estructura_flutter()
    
    # Copiar archivos
    if not copiar_archivos_flutter(modelo_tflite, labels_txt, model_dir):
        print("❌ Error copiando archivos")
        return
    
    # Crear pubspec.yaml de ejemplo
    crear_pubspec_yaml()
    
    print("\n🎉 ¡Conversión completada exitosamente!")
    print("=" * 50)
    print("📁 Archivos generados:")
    print(f"   - {modelo_tflite}")
    print(f"   - {model_dir}/model.tflite")
    print(f"   - {model_dir}/labels.txt")
    print("   - pubspec_example.yaml")
    print("\n📱 Para usar en Flutter:")
    print("   1. Copia la carpeta 'assets' a tu proyecto Flutter")
    print("   2. Usa el archivo 'pubspec_example.yaml' como referencia")
    print("   3. Usa el procesador 'ProcesadorTFLiteOffline' de la carpeta lib/")

if __name__ == "__main__":
    main() 