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

# Cargar modelo y clases
MODEL_PATH = 'modelo_llovizlens.h5'
DATASET_DIR = 'dataset'

if os.path.exists(MODEL_PATH):
    model = tf.keras.models.load_model(MODEL_PATH)
    class_names = sorted(os.listdir(DATASET_DIR))
    ESPECIES = {
        'Apamates': 'Tabebuia rosea',
        'Araguaney': 'Handroanthus chrysanthus',
        'Araguato': 'Alouatta seniculus',
    }
else:
    model = None
    class_names = []
    ESPECIES = {}

@app.route('/')
def home():
    return 'Backend Flask para Llovizlens', 200

@app.route('/predict', methods=['POST'])
def predict():
    if model is None:
        return jsonify({'error': 'Modelo no entrenado'}), 500
    if 'file' not in request.files:
        return jsonify({'error': 'No se envió imagen'}), 400
    file = request.files['file']
    try:
        img = Image.open(file.stream).convert('RGB')
        img = img.resize((224, 224))
        x = image.img_to_array(img)
        x = np.expand_dims(x, axis=0)
        x = preprocess_input(x)
        preds = model.predict(x)
        idx = np.argmax(preds[0])
        nombre_comun = class_names[idx]
        nombre_cientifico = ESPECIES.get(nombre_comun, '')
        return jsonify({
            'nombre_comun': nombre_comun,
            'nombre_cientifico': nombre_cientifico,
            'confianza': float(np.max(preds[0]))
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True) 