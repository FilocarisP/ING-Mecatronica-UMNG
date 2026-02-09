import os
from PIL import Image

def generate_vr_images(left_path, right_path, output_dir):
    """
    Generates parallel and cross-view VR images (horizontal and vertical).
    
    Args:
        left_path (str): Path to the left eye image (IZQ).
        right_path (str): Path to the right eye image (DER).
        output_dir (str): Directory where the output images will be saved.
    """
    # Verify input paths
    if not os.path.exists(left_path):
        print(f"Error: La imagen izquierda no existe: {left_path}")
        return
    if not os.path.exists(right_path):
        print(f"Error: La imagen derecha no existe: {right_path}")
        return

    # Ensure output directory exists
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Directorio creado: {output_dir}")

    try:
        img_left = Image.open(left_path)
        img_right = Image.open(right_path)
    except Exception as e:
        print(f"Error al abrir las imágenes: {e}")
        return

    # --- Horizontal Views (Side-by-Side) ---
    # Resize right image to match left image's height for horizontal stacking
    # We maintain aspect ratio of right image, but scale it to match left height
    # Or, simpler: maximize/minimize size? Usually VR demands exact dimensions.
    # Let's resize both to the smaller height of the two for consistency, or just match height.
    # A common approach is to resize the right image to match the left image's dimensions exactly if they differ significantly.
    # However, for VR, usually same resolution is best.
    # Let's resize right to match left.
    
    target_size = img_left.size # (width, height)
    width, height = target_size
    
    # Resize right to match left dimensions if they differ
    if img_right.size != target_size:
        img_right = img_right.resize(target_size, Image.Resampling.LANCZOS)

    # --- Horizontal Views (Side-by-Side) ---
    # Para que la imagen final sea del mismo tamaño que la original,
    # debemos comprimir el ancho de cada imagen a la mitad.
    half_width = width // 2
    img_left_h = img_left.resize((half_width, height), Image.Resampling.LANCZOS)
    img_right_h = img_right.resize((half_width, height), Image.Resampling.LANCZOS)

    # 1. Vista Paralela (Parallel View): Left | Right
    parallel_img = Image.new('RGB', (width, height))
    parallel_img.paste(img_left_h, (0, 0))
    parallel_img.paste(img_right_h, (half_width, 0))
    parallel_path = os.path.join(output_dir, "vista_paralela.jpg")
    parallel_img.save(parallel_path)
    print(f"Guardado: {parallel_path} (Tamaño: {parallel_img.size})")

    # 2. Vista Cruzada (Cross View): Right | Left
    cross_img = Image.new('RGB', (width, height))
    cross_img.paste(img_right_h, (0, 0))
    cross_img.paste(img_left_h, (half_width, 0))
    cross_path = os.path.join(output_dir, "vista_cruzada.jpg")
    cross_img.save(cross_path)
    print(f"Guardado: {cross_path} (Tamaño: {cross_img.size})")

    # --- Vertical Views (Top-Bottom) ---
    # Para que la imagen final sea del mismo tamaño que la original,
    # debemos comprimir el alto de cada imagen a la mitad.
    half_height = height // 2
    img_left_v = img_left.resize((width, half_height), Image.Resampling.LANCZOS)
    img_right_v = img_right.resize((width, half_height), Image.Resampling.LANCZOS)

    # 3. Vista Vertical Paralela (Top-Bottom): Left / Right
    vertical_parallel_img = Image.new('RGB', (width, height))
    vertical_parallel_img.paste(img_left_v, (0, 0))
    vertical_parallel_img.paste(img_right_v, (0, half_height))
    vertical_parallel_path = os.path.join(output_dir, "vista_vertical_paralela.jpg")
    vertical_parallel_img.save(vertical_parallel_path)
    print(f"Guardado: {vertical_parallel_path} (Tamaño: {vertical_parallel_img.size})")

    # 4. Vista Vertical Cruzada (Top-Bottom): Right / Left
    vertical_cross_img = Image.new('RGB', (width, height))
    vertical_cross_img.paste(img_right_v, (0, 0))
    vertical_cross_img.paste(img_left_v, (0, half_height))
    vertical_cross_path = os.path.join(output_dir, "vista_vertical_cruzada.jpg")
    vertical_cross_img.save(vertical_cross_path)
    print(f"Guardado: {vertical_cross_path} (Tamaño: {vertical_cross_img.size})")

if __name__ == "__main__":
    # Rutas definidas por el usuario
    left_image_path = r"C:\Users\pinzo\Documents\GitHub\UMNG\Realidad_VR\IZQ.jpeg"
    right_image_path = r"C:\Users\pinzo\Documents\GitHub\UMNG\Realidad_VR\DER.jpeg"
    output_directory = r"C:\Users\pinzo\Documents\GitHub\UMNG\IA\AntiGravity\notebooks\Realidad"

    print("Iniciando generación de imágenes VR...")
    generate_vr_images(left_image_path, right_image_path, output_directory)
    print("Proceso finalizado.")
