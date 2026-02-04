# Clasificador de Perros y Gatos con IA

Este proyecto utiliza TensorFlow y MobileNetV2 para clasificar imágenes.

## Instalación

1. Asegúrate de tener Python instalado.
2. Instala las dependencias:
   ```bash
   pip install -r requirements.txt
   ```

## Uso

### Script Interactivo
Para probar el clasificador con tus propias imágenes:
```bash
python script.py
```
El programa te pedirá la ruta de una imagen.

### Como Módulo
Puedes usar `CatDogClassifier` en tu propio código:

```python
from cat_dog_classifier import CatDogClassifier

classifier = CatDogClassifier()
result, confidence, label = classifier.predict("ruta/a/tu/imagen.jpg")

print(f"Es un {result} con {confidence:.2%} de confianza.")
```

## Notas
- La primera vez que ejecutes el código, se descargará el modelo MobileNetV2 (aprox 14MB).
- El clasificador está basado en ImageNet, por lo que puede reconocer muchas otras cosas, pero este módulo filtra especificamente por perros y gatos.
