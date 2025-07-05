import os
import requests
from duckduckgo_search import DDGS
from PIL import Image
from io import BytesIO

ESPECIES = {
    'Apamates': 'Tabebuia rosea',
    'Araguaney': 'Handroanthus chrysanthus',
    'Araguato': 'Alouatta seniculus',
}

IMAGENES_POR_ESPECIE = 50
DATASET_DIR = 'dataset'

os.makedirs(DATASET_DIR, exist_ok=True)

def descargar_imagenes(query, carpeta, n=50):
    os.makedirs(carpeta, exist_ok=True)
    urls = []
    with DDGS() as ddgs:
        for r in ddgs.images(query, max_results=n*2):
            if r['image'] and r['image'].startswith('http'):
                urls.append(r['image'])
            if len(urls) >= n:
                break
    print(f"Descargando {len(urls)} imágenes para {query}...")
    descargadas = 0
    for i, url in enumerate(urls):
        try:
            resp = requests.get(url, timeout=10)
            img = Image.open(BytesIO(resp.content)).convert('RGB')
            img.save(os.path.join(carpeta, f'{i+1}.jpg'))
            descargadas += 1
        except Exception as e:
            print(f"Error con {url}: {e}")
        if descargadas >= n:
            break
    print(f"Descargadas {descargadas} imágenes en {carpeta}")

if __name__ == '__main__':
    for nombre, cientifico in ESPECIES.items():
        query = f"{nombre} {cientifico}"
        carpeta = os.path.join(DATASET_DIR, nombre)
        descargar_imagenes(query, carpeta, IMAGENES_POR_ESPECIE) 