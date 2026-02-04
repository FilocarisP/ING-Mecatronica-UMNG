import tensorflow as tf
from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, preprocess_input, decode_predictions
from tensorflow.keras.preprocessing import image
import numpy as np
import os

class CatDogClassifier:
    def __init__(self):
        # Cargar el modelo pre-entrenado MobileNetV2
        # Include_top=True significa que incluimos las capas finales de clasificación (1000 clases de ImageNet)
        print("Cargando modelo MobileNetV2...")
        self.model = MobileNetV2(weights='imagenet', include_top=True)
        print("Modelo cargado exitosamente.")

    def predict(self, image_input):
        """
        Identifica si la imagen es un perro o un gato.
        image_input puede ser una ruta de archivo (str) o una imagen PIL / array.
        Retorna: 'dog', 'cat', o 'unknown' junto con la confianza.
        """
        try:
            # Procesar entrada dependiendo del tipo
            if isinstance(image_input, str):
                if not os.path.exists(image_input):
                    return "Error", 0.0, f"El archivo {image_input} no existe."
                img = image.load_img(image_input, target_size=(224, 224))
                x = image.img_to_array(img)
            else:
                # Asumimos que es una imagen PIL o numpy array si no es string
                # Gradio pasa numpy arrays o PIL images
                import PIL.Image
                
                if isinstance(image_input, np.ndarray):
                     # Convertir numpy array a PIL Image para redimensionar facilmente si es necesario
                     img = PIL.Image.fromarray(image_input)
                else:
                     img = image_input
                
                # Redimensionar al tamaño esperado
                img = img.resize((224, 224))
                x = image.img_to_array(img)
            
            # Expandir dimensiones para crear un batch de tamaño 1 (1, 224, 224, 3)
            x = np.expand_dims(x, axis=0)
            
            # Preprocesar la entrada (escalar valores, etc.)
            x = preprocess_input(x)

            # Realizar la predicción
            preds = self.model.predict(x)
            
            # Decodificar las predicciones (top 3)
            decoded_preds = decode_predictions(preds, top=3)[0]
            
            # Buscar si hay perro o gato en las predicciones
            for i, (imagenet_id, label, score) in enumerate(decoded_preds):
                # ImageNet tiene muchas razas específicas, pero muchas contienen 'terrier', 'spaniel', 'cat', 'tabby', etc.
                # Simplificamos buscando palabras clave en las etiquetas del modelo.
                
                # Definir palabras clave comunes para perros y gatos en ImageNet
                # Nota: Las etiquetas de ImageNet están en inglés
                label_lower = label.lower()
                
                # Lista expandida de términos
                cat_terms = ['cat', 'tabby', 'tiger_cat', 'persian_cat', 'siamese_cat', 'egyptian_cat', 'lynx']
                dog_terms = ['dog', 'terrier', 'retriever', 'hound', 'poodle', 'chihuahua', 'beagle', 'collie', 
                             'doberman', 'schnauzer', 'dalmatian', 'spaniel', 'bulldog', 'pug', 'shepherd', 'malamute',
                             'pomeranian', 'samoyed', 'husky', 'dane', 'corgi', 'boxer', 'rottweiler', 'bernard']

                # Verificar si es gato
                if any(term in label_lower for term in cat_terms):
                    return "Gato", float(score), label
                
                # Verificar si es perro
                # Nota: Muchas razas de perro no dicen explícitamente "dog", así que es una aproximación.
                # Una lógica más robusta sería verificar si el synset (imagenet_id) pertenece a la jerarquía de perros,
                # pero para este demo simple, buscaremos términos comunes y asumiremos que la mayoría de 
                # las predicciones biológicas domésticas que no son gatos, podrían ser perros si coinciden con razas.
                # Sin embargo, para ser más precisos con un modelo genérico:
                    
                # Si el label contiene 'dog' o es una raza conocida
                if any(term in label_lower for term in dog_terms):
                    return "Perro", float(score), label
            
            # Si no se encontró ninguno en el top 3
            return "Desconocido/Otro", float(decoded_preds[0][2]), decoded_preds[0][1]

        except Exception as e:
            return "Error", 0.0, str(e)

if __name__ == "__main__":
    # Ejemplo de uso simple si se ejecuta directamente
    classifier = CatDogClassifier()
    print("Módulo listo. Importa esta clase o usa predict() con una ruta de imagen.")
