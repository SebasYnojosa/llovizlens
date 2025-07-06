# Entrenamiento del Modelo IA para Clasificación de Plantas

Este script entrena un modelo de clasificación de plantas usando TensorFlow y lo convierte a TensorFlow Lite para usar en Flutter.

## Requisitos

- Python 3.8 o superior
- Conexión a internet para descargar imágenes

## Instalación

1. Instala las dependencias:
```bash
pip install -r requirements_entrenamiento.txt
```

## Uso

1. Ejecuta el script de entrenamiento:
```bash
python entrenar_modelo.py
```

2. El script hará lo siguiente:
   - Descargará imágenes de plantas de internet
   - Entrenará un modelo de clasificación
   - Convertirá el modelo a TensorFlow Lite
   - Guardará los archivos necesarios

## Archivos Generados

- `modelo_plantas.tflite` - Modelo para usar en Flutter
- `metadata_modelo.json` - Información del modelo
- `dataset/` - Imágenes descargadas

## Integración con Flutter

1. Copia `modelo_plantas.tflite` a `assets/model/tu_modelo.tflite`
2. Copia `metadata_modelo.json` a `assets/model/`
3. Actualiza el código de Flutter para usar las categorías del modelo

## Categorías del Modelo

El modelo clasifica las siguientes plantas:
- Rosa
- Girasol
- Tulipán
- Margarita
- Lirio
- Orquídea
- Crisantemo
- Peonía
- Geranio
- Begonia

## Personalización

Puedes modificar `entrenar_modelo.py` para:
- Cambiar las categorías de plantas
- Ajustar el número de imágenes por categoría
- Modificar la arquitectura del modelo
- Cambiar los hiperparámetros de entrenamiento 