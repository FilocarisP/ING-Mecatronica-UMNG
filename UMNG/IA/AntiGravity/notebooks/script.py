from cat_dog_classifier import CatDogClassifier
import gradio as gr
import os

# Inicializar modelo globalmente para no recargarlo en cada interacción
print("Inicializando clasificador...")
classifier = CatDogClassifier()

def clasificar_imagen(imagen):
    """
    Función wrapper para Gradio.
    Recibe una imagen (numpy array o PIL), la procesa y retorna el resultado legible.
    """
    if imagen is None:
        return "Por favor carga una imagen.", "N/A"
        
    resultado, confianza, etiqueta = classifier.predict(imagen)
    
    if resultado == "Error":
        return f"Error: {etiqueta}", 0.0
    
    mensaje = f"Es un **{resultado}**\n(Clase específica: {etiqueta})"
    confianza_fmt = f"{confianza:.1%}"
    
    return mensaje, confianza_fmt

# Crear interfaz de Gradio
# Usamos Blocks para personalizar un poco más el diseño si quisieramos, 
# pero Interface es suficiente y muy rápido.
iface = gr.Interface(
    fn=clasificar_imagen,
    inputs=gr.Image(type="pil", label="Carga tu imagen aquí"),
    outputs=[
        gr.Textbox(label="Resultado", lines=2),
        gr.Textbox(label="Confianza")
    ],
    title="🐶 Clasificador de Perros y Gatos 🐱",
    description="Sube una foto y la IA te dirá si es un perro o un gato utilizando MobileNetV2.",
)

if __name__ == "__main__":
    print("Lanzando interfaz web...")
    # launch(inbrowser=True) abre el navegador automáticamente
    iface.launch(inbrowser=True)
