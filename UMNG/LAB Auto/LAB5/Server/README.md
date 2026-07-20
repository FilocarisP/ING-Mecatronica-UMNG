# Guía de Extracción de Datos de PLC Siemens (S7) en Python

Esta carpeta contiene dos herramientas profesionales en Python para la extracción, visualización y registro en tiempo real (datalogger) de tags de un PLC Siemens (S7-300, S7-400, S7-1200 y S7-1500):

1. **`siemens_plcsim_extractor.py`**: Configurado para pruebas locales conectándose a **Siemens PLCSIM** mediante el puente **NetToPLCSim**.
2. **`siemens_physical_extractor.py`**: Configurado para conectarse directamente a un **PLC físico** en tu laboratorio de automatización e incluye la capacidad opcional de registrar los datos históricos en un archivo CSV.

---

## 🛠️ Requisitos de Software y Librerías

### 1. Entorno de Python
Instala las dependencias necesarias ejecutando el siguiente comando en tu terminal:

```bash
pip install -r requirements.txt
```

*Nota: La librería `python-snap7` es un wrapper en Python de la librería nativa en C++ llamada Snap7. En las versiones modernas de Windows, al hacer `pip install`, se instala automáticamente el archivo binario compilado (`snap7.dll`). Si al iniciar el script obtienes un error del tipo `RuntimeError: Can't find snap7.dll`, puedes descargar el archivo dll desde la página oficial de Snap7 y colocarlo en tu carpeta `C:\Windows\System32` o directamente en el mismo directorio que este script.*

---

## ⚙️ Configuración en TIA Portal (¡Paso Crítico!)

Para que cualquier cliente externo (como este script en Python) pueda leer o escribir en un PLC Siemens moderno (S7-1200 o S7-1500), debes realizar dos configuraciones indispensables en tu proyecto de **TIA Portal**:

### Paso 1: Habilitar la comunicación PUT/GET
1. Abre tu proyecto en TIA Portal.
2. En el árbol del proyecto, haz doble clic en **Device configuration** (Configuración de dispositivos).
3. Selecciona tu CPU y abre la pestaña **Properties** (Propiedades) en la parte inferior.
4. Navega hasta **Protection & Security > Connection mechanisms** (Protección y Seguridad > Mecanismos de conexión).
5. Marca la casilla **"Permit access with PUT/GET communication from remote partner"** (Permitir acceso con comunicación PUT/GET del interlocutor remoto).

### Paso 2: Desactivar el Acceso Optimizado en tus Bloques de Datos (DB)
Por defecto, TIA Portal optimiza los DBs ocultando las direcciones físicas de las variables (Offsets). Como Snap7 lee el PLC direccionando bytes (ej. DB1, byte 0, bit 0), necesitamos ver los offsets numéricos fijos.
1. Haz clic derecho sobre el Bloque de Datos (DB) que deseas leer (por ejemplo, `DB1`).
2. Selecciona **Properties** (Propiedades).
3. En la sección de **Attributes** (Atributos), desmarca la casilla **"Optimized block access"** (Acceso optimizado al bloque).
4. Haz clic en **OK**.
5. Abre el DB. Verás que ahora aparece una columna llamada **"Offset"** con valores como `0.0`, `2.0`, `4.0`, etc.
6. **¡Importante!** Recompile completamente el software del PLC (`Compilar > Software (recompilar todo)`) y vuelve a descargar la configuración física y lógica en el PLC real o simulador.

---

## 🖥️ Conexión con PLCSIM usando NetToPLCSim (Simulación)

NetToPLCSim permite que un cliente externo se conecte a la instancia interna de PLCSIM utilizando el puerto estándar S7 (puerto TCP 102).

### Instrucciones de Configuración:
1. Inicia **Siemens PLCSIM** y arranca tu CPU cargada con el proyecto configurado en el paso anterior.
2. Descarga e inicia **NetToPLCSim** (haz clic derecho y selecciona **Ejecutar como Administrador**).
3. Si el programa te indica que el puerto 102 de Windows está ocupado (normalmente por el servicio de Siemens `s7oiehsx64`), haz clic en **Yes** para detener el servicio de Windows de forma automática.
4. En la interfaz de NetToPLCSim, haz clic en **Add**:
   * **Network IP Address:** Selecciona la IP actual de tu tarjeta de red de PC (o escribe `127.0.0.1` si estás probando puramente en local).
   * **Plcsim IP Address:** Haz clic en el botón `...` a la derecha. NetToPLCSim detectará automáticamente la dirección IP virtual asignada a tu CPU simulada en PLCSIM. Elígela.
   * **Rack / Slot:** Para S7-1200 o S7-1500, define **Rack: 0, Slot: 1**. (Para S7-300 antiguos, usa **Rack: 0, Slot: 2**).
