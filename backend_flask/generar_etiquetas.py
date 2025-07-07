#!/usr/bin/env python3
"""
Script para generar etiquetas correctas basadas en el modelo
"""

import tensorflow as tf
import os

def obtener_etiquetas_del_modelo(model_path):
    """Obtiene las etiquetas del modelo si están disponibles"""
    try:
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        # Obtener información de salida
        output_details = interpreter.get_output_details()
        num_classes = output_details[0]['shape'][-1]
        
        print(f"📊 Modelo tiene {num_classes} clases")
        return num_classes
        
    except Exception as e:
        print(f"❌ Error leyendo modelo: {e}")
        return None

def generar_etiquetas_amazonas(num_clases=19):
    """Genera etiquetas para especies del Amazonas"""
    
    # Lista completa de especies del Amazonas
    todas_especies = [
        'Apamates', 'Araguaney', 'Araguato', 'Ave del paraíso', 'Azulejo',
        'Baba', 'Baquiro', 'Cachicamo', 'Cari cari', 'Cereza',
        'Chiguire', 'Culebra', 'Curí', 'Falsa coral', 'Indio desnudo (Arbol)',
        'Lapa', 'Lora', 'Loro real', 'Monos capuchino', 'Morocoto',
        'Morrocoy', 'Nutria gigante', 'Orquídeas', 'Pavón', 'Payara',
        'Pereza', 'Roble', 'Sapito minero', 'Tucan', 'Turpial', 'Uva playera'
    ]
    
    # Tomar solo las primeras num_clases especies
    etiquetas = todas_especies[:num_clases]
    
    print(f"📝 Generando {len(etiquetas)} etiquetas:")
    for i, etiqueta in enumerate(etiquetas):
        print(f"   {i+1:2d}. {etiqueta}")
    
    return etiquetas

def guardar_etiquetas(etiquetas, output_path):
    """Guarda las etiquetas en un archivo"""
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            for etiqueta in etiquetas:
                f.write(f"{etiqueta}\n")
        
        print(f"💾 Etiquetas guardadas en: {output_path}")
        return True
        
    except Exception as e:
        print(f"❌ Error guardando etiquetas: {e}")
        return False

def main():
    # Verificar si existe el modelo
    model_path = "model.tflite"
    if not os.path.exists(model_path):
        print(f"❌ No se encontró el modelo: {model_path}")
        print("💡 Asegúrate de haber convertido el modelo primero")
        return
    
    # Obtener número de clases del modelo
    num_clases = obtener_etiquetas_del_modelo(model_path)
    if num_clases is None:
        print("⚠️  No se pudo leer el modelo, usando 19 clases por defecto")
        num_clases = 19
    
    # Generar etiquetas
    etiquetas = generar_etiquetas_amazonas(num_clases)
    
    # Guardar etiquetas
    output_path = "../assets/model/labels.txt"
    success = guardar_etiquetas(etiquetas, output_path)
    
    if success:
        print("\n🎉 ¡Etiquetas generadas exitosamente!")
        print(f"📱 El archivo {output_path} está listo para usar en Flutter")
        print("\n📋 Próximos pasos:")
        print("1. Verifica que las etiquetas coincidan con tu modelo")
        print("2. Prueba la app con el nuevo modelo")
        print("3. Si las etiquetas no coinciden, edita manualmente el archivo")

if __name__ == "__main__":
    main() 