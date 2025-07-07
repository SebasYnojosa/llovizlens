#!/usr/bin/env python3
"""
Script simplificado para convertir modelos H5 a TFLite
Evita errores de compatibilidad entre versiones de TensorFlow
"""

import argparse
import os
import tensorflow as tf
import numpy as np

def convertir_modelo_simple(input_path, output_path):
    """Convierte un modelo H5 a TFLite de forma simple"""
    try:
        print(f"🔄 Cargando modelo desde: {input_path}")
        
        # Cargar el modelo
        model = tf.keras.models.load_model(input_path)
        
        print(f"✅ Modelo cargado exitosamente")
        print(f"📊 Arquitectura del modelo:")
        model.summary()
        
        # Obtener información del modelo
        input_shape = model.input_shape
        output_shape = model.output_shape
        print(f"📐 Forma de entrada: {input_shape}")
        print(f"📐 Forma de salida: {output_shape}")
        
        # Guardar como SavedModel primero (más compatible)
        temp_dir = "temp_saved_model"
        print(f"💾 Guardando como SavedModel en: {temp_dir}")
        try:
            # Intentar método de Keras 3
            model.save(temp_dir)
        except Exception as e:
            print(f"⚠️  Error con método Keras 3: {e}")
            print("🔄 Intentando método alternativo...")
            # Método alternativo para Keras 3
            model.export(temp_dir)
        
        # Convertir desde SavedModel
        print("🔄 Convirtiendo a TFLite...")
        converter = tf.lite.TFLiteConverter.from_saved_model(temp_dir)
        
        # Configuraciones básicas sin optimizaciones problemáticas
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS
        ]
        
        # Convertir
        tflite_model = converter.convert()
        
        # Guardar el modelo
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        # Calcular tamaño
        size_mb = os.path.getsize(output_path) / (1024 * 1024)
        print(f"✅ Modelo convertido exitosamente!")
        print(f"📁 Guardado en: {output_path}")
        print(f"📏 Tamaño: {size_mb:.2f} MB")
        
        # Limpiar archivos temporales
        import shutil
        if os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)
        
        return True
        
    except Exception as e:
        print(f"❌ Error convirtiendo modelo: {e}")
        # Limpiar en caso de error
        import shutil
        if os.path.exists("temp_saved_model"):
            shutil.rmtree("temp_saved_model")
        return False

def verificar_modelo_tflite(tflite_path):
    """Verifica que el modelo TFLite sea válido"""
    try:
        print(f"🔍 Verificando modelo: {tflite_path}")
        
        interpreter = tf.lite.Interpreter(model_path=tflite_path)
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print("✅ Modelo TFLite válido!")
        print(f"📊 Entrada: {input_details[0]['shape']} - {input_details[0]['dtype']}")
        print(f"📊 Salida: {output_details[0]['shape']} - {output_details[0]['dtype']}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error verificando modelo: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Convertir modelo H5 a TFLite (versión simple)')
    parser.add_argument('--input', required=True, help='Ruta al archivo .h5')
    parser.add_argument('--output', default='model.tflite', help='Ruta de salida para .tflite')
    parser.add_argument('--verify', action='store_true', help='Verificar compatibilidad después de convertir')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        print(f"❌ Error: El archivo {args.input} no existe")
        return
    
    # Convertir el modelo
    success = convertir_modelo_simple(args.input, args.output)
    
    if success and args.verify:
        verificar_modelo_tflite(args.output)
    
    if success:
        print("\n🎉 ¡Conversión completada!")
        print(f"📱 El modelo {args.output} está listo para usar en Flutter")
        print("\n📋 Próximos pasos:")
        print("1. Copia el archivo .tflite a assets/model/")
        print("2. Asegúrate de que las etiquetas en labels.txt coincidan")
        print("3. Prueba la app con el nuevo modelo")

if __name__ == "__main__":
    main() 