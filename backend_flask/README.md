# Backend Flask para Llovizlens

## Requisitos
- Python 3.8+
- pip

## Instalación

```bash
cd backend_flask
pip install -r requirements.txt
```

## Ejecución

```bash
python app.py
```

El backend estará disponible en http://localhost:5000

## Endpoint de predicción

- POST `/predict`
- Body: imagen (form-data, campo 'file')
- Respuesta: JSON con nombre común y científico 