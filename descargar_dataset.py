import os
import requests
from PIL import Image
import io

def descargar_imagen_unsplash(query, filename, access_key="tu_access_key"):
    """Descarga una imagen de Unsplash"""
    try:
        # URL de Unsplash API
        url = f"https://api.unsplash.com/photos/random?query={query}&client_id={access_key}"
        
        # Obtener información de la imagen
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            image_url = data['urls']['regular']
            
            # Descargar la imagen
            img_response = requests.get(image_url)
            if img_response.status_code == 200:
                # Guardar la imagen
                with open(filename, 'wb') as f:
                    f.write(img_response.content)
                
                # Verificar que la imagen sea válida
                with Image.open(filename) as img:
                    img.verify()
                return True
    except Exception as e:
        print(f"Error descargando {query}: {e}")
    return False

def descargar_dataset_plantas():
    """Descarga un dataset básico de plantas"""
    plantas = {
        'rosa': 'rose flower',
        'girasol': 'sunflower',
        'tulipan': 'tulip flower',
        'margarita': 'daisy flower',
        'lirio': 'lily flower'
    }
    
    # Crear directorio
    os.makedirs('dataset', exist_ok=True)
    
    print("Descargando dataset de plantas...")
    print("Nota: Para usar la API de Unsplash, necesitas una access key gratuita")
    print("Visita: https://unsplash.com/developers")
    
    # Por ahora, creamos imágenes de ejemplo
    for planta, query in plantas.items():
        os.makedirs(f'dataset/{planta}', exist_ok=True)
        print(f"Creando directorio para {planta}...")
        
        # Crear archivo de placeholder
        with open(f'dataset/{planta}/README.txt', 'w') as f:
            f.write(f"Coloca aquí imágenes de {planta}\n")
            f.write(f"Busca en Google: {query}\n")
            f.write("Descarga al menos 10-20 imágenes por categoría\n")

if __name__ == "__main__":
    descargar_dataset_plantas()
    print("\nDataset creado. Ahora:")
    print("1. Ve a cada carpeta en dataset/")
    print("2. Descarga imágenes de internet manualmente")
    print("3. O usa la API de Unsplash con una access key")
    print("4. Ejecuta entrenar_modelo.py") 