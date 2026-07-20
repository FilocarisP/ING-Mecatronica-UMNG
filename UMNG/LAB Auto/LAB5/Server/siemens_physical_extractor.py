#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Siemens Physical PLC Data Extractor
-----------------------------------
Este script se conecta directamente a un PLC Siemens físico (S7-300, S7-400,
S7-1200, S7-1500) a través de Ethernet utilizando el protocolo S7 (ISO-on-TCP)
y la librería `python-snap7`.

Permite la lectura en tiempo real de tags estructurados en Bloques de Datos (DB),
su visualización en una interfaz de consola premium y el registro de datos (logging)
automático en un archivo CSV.
"""

import sys
import time
import argparse
import random
import os
import csv
from datetime import datetime

# Intentar importar snap7 de forma segura para no romper el modo simulado (mock)
# en entornos que aún no tengan configurada la DLL de snap7.
try:
    import snap7
    from snap7.util import get_bool, get_int, get_dint, get_real, get_string
    SNAP7_AVAILABLE = True
    SNAP7_ERROR = None
except Exception as e:
    SNAP7_AVAILABLE = False
    SNAP7_ERROR = str(e)

# ==============================================================================
# CONFIGURACIÓN DE CONEXIÓN (Predeterminada para PLC Físico)
# ==============================================================================
# Ajusta estos valores a la dirección IP real de tu PLC de laboratorio.
DEFAULT_IP = "192.168.0.1" 
DEFAULT_RACK = 0
DEFAULT_SLOT = 1  # S7-1200 y S7-1500 siempre usan Rack 0, Slot 1. (S7-300 usa Slot 2)

# ==============================================================================
# CONFIGURACIÓN DE TAGS (Mapeo de DB y Offsets)
# ==============================================================================
# Define aquí tus variables físicas. El DB en TIA Portal debe ser NO-OPTIMIZADO.
# ==============================================================================
TAGS_CONFIG = [
    {
        "name": "Temperatura_Horno",
        "db": 1,
        "type": "Real",
        "offset": 0,
        "description": "Temperatura actual de la cámara (°C)"
    },
    {
        "name": "Presion_Tanque",
        "db": 1,
        "type": "Real",
        "offset": 4,
        "description": "Presión interna del reactor (bar)"
    },
    {
        "name": "Velocidad_Motor",
        "db": 1,
        "type": "Int",
        "offset": 8,
        "description": "Velocidad de rotación del agitador (RPM)"
    },
    {
        "name": "Contador_Ciclos",
        "db": 1,
        "type": "DInt",
        "offset": 10,
        "description": "Número total de lotes procesados"
    },
    {
        "name": "Bomba_Alimentacion",
        "db": 1,
        "type": "Bool",
        "offset": 14,
        "bit": 0,
        "description": "Estado de la bomba de entrada"
    },
    {
        "name": "Valvula_Retorno",
        "db": 1,
        "type": "Bool",
        "offset": 14,
        "bit": 1,
        "description": "Válvula solenoide de recirculación"
    },
    {
        "name": "Alarma_Sobrepresion",
        "db": 1,
        "type": "Bool",
        "offset": 14,
        "bit": 2,
        "description": "Alerta crítica de seguridad"
    },
    {
        "name": "Operario_Turno",
        "db": 1,
        "type": "String",
        "offset": 16,
        "length": 30,
        "description": "Operario actualmente registrado"
    }
]

# Estilos de consola (colores ANSI)
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    BG_DARK = '\033[48;5;234m'
    CLEAR = '\033[H\033[J'

def parse_args():
    parser = argparse.ArgumentParser(
        description="Siemens Physical PLC Data Extractor & Datalogger",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--ip", default=DEFAULT_IP, help="Dirección IP del PLC físico")
    parser.add_argument("--rack", type=int, default=DEFAULT_RACK, help="Rack del PLC físico")
    parser.add_argument("--slot", type=int, default=DEFAULT_SLOT, help="Slot del PLC físico (S7-1200/1500=1, S7-300=2)")
    parser.add_argument("--interval", type=float, default=1.0, help="Intervalo de muestreo en segundos")
    parser.add_argument("--mock", action="store_true", help="Forzar modo simulación sin conectarse al PLC real")
    parser.add_argument("--log", action="store_true", help="Guardar datos extraídos automáticamente en un archivo CSV")
    parser.add_argument("--logfile", default="registro_plc.csv", help="Nombre del archivo CSV para el guardado de datos")
    return parser.parse_args()

class PLCExtractor:
    def __init__(self, ip, rack, slot, mock_mode=False):
        self.ip = ip
        self.rack = rack
        self.slot = slot
        self.mock_mode = mock_mode
        self.client = None
        self.connected = False
        
        # Generar datos iniciales simulados para el modo Mock
        self.mock_values = {
            "Temperatura_Horno": 22.5,
            "Presion_Tanque": 0.98,
            "Velocidad_Motor": 0,
            "Contador_Ciclos": 0,
            "Bomba_Alimentacion": False,
            "Valvula_Retorno": False,
            "Alarma_Sobrepresion": False,
            "Operario_Turno": "Lab Automatización"
        }

        # Agrupar tags por DB para optimizar las lecturas
        self.db_groups = {}
        for tag in TAGS_CONFIG:
            db_num = tag["db"]
            if db_num not in self.db_groups:
                self.db_groups[db_num] = []
            self.db_groups[db_num].append(tag)
        
        # Calcular el tamaño a leer para cada DB
        self.db_sizes = {}
        for db_num, tags in self.db_groups.items():
            max_end = 0
            for tag in tags:
                offset = tag["offset"]
                t_type = tag["type"]
                if t_type == "Real" or t_type == "DInt":
                    end_byte = offset + 4
                elif t_type == "Int":
                    end_byte = offset + 2
                elif t_type == "Bool":
                    end_byte = offset + 1
                elif t_type == "String":
                    length = tag.get("length", 254)
                    end_byte = offset + length + 2
                else:
                    end_byte = offset + 1
                
                if end_byte > max_end:
                    max_end = end_byte
            self.db_sizes[db_num] = max_end

    def connect(self):
        if self.mock_mode:
            self.connected = True
            return True
            
        if not SNAP7_AVAILABLE:
            self.mock_mode = True
            self.connected = True
            return True

        try:
            self.client = snap7.client.Client()
            self.client.connect(self.ip, self.rack, self.slot)
            self.connected = self.client.get_connected()
            return self.connected
        except Exception as e:
            self.connected = False
            return False

    def disconnect(self):
        if self.client and not self.mock_mode:
            try:
                self.client.disconnect()
            except:
                pass
        self.connected = False

    def read_all_tags(self):
        results = {}
        
        # Modo SIMULADO (Mock)
        if self.mock_mode:
            self.mock_values["Temperatura_Horno"] += random.uniform(-0.3, 0.4)
            self.mock_values["Temperatura_Horno"] = max(20.0, min(100.0, self.mock_values["Temperatura_Horno"]))
            self.mock_values["Presion_Tanque"] = 1.0 + (self.mock_values["Temperatura_Horno"] - 20.0) * 0.08 + random.uniform(-0.01, 0.01)
            
            if self.mock_values["Presion_Tanque"] < 3.0:
                self.mock_values["Bomba_Alimentacion"] = True
                self.mock_values["Velocidad_Motor"] = min(1200, self.mock_values["Velocidad_Motor"] + random.randint(30, 80))
            elif self.mock_values["Presion_Tanque"] > 5.5:
                self.mock_values["Bomba_Alimentacion"] = False
                self.mock_values["Velocidad_Motor"] = max(0, self.mock_values["Velocidad_Motor"] - random.randint(80, 150))
            
            self.mock_values["Alarma_Sobrepresion"] = self.mock_values["Presion_Tanque"] > 6.0
            
            if random.random() < 0.08:
                self.mock_values["Valvula_Retorno"] = not self.mock_values["Valvula_Retorno"]
            
            if random.random() < 0.03:
                self.mock_values["Contador_Ciclos"] += 1
                
            return {tag["name"]: self.mock_values[tag["name"]] for tag in TAGS_CONFIG}

        # Modo REAL (Snap7)
        if not self.connected:
            raise ConnectionError("Cliente S7 no conectado.")

        try:
            for db_num, tags in self.db_groups.items():
                size = self.db_sizes[db_num]
                db_data = self.client.db_read(db_num, 0, size)
                
                for tag in tags:
                    name = tag["name"]
                    t_type = tag["type"]
                    offset = tag["offset"]
                    
                    if t_type == "Real":
                        results[name] = get_real(db_data, offset)
                    elif t_type == "Int":
                        results[name] = get_int(db_data, offset)
                    elif t_type == "DInt":
                        results[name] = get_dint(db_data, offset)
                    elif t_type == "Bool":
                        bit = tag.get("bit", 0)
                        results[name] = get_bool(db_data, offset, bit)
                    elif t_type == "String":
                        results[name] = get_string(db_data, offset)
                    else:
                        results[name] = None
                        
            return results
        except Exception as e:
            self.connected = False  # Forzar reconexión
            raise e

def print_dashboard(extractor, data, error=None, log_enabled=False, logfile=""):
    print(Colors.CLEAR, end="")
    
    # Cabecera Premium
    print(Colors.HEADER + Colors.BOLD + "=====================================================================" + Colors.ENDC)
    print(Colors.GREEN + Colors.BOLD + "       S7 PLC DATA EXTRACTOR - CONEXIÓN CON PLC FÍSICO" + Colors.ENDC)
    print(Colors.HEADER + Colors.BOLD + "=====================================================================" + Colors.ENDC)
    
    # Estado de la conexión
    mode_str = f" [{Colors.YELLOW}MOCK/SIMULADO{Colors.ENDC}]" if extractor.mock_mode else ""
    status_color = Colors.GREEN if extractor.connected else Colors.RED
    status_str = f"{status_color}CONECTADO{Colors.ENDC}" if extractor.connected else f"{status_color}DESCONECTADO{Colors.ENDC}"
    
    print(f" {Colors.BOLD}Estado:{Colors.ENDC} {status_str}{mode_str}")
    print(f" {Colors.BOLD}Configuración S7:{Colors.ENDC} IP={Colors.BLUE}{extractor.ip}{Colors.ENDC} | Rack={Colors.BLUE}{extractor.rack}{Colors.ENDC} | Slot={Colors.BLUE}{extractor.slot}{Colors.ENDC}")
    
    log_status = f"{Colors.GREEN}ACTIVO ({logfile}){Colors.ENDC}" if log_enabled else f"{Colors.YELLOW}INACTIVO{Colors.ENDC}"
    print(f" {Colors.BOLD}Registro CSV (Datalogger):{Colors.ENDC} {log_status}")
    print(Colors.HEADER + "---------------------------------------------------------------------" + Colors.ENDC)

    if error:
        print(f"\n {Colors.RED}{Colors.BOLD}ERROR DE CONEXIÓN O LECTURA DE RED:{Colors.ENDC}")
        print(f" Detalle: {error}")
        print(f" Reintentando establecer enlace físico en el siguiente ciclo...\n")
        print(Colors.HEADER + "=====================================================================" + Colors.ENDC)
        return

    # Imprimir cabecera de la tabla
    print(f" {Colors.BOLD}{'TAG (Variable)':<26} {'TIPO':<7} {'DIRECCIÓN':<10} {'VALOR':<18}{Colors.ENDC}")
    print(Colors.HEADER + "---------------------------------------------------------------------" + Colors.ENDC)

    # Imprimir cada tag
    for tag in TAGS_CONFIG:
        name = tag["name"]
        t_type = tag["type"]
        db = tag["db"]
        offset = tag["offset"]
        val = data.get(name, "N/A")
        
        # Formatear dirección lógica del tag
        if t_type == "Bool":
            bit = tag.get("bit", 0)
            addr_str = f"DB{db}.DBX{offset}.{bit}"
        elif t_type == "Int":
            addr_str = f"DB{db}.DBW{offset}"
        elif t_type == "DInt":
            addr_str = f"DB{db}.DBD{offset}"
        elif t_type == "Real":
            addr_str = f"DB{db}.DBD{offset}"
        elif t_type == "String":
            addr_str = f"DB{db}.DBB{offset}"
        else:
            addr_str = f"DB{db}.?{offset}"

        # Colorear y formatear valores según tipo
        val_str = str(val)
        if isinstance(val, float):
            val_str = f"{val:.3f}"
            val_color = Colors.CYAN
        elif isinstance(val, bool):
            val_str = "ON" if val else "OFF"
            val_color = Colors.GREEN if val else Colors.YELLOW
            if val and "Alarma" in name:
                val_color = Colors.RED + Colors.BOLD
        elif isinstance(val, int):
            val_color = Colors.BLUE
        else:
            val_color = Colors.ENDC

        print(f" {Colors.BOLD}{name:<26}{Colors.ENDC} {t_type:<7} {addr_str:<10} {val_color}{val_str:<18}{Colors.ENDC}")

    print(Colors.HEADER + "=====================================================================" + Colors.ENDC)
    print(f" Pulse {Colors.BOLD}Ctrl + C{Colors.ENDC} para detener de forma segura.")

def log_to_csv(filename, data):
    file_exists = os.path.isfile(filename)
    # Crear cabecera si el archivo es nuevo
    headers = ["Timestamp"] + [tag["name"] for tag in TAGS_CONFIG]
    
    row = [datetime.now().strftime("%Y-%m-%d %H:%M:%S")]
    for tag in TAGS_CONFIG:
        row.append(data.get(tag["name"], ""))

    with open(filename, mode='a', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        if not file_exists:
            writer.writerow(headers)
        writer.writerow(row)

def main():
    args = parse_args()
    
    # Habilitar soporte de colores ANSI en consolas Windows modernas
    if os.name == 'nt':
        os.system('')

    mock_mode = args.mock
    if not SNAP7_AVAILABLE:
        if not mock_mode:
            mock_mode = True
            print(Colors.YELLOW + Colors.BOLD + "\n[AVISO] La librería 'python-snap7' o su DLL nativa no están instaladas/configuradas." + Colors.ENDC)
            print(f"Detalle del error: {SNAP7_ERROR}")
            print(Colors.CYAN + "El script se iniciará automáticamente en MODO SIMULACIÓN (Mock).\n" + Colors.ENDC)
            time.sleep(3.5)

    extractor = PLCExtractor(args.ip, args.rack, args.slot, mock_mode=mock_mode)

    print(f"Conectando directamente al PLC Siemens físico en {extractor.ip}:{extractor.rack}:{extractor.slot}...")
    
    try:
        while True:
            if not extractor.connected:
                success = extractor.connect()
                if not success:
                    print_dashboard(extractor, {}, error=f"Imposible enlazar con el PLC físico en la IP {extractor.ip}.", log_enabled=args.log, logfile=args.logfile)
                    time.sleep(min(args.interval * 2, 5.0))
                    continue

            try:
                tag_values = extractor.read_all_tags()
                print_dashboard(extractor, tag_values, log_enabled=args.log, logfile=args.logfile)
                
                # Registrar datos en el CSV si la opción --log está habilitada
                if args.log and tag_values:
                    log_to_csv(args.logfile, tag_values)
                    
            except Exception as read_error:
                print_dashboard(extractor, {}, error=str(read_error), log_enabled=args.log, logfile=args.logfile)
                extractor.disconnect()

            time.sleep(args.interval)

    except KeyboardInterrupt:
        print(Colors.YELLOW + f"\n\nDeteniendo extractor físico. Cerrando sockets de red..." + Colors.ENDC)
        extractor.disconnect()
        print(Colors.GREEN + "Conexiones físicas cerradas de forma segura. ¡Datalogger detenido!" + Colors.ENDC)

if __name__ == "__main__":
    main()
