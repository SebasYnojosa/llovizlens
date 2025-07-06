import os
import requests
from PIL import Image
import numpy as np
from sklearn.model_selection import train_test_split
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
import tensorflow as tf
from tensorflow import keras
import json

class EntrenadorModeloPlantas:
    def __init__(self):
        self.categorias = [
            'rosa', 'girasol', 'tulipan', 'margarita', 'lirio', 
            'orquidea', 'crisantemo', 'peonia', 'geranio', 'begonia'
        ]
        self.imagenes_por_categoria = 100
        self.tamano_imagen = (224, 224)
        self.datos_entrenamiento = []
        self.etiquetas = []
        
    def descargar_imagen(self, url, ruta_destino):
        """Descarga una imagen desde una URL"""
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            
            with open(ruta_destino, 'wb') as f:
                f.write(response.content)
            
            # Verificar que la imagen sea válida
            with Image.open(ruta_destino) as img:
                img.verify()
            return True
        except Exception as e:
            print(f"Error descargando {url}: {e}")
            return False
    
    def buscar_imagenes_plantas(self, categoria):
        """Busca URLs de imágenes de plantas usando Unsplash API"""
        # URLs de ejemplo para cada categoría (en un caso real usarías una API)
        urls_ejemplo = {
            'rosa': [
                'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=400',
                'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400',
                'https://images.unsplash.com/photo-1519378058457-4c29a0a2efac?w=400',
            ],
            'girasol': [
                'https://images.unsplash.com/photo-1597848212624-a19eb35e2651?w=400',
                'https://images.unsplash.com/photo-1504567961542-e24d9439a724?w=400',
                'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
            ],
            'tulipan': [
                'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?w=400',
                'https://images.unsplash.com/photo-1526040652367-ac003a0475fe?w=400',
                'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400',
            ],
            'margarita': [
                'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400',
                'https://images.unsplash.com/photo-1504567961542-e24d9439a724?w=400',
                'https://images.unsplash.com/photo-1597848212624-a19eb35e2651?w=400',
            ],
            'lirio': [
                'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=400',
                'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400',
                'https://images.unsplash.com/photo-1519378058457-4c29a0a2efac?w=400',
            ]
        }
        
        # Para simplificar, usamos las mismas URLs para todas las categorías
        # En un caso real, tendrías URLs específicas para cada planta
        return urls_ejemplo.get(categoria, urls_ejemplo['rosa'])
    
    def descargar_dataset(self):
        """Descarga el dataset de imágenes"""
        print("Descargando dataset de plantas...")
        
        # Crear directorios
        os.makedirs('dataset', exist_ok=True)
        for categoria in self.categorias:
            os.makedirs(f'dataset/{categoria}', exist_ok=True)
        
        for categoria in self.categorias:
            print(f"Descargando imágenes de {categoria}...")
            urls = self.buscar_imagenes_plantas(categoria)
            
            for i, url in enumerate(urls):
                ruta_destino = f'dataset/{categoria}/{categoria}_{i}.jpg'
                if self.descargar_imagen(url, ruta_destino):
                    print(f"  ✓ Descargada: {ruta_destino}")
                else:
                    print(f"  ✗ Falló: {url}")
    
    def cargar_y_preprocesar_imagenes(self):
        """Carga y preprocesa las imágenes del dataset"""
        print("Cargando y preprocesando imágenes...")
        
        for idx, categoria in enumerate(self.categorias):
            ruta_categoria = f'dataset/{categoria}'
            if not os.path.exists(ruta_categoria):
                continue
                
            for archivo in os.listdir(ruta_categoria):
                if archivo.endswith(('.jpg', '.jpeg', '.png')):
                    ruta_completa = os.path.join(ruta_categoria, archivo)
                    try:
                        # Cargar y redimensionar imagen
                        imagen = Image.open(ruta_completa).convert('RGB')
                        imagen = imagen.resize(self.tamano_imagen)
                        
                        # Convertir a array y normalizar
                        array_imagen = np.array(imagen) / 255.0
                        
                        self.datos_entrenamiento.append(array_imagen)
                        self.etiquetas.append(idx)
                        
                    except Exception as e:
                        print(f"Error procesando {ruta_completa}: {e}")
        
        self.datos_entrenamiento = np.array(self.datos_entrenamiento)
        self.etiquetas = np.array(self.etiquetas)
        
        print(f"Dataset cargado: {len(self.datos_entrenamiento)} imágenes, {len(self.categorias)} categorías")
    
    def crear_modelo(self):
        """Crea el modelo de clasificación"""
        print("Creando modelo...")
        
        # Modelo base pre-entrenado
        modelo_base = MobileNetV2(
            weights='imagenet',
            include_top=False,
            input_shape=(224, 224, 3)
        )
        
        # Congelar las capas del modelo base
        modelo_base.trainable = False
        
        # Agregar capas de clasificación
        x = modelo_base.output
        x = GlobalAveragePooling2D()(x)
        x = Dense(512, activation='relu')(x)
        x = Dropout(0.5)(x)
        x = Dense(256, activation='relu')(x)
        x = Dropout(0.3)(x)
        salida = Dense(len(self.categorias), activation='softmax')(x)
        
        # Crear modelo
        modelo = Model(inputs=modelo_base.input, outputs=salida)
        
        # Compilar modelo
        modelo.compile(
            optimizer=Adam(learning_rate=0.001),
            loss='sparse_categorical_crossentropy',
            metrics=['accuracy']
        )
        
        return modelo
    
    def entrenar_modelo(self, modelo):
        """Entrena el modelo"""
        print("Entrenando modelo...")
        
        # Dividir datos en entrenamiento y validación
        X_train, X_val, y_train, y_val = train_test_split(
            self.datos_entrenamiento, 
            self.etiquetas, 
            test_size=0.2, 
            random_state=42,
            stratify=self.etiquetas
        )
        
        # Data augmentation para entrenamiento
        datagen = ImageDataGenerator(
            rotation_range=20,
            width_shift_range=0.2,
            height_shift_range=0.2,
            horizontal_flip=True,
            zoom_range=0.2
        )
        
        # Entrenar modelo
        historia = modelo.fit(
            datagen.flow(X_train, y_train, batch_size=32),
            validation_data=(X_val, y_val),
            epochs=10,
            steps_per_epoch=len(X_train) // 32
        )
        
        return historia
    
    def convertir_a_tflite(self, modelo):
        """Convierte el modelo a TensorFlow Lite"""
        print("Convirtiendo a TensorFlow Lite...")
        
        # Convertir a TFLite
        converter = tf.lite.TFLiteConverter.from_keras_model(modelo)
        tflite_model = converter.convert()
        
        # Guardar modelo TFLite
        with open('modelo_plantas.tflite', 'wb') as f:
            f.write(tflite_model)
        
        print("Modelo TFLite guardado como 'modelo_plantas.tflite'")
    
    def guardar_metadata(self):
        """Guarda metadata del modelo"""
        metadata = {
            'categorias': self.categorias,
            'tamano_imagen': self.tamano_imagen,
            'descripcion': 'Modelo de clasificación de plantas entrenado con MobileNetV2'
        }
        
        with open('metadata_modelo.json', 'w', encoding='utf-8') as f:
            json.dump(metadata, f, ensure_ascii=False, indent=2)
        
        print("Metadata guardada como 'metadata_modelo.json'")
    
    def ejecutar_entrenamiento_completo(self):
        """Ejecuta todo el proceso de entrenamiento"""
        print("=== INICIANDO ENTRENAMIENTO DE MODELO DE PLANTAS ===")
        
        # 1. Descargar dataset
        self.descargar_dataset()
        
        # 2. Cargar y preprocesar imágenes
        self.cargar_y_preprocesar_imagenes()
        
        if len(self.datos_entrenamiento) == 0:
            print("Error: No se pudieron cargar imágenes. Verifica la conexión a internet.")
            return
        
        # 3. Crear modelo
        modelo = self.crear_modelo()
        
        # 4. Entrenar modelo
        historia = self.entrenar_modelo(modelo)
        
        # 5. Convertir a TFLite
        self.convertir_a_tflite(modelo)
        
        # 6. Guardar metadata
        self.guardar_metadata()
        
        print("=== ENTRENAMIENTO COMPLETADO ===")
        print("Archivos generados:")
        print("- modelo_plantas.tflite (modelo para Flutter)")
        print("- metadata_modelo.json (información del modelo)")
        print("- dataset/ (imágenes descargadas)")

if __name__ == "__main__":
    entrenador = EntrenadorModeloPlantas()
    entrenador.ejecutar_entrenamiento_completo() 