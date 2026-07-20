import snap7
from snap7.util import get_bool, get_int
from snap7.type import Areas
import psycopg2
import time
from datetime import datetime

# =========================================================
# CONFIGURACIÓN PLC
# =========================================================

PLC_IP = "192.168.0.1"
RACK = 0
SLOT = 1

# =========================================================
# CONFIGURACIÓN BASE DE DATOS
# =========================================================

DB_HOST = "aws-1-us-west-2.pooler.supabase.com"
DB_NAME = "postgres"
DB_USER = "postgres.wbjtcfbvucdlbdkjljkt"
DB_PASSWORD = "Suzuyuu3112"
DB_PORT = "5432"

# =========================================================
# CONEXIÓN PLC
# =========================================================

plc = snap7.client.Client()

print("=========================================")
print("Conectando al PLC...")
print("=========================================")

try:

    plc.connect(PLC_IP, RACK, SLOT)

    if plc.get_connected():
        print("Conexión exitosa con el PLC")
    else:
        print("No fue posible conectar con el PLC")
        exit()

    # =========================================================
    # CONEXIÓN BASE DE DATOS
    # =========================================================

    print("\nConectando a la base de datos...")

    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=DB_PORT
    )

    cursor = conn.cursor()

    print("Conexión exitosa con PostgreSQL")

    # =========================================================
    # CREAR TABLA SI NO EXISTE
    # =========================================================

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS estado_plc (

            id SERIAL PRIMARY KEY,
            fecha TIMESTAMP,

            start BOOLEAN,
            stop BOOLEAN,
            pe BOOLEAN,
            motor_banda BOOLEAN,

            metal BOOLEAN,
            vidrio BOOLEAN,
            plastico BOOLEAN,

            metal_ok BOOLEAN,
            vidrio_ok BOOLEAN,
            plastico_ok BOOLEAN,

            count_metal INTEGER,
            count_vidrio INTEGER,
            count_plastico INTEGER,

            alarma_startnopresence BOOLEAN,
            alarma_inicio BOOLEAN,
            alarma_final BOOLEAN,
            alarma_pe BOOLEAN
        )
    """)

    conn.commit()

    print("Tabla verificada correctamente")

    # =========================================================
    # LECTURA CONTINUA PLC
    # =========================================================

    print("\nIniciando adquisición de datos...\n")

    while True:

        # -----------------------------------------------------
        # LECTURA DE MARCAS
        # -----------------------------------------------------

        # Leer MB0 hasta MB10
        data = plc.read_area(Areas.MK, 0, 0, 11)

        # -----------------------------------------------------
        # VARIABLES BOOLEANAS
        # -----------------------------------------------------

        start = get_bool(data, 3, 4)
        stop = get_bool(data, 3, 5)
        pe = get_bool(data, 3, 6)
        motor_banda = get_bool(data, 3, 7)

        metal = get_bool(data, 0, 2)
        vidrio = get_bool(data, 0, 3)
        plastico = get_bool(data, 0, 4)

        metal_ok = get_bool(data, 1, 0)
        vidrio_ok = get_bool(data, 1, 2)
        plastico_ok = get_bool(data, 1, 4)

        alarma_startnopresence = get_bool(data, 10, 0)
        alarma_inicio = get_bool(data, 10, 1)
        alarma_final = get_bool(data, 10, 2)
        alarma_pe = get_bool(data, 10, 3)

        # -----------------------------------------------------
        # VARIABLES ENTERAS (MW)
        # -----------------------------------------------------

        count_metal = get_int(data, 4)
        count_vidrio = get_int(data, 6)
        count_plastico = get_int(data, 8)

        # -----------------------------------------------------
        # MOSTRAR EN CONSOLA
        # -----------------------------------------------------

        print("=========================================")
        print("Fecha:", datetime.now())

        print(f"Start: {start}")
        print(f"Stop: {stop}")
        print(f"PE: {pe}")
        print(f"Motor_Banda: {motor_banda}")

        print(f"Metal: {metal}")
        print(f"Vidrio: {vidrio}")
        print(f"Plastico: {plastico}")

        print(f"Metal_OK: {metal_ok}")
        print(f"Vidrio_OK: {vidrio_ok}")
        print(f"Plastico_OK: {plastico_ok}")

        print(f"Count_Metal: {count_metal}")
        print(f"Count_Vidrio: {count_vidrio}")
        print(f"Count_Plastico: {count_plastico}")

        print(f"Alarma_StartNoPresence: {alarma_startnopresence}")
        print(f"Alarma_Inicio: {alarma_inicio}")
        print(f"Alarma_Final: {alarma_final}")
        print(f"Alarma_PE: {alarma_pe}")

        # -----------------------------------------------------
        # GUARDAR EN BASE DE DATOS
        # -----------------------------------------------------

        cursor.execute("""

            INSERT INTO estado_plc (

                fecha,

                start,
                stop,
                pe,
                motor_banda,

                metal,
                vidrio,
                plastico,

                metal_ok,
                vidrio_ok,
                plastico_ok,

                count_metal,
                count_vidrio,
                count_plastico,

                alarma_startnopresence,
                alarma_inicio,
                alarma_final,
                alarma_pe

            )

            VALUES (

                %s,

                %s,
                %s,
                %s,
                %s,

                %s,
                %s,
                %s,

                %s,
                %s,
                %s,

                %s,
                %s,
                %s,

                %s,
                %s,
                %s,
                %s
            )

        """, (

            datetime.now(),

            start,
            stop,
            pe,
            motor_banda,

            metal,
            vidrio,
            plastico,

            metal_ok,
            vidrio_ok,
            plastico_ok,

            count_metal,
            count_vidrio,
            count_plastico,

            alarma_startnopresence,
            alarma_inicio,
            alarma_final,
            alarma_pe

        ))

        conn.commit()

        print("\nDatos guardados en PostgreSQL correctamente")
        print("=========================================\n")

        time.sleep(1)

# =========================================================
# MANEJO DE ERRORES
# =========================================================

except KeyboardInterrupt:
    print("\nPrograma detenido por el usuario")

except Exception as e:
    print("\nERROR:", e)

finally:

    try:
        cursor.close()
        conn.close()
        print("Base de datos desconectada")
    except:
        pass

    try:
        plc.disconnect()
        print("PLC desconectado")
    except:
        pass
