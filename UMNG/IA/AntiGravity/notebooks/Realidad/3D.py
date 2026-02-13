import cv2
import numpy as np
import os

def create_glitch_3d_effect(image_path, output_path, shift_amount=10):
    """
    Crea un efecto glitch 3D (anaglifo) a partir de una imagen.
    1. Convierte la imagen a blanco y negro.
    2. Duplica la imagen y desplaza los canales.
    3. Combina un canal Rojo desplazado y un canal Cian desplazado.
    """
    
    # Verificar existencia
    if not os.path.exists(image_path):
        print(f"Error: La imagen no existe en la ruta: {image_path}")
        # Intentar buscarla en el directorio actual si falla la ruta absoluta provista
        filename = os.path.basename(image_path)
        if os.path.exists(filename):
             image_path = filename
             print(f"Encontrada en directorio actual: {image_path}")
        else:
             return

    # Cargar imagen
    img = cv2.imread(image_path)
    if img is None:
        print("Error al cargar la imagen con OpenCV.")
        return

    # 1. Convertir a Escala de Grises (Blanco y Negro)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    rows, cols = gray.shape

    # 2. Crear copias desplazadas
    # Matriz de desplazamiento para el canal ROJO (izquierda)
    # [1, 0, -shift] -> mover en X negativo
    M_left = np.float32([[1, 0, -shift_amount], [0, 1, 0]])
    gray_shifted_left = cv2.warpAffine(gray, M_left, (cols, rows))

    # Matriz de desplazamiento para el canal CIAN (derecha)
    # [1, 0, shift] -> mover en X positivo
    M_right = np.float32([[1, 0, shift_amount], [0, 1, 0]])
    gray_shifted_right = cv2.warpAffine(gray, M_right, (cols, rows))

    # 3. Combinar canales (Efecto Anaglifo/Glitch)
    # OpenCV usa formato BGR: Canal 0 = Azul, Canal 1 = Verde, Canal 2 = Rojo
    
    # Crear imagen vacía de 3 canales
    glitch_img = np.zeros((rows, cols, 3), dtype=np.uint8)

    # Asignar imagen desplazada a la derecha a los canales Azul y Verde (Cian = B+G)
    glitch_img[:, :, 0] = gray_shifted_right # Azul
    glitch_img[:, :, 1] = gray_shifted_right # Verde

    # Asignar imagen desplazada a la izquierda al canal Rojo
    glitch_img[:, :, 2] = gray_shifted_left  # Rojo

    # 4. Guardar resultado
    cv2.imwrite(output_path, glitch_img)
    print(f"Imagen con efecto Glitch 3D guardada: {output_path}")

    # Opcional: Mostrar (comentado para evitar bloqueo)
    # cv2.imshow("Glitch 3D", glitch_img)
    # cv2.waitKey(0)
    # cv2.destroyAllWindows()

if __name__ == "__main__":
    # Primera imagen
    input_image_1 = r"C:\Users\pinzo\Documents\GitHub\UMNG\Realidad_VR\bomber3d.jpeg"
    output_image_1 = "glitch_3d_result.jpg"
    print(f"Procesando {input_image_1}...")
    create_glitch_3d_effect(input_image_1, output_image_1, shift_amount=15)
    
    # Segunda imagen
    input_image_2 = r"C:\Users\pinzo\Documents\GitHub\UMNG\Realidad_VR\umngbom.jpeg"
    output_image_2 = "glitch_3d_umngbom.jpg"
    print(f"Procesando {input_image_2}...")
    create_glitch_3d_effect(input_image_2, output_image_2, shift_amount=15)