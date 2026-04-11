import tensorflow as tf
from tensorflow.keras.models import Sequential, load_model
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import os
import numpy as np
from tensorflow.keras.preprocessing import image
import customtkinter as ctk
from PIL import Image
import threading
from tkinter import filedialog, messagebox

# ==============================================================================
# CONFIGURACIÓN DEL DATASET Y PARÁMETROS
# ==============================================================================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(BASE_DIR, 'dataset_barcos')
TRAIN_DIR = os.path.join(DATASET_DIR, 'train')
VAL_DIR = os.path.join(DATASET_DIR, 'val')
MODEL_PATH = os.path.join(BASE_DIR, 'modelo_satelite_barcos.h5')
CLASSES_PATH = os.path.join(BASE_DIR, 'indices_clases.npy')

IMG_HEIGHT, IMG_WIDTH = 128, 128
BATCH_SIZE = 32
EPOCHS = 10 # Reducido para pruebas rápidas
NUM_CLASSES = 3

# ==============================================================================
# LÓGICA DEL MODELO
# ==============================================================================

def crear_estructura_directorios():
    carpetas = ['no_barco', 'barco_navegando', 'barco_en_puerto']
    for split in ['train', 'val']:
        for carpeta in carpetas:
            os.makedirs(os.path.join(DATASET_DIR, split, carpeta), exist_ok=True)
    return DATASET_DIR

def build_model():
    model = Sequential([
        Conv2D(32, (3, 3), activation='relu', input_shape=(IMG_HEIGHT, IMG_WIDTH, 3)),
        MaxPooling2D(2, 2),
        Conv2D(64, (3, 3), activation='relu'),
        MaxPooling2D(2, 2),
        Conv2D(128, (3, 3), activation='relu'),
        MaxPooling2D(2, 2),
        Flatten(),
        Dense(256, activation='relu'),
        Dropout(0.5),
        Dense(NUM_CLASSES, activation='softmax')
    ])
    model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
    return model

# ==============================================================================
# INTERFAZ GRÁFICA (GUI)
# ==============================================================================