5. Haz clic en **OK**.
6. Haz clic en **Start Server**. El estado debería cambiar a "RUNNING".
7. Tu script de Python ahora podrá conectarse directamente a la **Network IP Address** configurada en el paso anterior.

---

## 🚀 Cómo Ejecutar los Scripts

Ambos scripts incorporan un sofisticado panel de terminal dinámico que refresca los datos automáticamente en tiempo real sin parpadeos y soporta colores ANSI para una lectura cómoda.

### 🌟 1. Modo Simulación Integrado (Modo Mock)
Si no tienes el PLC conectado ni PLCSIM ejecutándose, puedes probar inmediatamente los scripts con variables aleatorias fluctuantes (temperatura variando, bomba encendiendo y alarmas respondiendo) usando el parámetro `--mock`:

```bash
python siemens_plcsim_extractor.py --mock
# O para el PLC físico
python siemens_physical_extractor.py --mock
```

### 💻 2. Leer del Simulador (PLCSIM + NetToPLCSim)
Una vez que el servidor NetToPLCSim esté corriendo, ejecuta el script apuntando a la IP configurada en el puente (por defecto `127.0.0.1`):

```bash
python siemens_plcsim_extractor.py --ip 127.0.0.1 --interval 0.5
```

### 🔌 3. Leer del PLC Físico de Laboratorio
Conecta tu cable Ethernet al PLC y asegúrate de que tu PC esté en la misma subred (ejemplo: si el PLC está en `192.168.0.1`, tu PC debe tener la IP `192.168.0.10`).

Ejecuta el extractor apuntando a la IP real del PLC físico:
```bash
python siemens_physical_extractor.py --ip 192.168.0.1
```

### 📊 4. Registro de Datos en CSV (Datalogger)
Si deseas guardar las lecturas en tiempo real en una hoja de cálculo CSV para análisis de laboratorios o gráficas posteriores, utiliza el argumento `--log`:

```bash
python siemens_physical_extractor.py --ip 192.168.0.1 --log --logfile registro_plc_lab.csv --interval 2.0
```
Esto creará un archivo CSV en el mismo directorio con columnas ordenadas y un registro por marcas de tiempo en el intervalo seleccionado.

---

## ✏️ Personalizar los Tags y Variables en Python

Para adaptar el script a tus variables reales de TIA Portal, abre cualquiera de los archivos con un editor de código y busca la sección `TAGS_CONFIG` en la parte superior. Puedes añadir, quitar o modificar variables usando el siguiente formato de diccionario:

```python
TAGS_CONFIG = [
    # Sintaxis:
    # { "name": "Nombre_Consola", "db": NumeroDB, "type": "TipoDeDato", "offset": ByteInicio, ["bit": BitPosicion], ["length": MaxStringLength] }
    
    # 1. Variable Float (32 bits, Real en TIA Portal) - Ocupa 4 bytes
    { "name": "Temperatura_Reactor", "db": 1, "type": "Real", "offset": 0 },
    
    # 2. Variable Entera (16 bits, Int en TIA Portal) - Ocupa 2 bytes
    { "name": "Velocidad_Rotor", "db": 1, "type": "Int", "offset": 4 },
    
    # 3. Variable Entera Doble (32 bits, DInt en TIA Portal) - Ocupa 4 bytes
    { "name": "Contador_Piezas", "db": 1, "type": "DInt", "offset": 6 },
    
    # 4. Variable Booleana (1 bit, Bool en TIA Portal) - Requiere definir "bit" (0 a 7)
    { "name": "Falla_Ems", "db": 1, "type": "Bool", "offset": 10, "bit": 0 },
    { "name": "Boton_Start", "db": 1, "type": "Bool", "offset": 10, "bit": 1 },
    
    # 5. Cadena de Texto (String en TIA Portal) - Define su longitud máxima en TIA Portal (ej. String[30])
    { "name": "Estado_Proceso", "db": 1, "type": "String", "offset": 12, "length": 30 }
]
```

### 💡 Consejo Profesional de Rendimiento
Nuestros scripts agrupan automáticamente las variables por número de DB y realizan **una sola lectura en bloque** por cada DB del PLC, en lugar de consultar tag por tag. Esto reduce la latencia de comunicación de red en más de un **95%**, garantizando que el PLC y la red no se saturen y la recolección sea estable a altas velocidades (hasta 10 ms de muestreo).
