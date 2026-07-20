import snap7
from snap7.util import *
from snap7.type import Areas
import sys

PLC_IP = "192.168.0.1"
RACK = 0
SLOT = 1

plc = snap7.client.Client()
print("Intentando conectar a", PLC_IP)
try:
    plc.connect(PLC_IP, RACK, SLOT)
    if plc.get_connected():
        print("¡Conexión física EXITOSA!")
    else:
        print("No se pudo conectar.")
        sys.exit(1)
except Exception as e:
    print("Error al conectar:", e)
    sys.exit(1)

# Probar lectura de Merkers (MK)
print("\n--- Probando lectura de Merkers (Memoria M) ---")
try:
    data_mk = plc.read_area(Areas.MK, 0, 0, 10)
    print("Lectura de Merkers (M0.0 a M9.7) EXITOSA. Bytes:", list(data_mk))
except Exception as e:
    print("Fallo al leer Merkers:", e)

# Probar lectura de DB1 con diferentes tamaños
print("\n--- Probando lectura de DB1 ---")
for size in [1, 2, 4, 8]:
    try:
        data_db = plc.read_area(Areas.DB, 1, 0, size)
        print(f"Lectura de DB1 (tamaño {size} bytes) EXITOSA. Bytes:", list(data_db))
    except Exception as e:
        print(f"Fallo al leer DB1 con tamaño {size}:", e)

# Probar lectura de otros DBs comunes (DB2, DB3)
for db_num in [2, 3]:
    print(f"\n--- Probando lectura de DB{db_num} ---")
    try:
        data_db = plc.read_area(Areas.DB, db_num, 0, 2)
        print(f"Lectura de DB{db_num} (2 bytes) EXITOSA. Bytes:", list(data_db))
    except Exception as e:
        print(f"Fallo al leer DB{db_num}:", e)

plc.disconnect()
print("\nDesconectado del PLC.")
