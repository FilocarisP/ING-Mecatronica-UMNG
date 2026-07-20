import snap7
from snap7.util import get_bool, get_int
from snap7.type import Areas
import tkinter as tk
import threading

# ==========================================
# PLC CONFIG
# ==========================================
PLC_IP = "192.168.0.1"
RACK = 0
SLOT = 1

plc = snap7.client.Client()
plc.connect(PLC_IP, RACK, SLOT)

if not plc.get_connected():
    print("Error de conexión PLC")
    exit()

# ==========================================
# FUNCIONES LECTURA
# ==========================================
def read_bit(byte, bit):
    data = plc.read_area(Areas.MK, 0, byte, 1)
    return get_bool(data, 0, bit)

def read_int(byte):
    data = plc.read_area(Areas.MK, 0, byte, 2)
    return get_int(data, 0)

# ==========================================
# UI BASE
# ==========================================
root = tk.Tk()
root.title("SCADA - BANDA TRANSPORTADORA")
root.geometry("850x600")
root.configure(bg="#0f172a")  # fondo oscuro industrial

# ==========================================
# HEADER
# ==========================================
header = tk.Label(
    root,
    text="MONITOREO INDUSTRIAL - BANDA TRANSPORTADORA",
    font=("Arial", 18, "bold"),
    bg="#0f172a",
    fg="white"
)
header.pack(pady=10)

# ==========================================
# ESTILO LED
# ==========================================
def create_led(parent, text, row, col):
    frame = tk.Frame(parent, bg="#0f172a")
    frame.grid(row=row, column=col, padx=20, pady=10)

    lbl_text = tk.Label(frame, text=text, font=("Arial", 10), bg="#0f172a", fg="white")
    lbl_text.pack()

    canvas = tk.Canvas(frame, width=25, height=25, bg="#0f172a", highlightthickness=0)
    canvas.pack()

    led = canvas.create_oval(5, 5, 20, 20, fill="red")

    return canvas, led

def set_led(canvas, led, state):
    color = "lime green" if state else "red"
    canvas.itemconfig(led, fill=color)

# ==========================================
# SECCIONES
# ==========================================
frame_top = tk.Frame(root, bg="#0f172a")
frame_top.pack()

frame_mid = tk.Frame(root, bg="#0f172a")
frame_mid.pack()

frame_bot = tk.Frame(root, bg="#0f172a")
frame_bot.pack(pady=20)

# ==========================================
# INDICADORES
# ==========================================
signals = {}

# Sensores
signals["Start"] = create_led(frame_top, "START", 0, 0)
signals["Stop"] = create_led(frame_top, "STOP", 0, 1)
signals["PE"] = create_led(frame_top, "PE", 0, 2)
signals["Motor_Banda"] = create_led(frame_top, "MOTOR", 0, 3)

signals["Metal"] = create_led(frame_mid, "METAL", 0, 0)
signals["Vidrio"] = create_led(frame_mid, "VIDRIO", 0, 1)
signals["Plastico"] = create_led(frame_mid, "PLASTICO", 0, 2)

signals["Metal_OK"] = create_led(frame_mid, "METAL OK", 1, 0)
signals["Vidrio_OK"] = create_led(frame_mid, "VIDRIO OK", 1, 1)
signals["Plastico_OK"] = create_led(frame_mid, "PLASTICO OK", 1, 2)

# Alarmas
signals["Alarma_StartNoPresence"] = create_led(frame_bot, "AL START", 0, 0)
signals["Alarma_Inicio"] = create_led(frame_bot, "AL INICIO", 0, 1)
signals["Alarma_Final"] = create_led(frame_bot, "AL FINAL", 0, 2)
signals["Alarma_PE"] = create_led(frame_bot, "AL PE", 0, 3)

# ==========================================
# CONTADORES
# ==========================================
counter_label = tk.Label(
    root,
    text="CONTADORES",
    font=("Arial", 14, "bold"),
    bg="#0f172a",
    fg="white"
)
counter_label.pack(pady=10)

counter_values = tk.Label(
    root,
    text="",
    font=("Consolas", 12),
    bg="#0f172a",
    fg="lime"
)
counter_values.pack()

# ==========================================
# LOOP ACTUALIZACIÓN
# ==========================================
def update():

    try:
        values = {
            "Start": read_bit(3, 4),
            "Stop": read_bit(3, 5),
            "PE": read_bit(3, 6),
            "Motor_Banda": read_bit(3, 7),

            "Metal": read_bit(0, 2),
            "Vidrio": read_bit(0, 3),
            "Plastico": read_bit(0, 4),

            "Metal_OK": read_bit(1, 0),
            "Vidrio_OK": read_bit(1, 2),
            "Plastico_OK": read_bit(1, 4),

            "Alarma_StartNoPresence": read_bit(10, 0),
            "Alarma_Inicio": read_bit(10, 1),
            "Alarma_Final": read_bit(10, 2),
            "Alarma_PE": read_bit(10, 3),
        }

        for k, v in values.items():
            canvas, led = signals[k]
            set_led(canvas, led, v)

        metal = read_int(4)
        vidrio = read_int(6)
        plastico = read_int(8)

        counter_values.config(
            text=f"METAL: {metal}   |   VIDRIO: {vidrio}   |   PLASTICO: {plastico}"
        )

    except Exception as e:
        print("Error PLC:", e)

    root.after(800, update)

update()
root.mainloop()

plc.disconnect()