class App(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("Sistema de Clasificación Satelital de Barcos")
        self.geometry("900x600")
        
        # Configurar el sistema de cuadrícula responsiva
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        # --- BARRA LATERAL ---
        self.sidebar_frame = ctk.CTkFrame(self, width=200, corner_radius=0)
        self.sidebar_frame.grid(row=0, column=0, sticky="nsew")
        self.sidebar_frame.grid_rowconfigure(4, weight=1)

        self.logo_label = ctk.CTkLabel(self.sidebar_frame, text="IA Barcos", font=ctk.CTkFont(size=20, weight="bold"))
        self.logo_label.grid(row=0, column=0, padx=20, pady=(20, 10))

        self.train_button = ctk.CTkButton(self.sidebar_frame, text="Entrenar Modelo", command=self.start_training_thread)
        self.train_button.grid(row=1, column=0, padx=20, pady=10)

        self.predict_button = ctk.CTkButton(self.sidebar_frame, text="Predecir Imagen", command=self.load_and_predict)
        self.predict_button.grid(row=2, column=0, padx=20, pady=10)

        self.dir_button = ctk.CTkButton(self.sidebar_frame, text="Ver Directorios", command=lambda: os.startfile(DATASET_DIR))
        self.dir_button.grid(row=3, column=0, padx=20, pady=10)

        self.appearance_mode_label = ctk.CTkLabel(self.sidebar_frame, text="Apariencia:", anchor="w")
        self.appearance_mode_label.grid(row=5, column=0, padx=20, pady=(10, 0))
        self.appearance_mode_optionemenu = ctk.CTkOptionMenu(self.sidebar_frame, values=["Dark", "Light", "System"], command=self.change_appearance_mode)
        self.appearance_mode_optionemenu.grid(row=6, column=0, padx=20, pady=(10, 20))

        # --- PANEL PRINCIPAL ---
        self.main_frame = ctk.CTkFrame(self, corner_radius=15)
        self.main_frame.grid(row=0, column=1, padx=20, pady=20, sticky="nsew")
        self.main_frame.grid_columnconfigure(0, weight=1)
        self.main_frame.grid_rowconfigure(1, weight=1)

        self.status_label = ctk.CTkLabel(self.main_frame, text="Estado: Listo", font=ctk.CTkFont(size=14))
        self.status_label.grid(row=0, column=0, padx=20, pady=10)

        self.textbox = ctk.CTkTextbox(self.main_frame, width=250)
        self.textbox.grid(row=1, column=0, padx=20, pady=10, sticky="nsew")
        
        self.progress_bar = ctk.CTkProgressBar(self.main_frame)
        self.progress_bar.grid(row=2, column=0, padx=20, pady=10, sticky="ew")
        self.progress_bar.set(0)

        # Crear estructura inicial
        crear_estructura_directorios()
        self.log("Directorios listos. Coloca imágenes en 'dataset_barcos' para entrenar.")

    def log(self, message):
        self.textbox.insert("end", f"> {message}\n")
        self.textbox.see("end")

    def change_appearance_mode(self, new_appearance_mode: str):
        ctk.set_appearance_mode(new_appearance_mode)

    def start_training_thread(self):
        thread = threading.Thread(target=self.train_model)
        thread.daemon = True
        thread.start()

    def train_model(self):
        self.train_button.configure(state="disabled")
        self.status_label.configure(text="Estado: Entrenando...")
        self.progress_bar.set(0.2)
        
        try:
            train_datagen = ImageDataGenerator(rescale=1./255, horizontal_flip=True, fill_mode='nearest')
            val_datagen = ImageDataGenerator(rescale=1./255)

            train_generator = train_datagen.flow_from_directory(TRAIN_DIR, target_size=(128, 128), batch_size=32, class_mode='categorical')
            val_generator = val_datagen.flow_from_directory(VAL_DIR, target_size=(128, 128), batch_size=32, class_mode='categorical')

            if train_generator.samples == 0:
                self.log("ERROR: No hay imágenes en la carpeta de entrenamiento.")
                messagebox.showwarning("Faltan Datos", "Asegúrate de poner imágenes en la carpeta 'dataset_barcos/train'.")
                return

            self.log(f"Iniciando entrenamiento con {train_generator.samples} imágenes...")
            np.save(CLASSES_PATH, train_generator.class_indices)
            
            model = build_model()
            self.progress_bar.set(0.5)
            
            model.fit(train_generator, epochs=EPOCHS, validation_data=val_generator)
            model.save(MODEL_PATH)
            
            self.log("¡Entrenamiento completado!")
            self.progress_bar.set(1)
            messagebox.showinfo("Éxito", "El modelo se ha entrenado y guardado correctamente.")
        except Exception as e:
            self.log(f"Error: {str(e)}")
        finally:
            self.train_button.configure(state="normal")
            self.status_label.configure(text="Estado: Listo")

    def load_and_predict(self):
        if not os.path.exists(MODEL_PATH):
            messagebox.showerror("Error", "Primero debes entrenar el modelo.")
            return

        file_path = filedialog.askopenfilename(filetypes=[("Archivos de imagen", "*.jpg *.png *.jpeg")])
        if file_path:
            self.status_label.configure(text="Estado: Procesando imagen...")
            try:
                model = load_model(MODEL_PATH)
                img = image.load_img(file_path, target_size=(128, 128))
                img_array = image.img_to_array(img)
                img_array = np.expand_dims(img_array, axis=0) / 255.0
                
                preds = model.predict(img_array)
                idx = np.argmax(preds[0])
                conf = preds[0][idx] * 100
                
                if os.path.exists(CLASSES_PATH):
                    classes = np.load(CLASSES_PATH, allow_pickle=True).item()
                    name = [k for k, v in classes.items() if v == idx][0]
                else:
                    name = "Clase Desconocida"

                res_msg = f"Predicción: {name} ({conf:.2f}%)"
                self.log(res_msg)
                messagebox.showinfo("Resultado", res_msg)
            except Exception as e:
                self.log(f"Error en predicción: {str(e)}")
            self.status_label.configure(text="Estado: Listo")

if __name__ == "__main__":
    ctk.set_appearance_mode("Dark")
    ctk.set_default_color_theme("blue")
    app = App()
    app.mainloop()
