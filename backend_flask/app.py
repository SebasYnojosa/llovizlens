from flask import Flask, request, jsonify
from flask_cors import CORS
import tensorflow as tf
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input
from tensorflow.keras.preprocessing import image
import numpy as np
import os
from PIL import Image

app = Flask(__name__)
CORS(app)

# Configuración de rutas
MODEL_PATH = 'model_pruebas.h5'  # Usar el modelo solicitado
LABELS_PATH = 'labels.txt'       # Etiquetas en el mismo directorio

# Variables globales
model = None
class_names = []

# Función para cargar modelo y etiquetas
def cargar_modelo():
    global model, class_names
    try:
        # Cargar etiquetas
        if os.path.exists(LABELS_PATH):
            with open(LABELS_PATH, 'r', encoding='utf-8') as f:
                class_names = [line.strip() for line in f if line.strip()]
            print(f'✅ Etiquetas cargadas: {len(class_names)}')
        else:
            print('❌ No se encontró labels.txt')
            class_names = []
            return False
        # Cargar modelo
        if os.path.exists(MODEL_PATH):
            model = tf.keras.models.load_model(MODEL_PATH)
            print(f'✅ Modelo cargado: {MODEL_PATH}')
            print(f'📊 Forma de entrada: {model.input_shape}')
            print(f'📊 Forma de salida: {model.output_shape}')
            return True
        else:
            print(f'❌ No se encontró el modelo: {MODEL_PATH}')
            return False
    except Exception as e:
        print(f'❌ Error cargando modelo: {e}')
        return False

# Inicializar modelo al iniciar
with app.app_context():
    cargar_modelo()

@app.route('/')
def home():
    return jsonify({
        'mensaje': 'Backend Flask para Llovizlens',
        'modelo_cargado': model is not None,
        'especies_disponibles': len(class_names),
        'especies': class_names
    }), 200

@app.route('/predict', methods=['POST'])
def predict():
    if model is None:
        return jsonify({'error': 'Modelo no cargado'}), 500
    if 'file' not in request.files:
        return jsonify({'error': 'No se envió imagen'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'Archivo no seleccionado'}), 400
    try:
        img = Image.open(file.stream).convert('RGB')
        img = img.resize((224, 224))
        x = image.img_to_array(img)
        x = np.expand_dims(x, axis=0)
        x = preprocess_input(x)
        preds = model.predict(x)
        idx = int(np.argmax(preds[0]))
        confianza = float(np.max(preds[0]) * 100)
        nombre_comun = class_names[idx] if idx < len(class_names) else 'Desconocido'
        # Top 3 predicciones
        top_indices = np.argsort(preds[0])[-3:][::-1]
        top_predictions = []
        for i in top_indices:
            if i < len(class_names):
                top_predictions.append({
                    'especie': class_names[i],
                    'confianza': float(preds[0][i] * 100),
                    'indice': int(i)
                })
        return jsonify({
            'especie_principal': nombre_comun,
            'confianza': confianza,
            'indice': idx,
            'top_predictions': top_predictions,
            'todas_predicciones': {
                class_names[i]: float(preds[0][i] * 100)
                for i in range(len(class_names))
            },
            'total_especies': len(class_names),
            'timestamp': str(np.datetime64("now"))
        })
    except Exception as e:
        print(f'❌ Error en predicción: {e}')
        return jsonify({'error': str(e)}), 500

@app.route('/status')
def status():
    return jsonify({
        'modelo_cargado': model is not None,
        'especies_disponibles': len(class_names),
        'especies': class_names,
        'modelo_path': MODEL_PATH,
        'labels_path': LABELS_PATH
    })

if __name__ == '__main__':
    print('🚀 Iniciando servidor Flask para Llovizlens...')
    print(f'📁 Buscando modelo en: {MODEL_PATH}')
    print(f'📁 Buscando etiquetas en: {LABELS_PATH}')
    if cargar_modelo():
        print('✅ Servidor listo para recibir predicciones')
    else:
        print('⚠️  Servidor iniciado sin modelo - algunas funciones no estarán disponibles')
    app.run(host='0.0.0.0', port=5000, debug=True) 