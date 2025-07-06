import tensorflow as tf
import numpy as np
import json
import os

def crear_modelo_ejemplo():
    """Crea un modelo TFLite de ejemplo para clasificación de plantas"""
    
    print("Creando modelo de ejemplo...")
    
    # Definir categorías
    categorias = ['rosa', 'girasol', 'tulipan', 'margarita', 'lirio']
    
    # Crear un modelo simple
    modelo = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(224, 224, 3)),
        tf.keras.layers.Conv2D(16, 3, activation='relu'),
        tf.keras.layers.MaxPooling2D(),
        tf.keras.layers.Conv2D(32, 3, activation='relu'),
        tf.keras.layers.MaxPooling2D(),
        tf.keras.layers.Conv2D(64, 3, activation='relu'),
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dropout(0.5),
        tf.keras.layers.Dense(len(categorias), activation='softmax')
    ])
    
    # Compilar modelo
    modelo.compile(
        optimizer='adam',
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )
    
    print("Modelo creado. Convirtiendo a TFLite...")
    
    # Convertir a TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(modelo)
    tflite_model = converter.convert()
    
    # Crear directorio si no existe
    os.makedirs('assets/model', exist_ok=True)
    
    # Guardar modelo TFLite
    with open('assets/model/tu_modelo.tflite', 'wb') as f:
        f.write(tflite_model)
    
    # Crear metadata
    metadata = {
        'categorias': categorias,
        'tamano_imagen': [224, 224],
        'descripcion': 'Modelo de ejemplo para clasificación de plantas',
        'version': '1.0',
        'autor': 'Llovizlens'
    }
    
    # Guardar metadata
    with open('assets/model/metadata_modelo.json', 'w', encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    
    print("✅ Modelo de ejemplo creado exitosamente!")
    print("📁 Archivos generados:")
    print("   - assets/model/tu_modelo.tflite")
    print("   - assets/model/metadata_modelo.json")
    print("\n🔧 Categorías del modelo:")
    for i, categoria in enumerate(categorias):
        print(f"   {i+1}. {categoria}")
    
    print("\n🚀 Ahora puedes ejecutar tu app Flutter!")
    print("   El modelo de ejemplo clasificará las plantas (aunque con baja precisión)")
    print("   Para mejor precisión, entrena con imágenes reales usando entrenar_modelo.py")

if __name__ == "__main__":
    crear_modelo_ejemplo() 