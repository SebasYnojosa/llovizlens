# Backend Flask para Llovizlens

## Requisitos
- Python 3.8+
- pip

## Instalación

```bash
cd backend_flask
pip install -r requirements.txt
```


```bash
fluter pub get
```

```bash
python convertir_modelo_simple.py 
--input tu_modelo.h5 --output model.tflite --verify
```

## Ejecución
```bash
fluter run
```

## Endpoint de predicción

- POST `/predict`
- Respuesta: JSON con nombre común y científico 

