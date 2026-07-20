#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Universidad Militar Nueva Granada
Facultad de Ingeniería - Ingeniería en Mecatrónica
Laboratorio de Automatización - Proyecto Final

Autor: Experto en Control Automático y Programación
Descripción: Simulador interactivo en Python (PyQt6 y Matplotlib) para sustentar
             el sistema de clasificación lineal con pesaje dinámico y control PID activo,
             junto con un Observador de Estados de Luenberger.
             Incluye modo de simulación instantánea, sintonización de PID interactiva,
             algoritmo de auto-sintonización por asignación de polos y enlace en tiempo real
             vía Snap7 con un PLC Siemens S7-1500.
"""

import sys
import numpy as np
from scipy import signal
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                               QHBoxLayout, QPushButton, QComboBox, QLabel, 
                               QTextBrowser, QGroupBox, QFrame, QSplitter,
                               QTabWidget, QLineEdit, QSpinBox, QDoubleSpinBox,
                               QMessageBox, QGridLayout, QDialog, QFileDialog)
from PyQt6.QtCore import QTimer, Qt, QPointF, QRectF
from PyQt6.QtGui import QPainter, QColor, QPen, QBrush, QFont, QPolygonF, QLinearGradient
from PyQt6.QtPrintSupport import QPrinter, QPrintDialog

import matplotlib
matplotlib.use('QtAgg')
from matplotlib.backends.backend_qtagg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure

# Importación segura de snap7 para enlace con PLC real
try:
    import snap7
    from snap7.util import get_bool, get_real, get_int
    SNAP7_AVAILABLE = True
except ImportError:
    SNAP7_AVAILABLE = False

# =============================================================================
# VENTANA EMERGENTE PARA EL MODELAMIENTO MATEMÁTICO (JURADOS)
# =============================================================================
class ModelingDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Modelamiento Físico y Función de Transferencia de la Planta")
        self.resize(820, 680)
        
        if parent:
            self.setStyleSheet(parent.styleSheet())
            
        layout = QVBoxLayout(self)
        layout.setContentsMargins(15, 15, 15, 15)
        layout.setSpacing(12)

        # ── Encabezado ──────────────────────────────────────────────────────────
        header_layout = QHBoxLayout()

        title = QLabel("MODELAMIENTO MATEMÁTICO Y DERIVACIÓN DE LA PLANTA G(s)")
        title.setStyleSheet("font-size: 14px; font-weight: bold; color: #2ecc71; margin-bottom: 5px;")
        header_layout.addWidget(title, stretch=1)

        badge = QLabel("UMNG · Control Automático")
        badge.setStyleSheet(
            "font-size: 9px; color: #a5a5b5; border: 1px solid #444454;"
            "border-radius: 4px; padding: 2px 6px; background-color: #2a2b36;"
        )
        badge.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
        header_layout.addWidget(badge)
        layout.addLayout(header_layout)

        # ── Contenido HTML ───────────────────────────────────────────────────────
        self.browser = QTextBrowser()
        self.browser.setHtml(self.get_modeling_html())
        layout.addWidget(self.browser)

        # ── Barra de botones ─────────────────────────────────────────────────────
        btn_layout = QHBoxLayout()
        btn_layout.setSpacing(10)

        btn_pdf = QPushButton("⬇  Exportar a PDF")
        btn_pdf.setStyleSheet(
            "background-color: #e74c3c; color: #ffffff; font-weight: bold;"
            "padding: 8px 14px; border-radius: 4px; font-size: 10px;"
        )
        btn_pdf.setToolTip("Guarda todo el contenido de esta ventana como archivo PDF")
        btn_pdf.clicked.connect(self.export_to_pdf)
        btn_layout.addWidget(btn_pdf)

        btn_print = QPushButton("🖨  Imprimir")
        btn_print.setStyleSheet(
            "background-color: #007acc; color: #ffffff; font-weight: bold;"
            "padding: 8px 14px; border-radius: 4px; font-size: 10px;"
        )
        btn_print.setToolTip("Abre el diálogo de impresión del sistema")
        btn_print.clicked.connect(self.print_document)
        btn_layout.addWidget(btn_print)

        btn_layout.addStretch()

        btn_close = QPushButton("✕  Cerrar")
        btn_close.setStyleSheet(
            "background-color: #3b3c4d; color: #f0f0f5; font-weight: bold;"
            "padding: 8px 14px; border-radius: 4px; font-size: 10px;"
        )
        btn_close.clicked.connect(self.close)
        btn_layout.addWidget(btn_close)

        layout.addLayout(btn_layout)

    # ── Exportar PDF ────────────────────────────────────────────────────────────
    def export_to_pdf(self):
        """Guarda el contenido del QTextBrowser como archivo PDF (PyQt6)."""
        try:
            file_path, _ = QFileDialog.getSaveFileName(
                self,
                "Guardar Modelamiento como PDF",
                "Modelamiento_Planta_UMNG.pdf",
                "Archivos PDF (*.pdf)"
            )
            if not file_path:
                return
            if not file_path.lower().endswith(".pdf"):
                file_path += ".pdf"

            from PyQt6.QtGui import QPageLayout, QPageSize
            from PyQt6.QtCore import QMarginsF

            printer = QPrinter(QPrinter.PrinterMode.HighResolution)
            printer.setOutputFormat(QPrinter.OutputFormat.PdfFormat)
            printer.setOutputFileName(file_path)

            page_layout = QPageLayout(
                QPageSize(QPageSize.PageSizeId.A4),
                QPageLayout.Orientation.Portrait,
                QMarginsF(15.0, 15.0, 15.0, 15.0),
                QPageLayout.Unit.Millimeter
            )
            printer.setPageLayout(page_layout)

            self.browser.document().print(printer)

            import os
            if os.path.isfile(file_path) and os.path.getsize(file_path) > 0:
                QMessageBox.information(
                    self,
                    "PDF Exportado ✔",
                    f"Archivo guardado exitosamente en:\n{file_path}"
                )
            else:
                QMessageBox.warning(
                    self,
                    "Advertencia",
                    f"El archivo se creó pero parece estar vacío.\nRuta: {file_path}"
                )

        except Exception as e:
            QMessageBox.critical(
                self,
                "Error al exportar PDF",
                f"Ocurrió un error durante la exportación:\n{str(e)}"
            )

    # ── Imprimir ─────────────────────────────────────────────────────────────────
    def print_document(self):
        """Abre el diálogo de impresión estándar del sistema."""
        printer = QPrinter(QPrinter.PrinterMode.HighResolution)
        dialog = QPrintDialog(printer, self)
        if dialog.exec() == QPrintDialog.DialogCode.Accepted:
            self.browser.document().print(printer)
        
    def get_modeling_html(self):
        return """
        <html>
        <body style="font-family:'Segoe UI', Arial, sans-serif; color:#dcdce6; background-color:#1e1e24; font-size:12px; line-height:1.6; padding: 10px;">
            <h3 style="color:#2ecc71; border-bottom:1px solid #444454; padding-bottom:5px; margin-top:0px;">1. SISTEMA FÍSICO: MASA-RESORTE-AMORTIGUADOR</h3>
            <p>
                La estación de pesaje dinámico consta de una plataforma acrílica montada sobre una <b>celda de carga strain-gauge de 5 kg</b>. 
                El impacto vertical que sufre la balanza cuando la botella se detiene bruscamente sobre ella activa una respuesta oscilatoria subamortiguada. 
                Este comportamiento físico se modela mecánicamente como un sistema de segundo orden clásico:
            </p>
            
            <div style="background-color:#2a2b36; padding:10px; border-radius:6px; text-align:center; font-family:'Courier New', monospace; font-size:13px; font-weight:bold; color:#007acc; border:1px solid #444454; margin: 10px 0;">
                m &bull; d²y(t)/dt² + c &bull; dy(t)/dt + k &bull; y(t) = f(t)
            </div>
            
            <p><b>Donde las variables y parámetros mecánicos corresponden a:</b></p>
            <ul>
                <li><b>y(t):</b> Desplazamiento o deflexión vertical de la celda de carga (voltaje de salida de 0 a 10V generado por el transmisor analógico JY-S60).</li>
                <li><b>f(t):</b> Fuerza vertical de entrada aplicada sobre la plataforma (debida al peso de la botella e inercia del impacto).</li>
                <li><b>m:</b> Masa equivalente del conjunto plataforma de pesaje + botella (expresada en kg).</li>
                <li><b>c:</b> Coeficiente de amortiguamiento viscoso interno de la celda de carga y su soporte mecánico (N&bull;s/m).</li>
                <li><b>k:</b> Constante de rigidez elástica a la flexión del cuerpo de aluminio de la celda de carga (N/m).</li>
            </ul>

            <h3 style="color:#2ecc71; border-bottom:1px solid #444454; padding-bottom:5px;">2. TRANSFORMADA DE LAPLACE Y FUNCIÓN DE TRANSFERENCIA</h3>
            <p>
                Para obtener la representación en el dominio de la frecuencia, aplicamos la Transformada de Laplace bajo la suposición de <b>condiciones iniciales nulas</b> (sistema en reposo absoluto antes del impacto: y(0) = 0, y'(0) = 0):
            </p>
            
            <div style="background-color:#2a2b36; padding:10px; border-radius:6px; text-align:center; font-family:'Courier New', monospace; font-size:12px; font-weight:bold; color:#2ecc71; border:1px solid #444454; margin: 10px 0;">
                L { m&bull;d²y(t)/dt² + c&bull;dy(t)/dt + k&bull;y(t) } = L { f(t) } <br><br>
                (m&bull;s² + c&bull;s + k) &bull; Y(s) = F(s)
            </div>
            
            <p>Despejando la relación salida/entrada, obtenemos la <b>Función de Transferencia G(s)</b> de la planta:</p>
            
            <div style="background-color:#2a2b36; padding:10px; border-radius:6px; text-align:center; font-family:'Courier New', monospace; font-size:13px; font-weight:bold; color:#007acc; border:1px solid #444454; margin: 10px 0;">
                G(s) = Y(s) / F(s) = 1 / (m&bull;s² + c&bull;s + k) = (1/m) / [s² + (c/m)&bull;s + (k/m)]
            </div>

            <h3 style="color:#2ecc71; border-bottom:1px solid #444454; padding-bottom:5px;">3. IDENTIFICACIÓN Y PARAMETRIZACIÓN NORMALIZADA</h3>
            <p>
                La ecuación general para un sistema de segundo orden normalizado está definida matemáticamente por:
            </p>
            
            <div style="background-color:#2a2b36; padding:10px; border-radius:6px; text-align:center; font-family:'Courier New', monospace; font-size:13px; font-weight:bold; color:#e74c3c; border:1px solid #444454; margin: 10px 0;">
                G(s) = K &bull; &omega;<sub>n</sub>² / (s² + 2 &bull; &zeta; &bull; &omega;<sub>n</sub> &bull; s + &omega;<sub>n</sub>²)
            </div>
            
            <p>Al comparar los coeficientes de ambas ecuaciones, deducimos las siguientes relaciones fundamentales:</p>
            <ul>
                <li><b>Ganancia Estática del Proceso (K):</b> K = 1 / k. En nuestro caso, la celda de carga y su amplificador JY-S60 están calibrados de manera que <b>K = 1</b>, lo que asegura que en estado estacionario la lectura de voltaje es numéricamente igual al setpoint de peso.</li>
                <li><b>Frecuencia Natural Angular (&omega;<sub>n</sub>):</b> &omega;<sub>n</sub> = &radic;(k/m). Calibrada en <b>5 rad/s</b>, representando la oscilación natural de la balanza.</li>
                <li><b>Coeficiente de Amortiguamiento (&zeta;):</b> &zeta; = c / (2 &bull; &radic;(m&bull;k)). Configurado en <b>&zeta; = 0.4</b>, lo que clasifica a la planta como un sistema <b>subamortiguado</b>. Este valor bajo de amortiguamiento explica el fuerte rebote mecánico.</li>
            </ul>

            <h3 style="color:#2ecc71; border-bottom:1px solid #444454; padding-bottom:5px;">4. OBTENCIÓN DE LA FUNCIÓN DE TRANSFERENCIA FINAL</h3>
            <p>
                Sustituyendo los valores de la frecuencia natural (&omega;<sub>n</sub> = 5 rad/s) y la tasa de amortiguamiento (&zeta; = 0.4) en la forma normalizada:
            </p>
            
            <div style="background-color:#2a2b36; padding:10px; border-radius:6px; text-align:center; font-family:'Courier New', monospace; font-size:12px; font-weight:bold; color:#2ecc71; border:1px solid #444454; margin: 10px 0;">
                G(s) = (1) &bull; (5²) / [ s² + 2 &bull; (0.4) &bull; (5) &bull; s + 5² ] <br><br>
                G(s) = 25 / (s² + 4s + 25)
            </div>
            
            <p>
                Esta es la función de transferencia final que describe de manera exacta el comportamiento dinámico del sensor de pesaje de la planta UMNG simulada en el software.
            </p>
            
            <h3 style="color:#2ecc71; border-bottom:1px solid #444454; padding-bottom:5px;">5. CONVERSIÓN A ESPACIO DE ESTADOS (FCO)</h3>
            <p>
                Para implementar el observador de estados y el control en tiempo real, convertimos la función de transferencia G(s) a la <b>Forma Canónica Observable (FCO)</b>:
            </p>
            <div style="background-color:#2a2b36; padding:8px; border-radius:6px; font-family:'Courier New', monospace; font-size:11px; color:#9b59b6; border:1px solid #444454; margin: 10px 0;">
                &bull; A = [ -4  1 ; -25  0 ] <br>
                &bull; B = [  0 ; 25 ] <br>
                &bull; C = [  1  0 ]
            </div>
            <p>
                El estado <b>x<sub>1</sub>(t)</b> coincide con la variable medible y(t) (voltaje del transmisor), y el estado interno estimado <b>x<sub>2</sub>(t)</b> representa la velocidad de deformación de la celda de carga.
            </p>
        </body>
        </html>
        """

# =============================================================================
# CONSTANTES DEL MODELO MATEMÁTICO BASE
# =============================================================================
# Planta: G(s) = 25 / (s^2 + 4s + 25)
A_PLANT = np.array([[-4.0, 1.0], 
                    [-25.0, 0.0]])
B_PLANT = np.array([[0.0], 
                    [25.0]])
C_PLANT = np.array([[1.0, 0.0]])

# Ganancias PID Iniciales (Asignación de polos: dominantes en -6.4 +/- j4.8, tercero en -10)
KP_INIT = 6.68
KI_INIT = 25.6
KD_INIT = 0.752

# Ganancias del Observador (Polos dobles en -25 rad/s, fijo por estabilidad de estimación)
L_OBS = np.array([[46.0], 
                  [600.0]])

# Configuración de Botellas (Setpoints de Voltaje de la Celda de Carga / JY-S60)
BOTTLE_CONFIGS = {
    "Metal": {"weight_v": 5.0, "color": QColor(192, 192, 192), "label": "Metal (500g)", "ejector": 1},
    "Vidrio": {"weight_v": 8.0, "color": QColor(64, 224, 208, 160), "label": "Vidrio (800g)", "ejector": 2},
    "Plástico": {"weight_v": 3.0, "color": QColor(245, 222, 179), "label": "Plástico (300g)", "ejector": 3} # Va al final
}

# =============================================================================
# WIDGET DE LA ANIMACIÓN (BANDA TRANSPORTADORA)
# =============================================================================
class ConveyorWidget(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setMinimumHeight(280)
        self.bottle_x = 50.0
        self.bottle_y = 120.0
        self.bottle_type = "Metal"
        self.conveyor_running = False
        self.belt_offset = 0.0
        
        # Posiciones de los componentes
        self.sensor_x = 220
        self.scale_x = 400
        self.scale_width = 100
        self.ejector1_x = 550 # Metal
        self.ejector2_x = 700 # Vidrio
        self.bin_plastic_x = 830 # Plástico
        
        # Estados de los sensores y actuadores
        self.sensor_ir_active = False
        self.sensor_ind_active = False
        self.sensor_cap_active = False
        
        self.ejector1_angle = 0.0 # Brazo 1
        self.ejector2_angle = 0.0 # Brazo 2
        
        # Desplazamiento vertical de la plataforma por oscilación
        self.platform_dy = 0.0
        self.state = "idle"
        self.countdown = 0.0

    def reset_simulation(self, bottle_type):
        self.bottle_x = 50.0
        self.bottle_y = 120.0
        self.bottle_type = bottle_type
        self.conveyor_running = True
        self.sensor_ir_active = False
        self.sensor_ind_active = False
        self.sensor_cap_active = False
        self.ejector1_angle = 0.0
        self.ejector2_angle = 0.0
        self.platform_dy = 0.0
        self.state = "moving_to_sensors"
        self.countdown = 0.0
        self.update()

    def update_animation(self, bottle_x, state, open_loop_y, closed_loop_y, is_closed_loop, setpoint_val, countdown=0.0):
        self.bottle_x = bottle_x
        self.state = state
        self.countdown = countdown
        
        # Movimiento de la cinta
        if self.conveyor_running and state != "weighing":
            self.belt_offset = (self.belt_offset + 3) % 20
            
        # Control de Sensores en la Zona de Detección
        if 180 <= self.bottle_x <= 250:
            self.sensor_ir_active = True
            if self.bottle_type == "Metal":
                self.sensor_ind_active = True
                self.sensor_cap_active = False
            elif self.bottle_type == "Vidrio":
                self.sensor_ind_active = False
                self.sensor_cap_active = True
            else: # Plástico
                self.sensor_ind_active = False
                self.sensor_cap_active = True
        else:
            self.sensor_ir_active = False
            self.sensor_ind_active = False
            self.sensor_cap_active = False
            
        # Física del rebote en la celda de carga
        if state == "weighing":
            current_y = closed_loop_y if is_closed_loop else open_loop_y
            # Escalar la vibración física a píxeles (vibración respecto al equilibrio)
            self.platform_dy = (current_y - setpoint_val) * 2.5
            self.bottle_y = 120.0 + self.platform_dy
        else:
            self.platform_dy = 0.0
            
        # Lógica de caída en brazos eyectores o al final
        if state == "ejecting":
            if self.bottle_type == "Metal" and self.bottle_x >= self.ejector1_x:
                self.ejector1_angle = min(45.0, self.ejector1_angle + 4.0)
                self.bottle_y += 3.0
            elif self.bottle_type == "Vidrio" and self.bottle_x >= self.ejector2_x:
                self.ejector2_angle = min(45.0, self.ejector2_angle + 4.0)
                self.bottle_y += 3.0
        elif state in ["completed", "waiting_restart"]:
            self.conveyor_running = False
            if self.bottle_type == "Plástico":
                self.bottle_y += 4.0 # Cae en el contenedor
                if self.bottle_y > 210:
                    self.bottle_y = 210
            elif self.bottle_type == "Metal":
                if self.bottle_y > 210:
                    self.bottle_y = 210
            elif self.bottle_type == "Vidrio":
                if self.bottle_y > 210:
                    self.bottle_y = 210

        self.update()

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        
        # Fondo del contenedor industrial (Gris Oscuro)
        painter.fillRect(self.rect(), QColor(30, 30, 36))
        
        # Dibujar Rieles / Soporte de la Banda
        painter.setPen(QPen(QColor(80, 80, 90), 4))
        painter.setBrush(QBrush(QColor(50, 50, 55)))
        painter.drawRect(30, 140, 800, 15)
        
        # Dibujar Rodillos de los extremos
        painter.setPen(Qt.PenStyle.NoPen)
        painter.setBrush(QBrush(QColor(100, 100, 110)))
        painter.drawEllipse(20, 135, 25, 25)
        painter.drawEllipse(815, 135, 25, 25)
        
        # Líneas de la cinta transportadora en movimiento (Efecto visual)
        painter.setPen(QPen(QColor(140, 140, 150), 2))
        for x in range(35, 820, 20):
            x_pos = x + self.belt_offset
            if x_pos < 820:
                if not (self.scale_x - 5 <= x_pos <= self.scale_x + self.scale_width + 5):
                    painter.drawLine(int(x_pos), 140, int(x_pos - 8), 155)
                    
        # =============================================================================
        # 1. ZONA DE SENSORES
        # =============================================================================
        painter.setBrush(QBrush(QColor(120, 120, 130)))
        painter.drawRect(self.sensor_x - 5, 40, 8, 100)
        
        # Sensor IR (E18-D80NK)
        ir_color = QColor(255, 69, 0) if self.sensor_ir_active else QColor(100, 30, 10)
        painter.setBrush(QBrush(ir_color))
        painter.drawRect(self.sensor_x - 18, 50, 13, 10)
        painter.setBrush(QBrush(QColor(220, 220, 230)))
        painter.drawRect(self.sensor_x - 5, 51, 8, 8)
        painter.setPen(QPen(ir_color, 1))
        painter.drawText(self.sensor_x - 55, 59, "IR")
        
        # Sensor Inductivo (LJ12A3-Z/BX)
        ind_color = QColor(0, 191, 255) if self.sensor_ind_active else QColor(10, 50, 100)
        painter.setBrush(QBrush(ind_color))
        painter.drawRect(self.sensor_x - 18, 75, 13, 10)
        painter.setBrush(QBrush(QColor(220, 220, 230)))
        painter.drawRect(self.sensor_x - 5, 76, 8, 8)
        painter.setPen(QPen(ind_color, 1))
        painter.drawText(self.sensor_x - 55, 84, "IND")
        
        # Sensor Capacitivo (LJC18A3-B-Z/BX)
        cap_color = QColor(255, 215, 0) if self.sensor_cap_active else QColor(100, 80, 10)
        painter.setBrush(QBrush(cap_color))
        painter.drawRect(self.sensor_x - 18, 100, 13, 10)
        painter.setBrush(QBrush(QColor(220, 220, 230)))
        painter.drawRect(self.sensor_x - 5, 101, 8, 8)
        painter.setPen(QPen(cap_color, 1))
        painter.drawText(self.sensor_x - 55, 109, "CAP")
        
        # =============================================================================
        # 2. ZONA DE PESAJE DINÁMICO
        # =============================================================================
        painter.setPen(QPen(QColor(70, 70, 75), 2))
        painter.setBrush(QBrush(QColor(40, 40, 45)))
        painter.drawRect(self.scale_x + 20, 185, 60, 25)
        
        painter.setBrush(QBrush(QColor(180, 180, 190)))
        painter.drawRect(self.scale_x + 35, 160, 30, 25)
        painter.setPen(QPen(QColor(120, 120, 130), 1))
        painter.drawEllipse(self.scale_x + 40, 168, 8, 8)
        painter.drawEllipse(self.scale_x + 52, 168, 8, 8)
        
        py = 138 + self.platform_dy
        painter.setPen(QPen(QColor(0, 191, 255, 180), 2))
        painter.setBrush(QBrush(QColor(0, 191, 255, 40)))
        painter.drawRect(self.scale_x, int(py), self.scale_width, 10)
        
        painter.setPen(QPen(QColor(200, 200, 200), 2))
        painter.drawLine(self.scale_x + 50, int(py + 10), self.scale_x + 50, 160)
        
        painter.setPen(QPen(QColor(0, 191, 255), 1))
        painter.drawText(self.scale_x + 10, 198, "CELDA 5kg")
        
        # =============================================================================
        # 3. ZONA DE ACTUADORES (Eyectores)
        # =============================================================================
        self.draw_servo(painter, self.ejector1_x, 115, self.ejector1_angle, "MG995 M")
        self.draw_servo(painter, self.ejector2_x, 115, self.ejector2_angle, "MG995 V")
        
        painter.setPen(QPen(QColor(100, 100, 110), 3))
        painter.setBrush(QBrush(QColor(45, 45, 50)))
        
        r1 = QPolygonF([QPointF(self.ejector1_x + 10, 155), QPointF(self.ejector1_x + 80, 210), 
                        QPointF(self.ejector1_x + 50, 210), QPointF(self.ejector1_x - 10, 155)])
        painter.drawPolygon(r1)
        
        r2 = QPolygonF([QPointF(self.ejector2_x + 10, 155), QPointF(self.ejector2_x + 80, 210), 
                        QPointF(self.ejector2_x + 50, 210), QPointF(self.ejector2_x - 10, 155)])
        painter.drawPolygon(r2)
        
        painter.setPen(QPen(QColor(80, 80, 90), 2))
        painter.setBrush(QBrush(QColor(80, 80, 90, 80)))
        painter.drawRect(self.ejector1_x + 40, 210, 50, 40)
        painter.setPen(QPen(QColor(192, 192, 192), 1))
        painter.drawText(self.ejector1_x + 48, 235, "METAL")
        
        painter.setPen(QPen(QColor(80, 80, 90), 2))
        painter.setBrush(QBrush(QColor(0, 128, 128, 80)))
        painter.drawRect(self.ejector2_x + 40, 210, 50, 40)
        painter.setPen(QPen(QColor(64, 224, 208), 1))
        painter.drawText(self.ejector2_x + 44, 235, "VIDRIO")
        
        painter.setPen(QPen(QColor(80, 80, 90), 2))
        painter.setBrush(QBrush(QColor(218, 165, 32, 80)))
        painter.drawRect(self.bin_plastic_x, 155, 50, 60)
        painter.setPen(QPen(QColor(245, 222, 179), 1))
        painter.drawText(self.bin_plastic_x + 4, 190, "PLÁSTICO")

        # =============================================================================
        # 4. LA BOTELLA
        # =============================================================================
        self.draw_bottle(painter, self.bottle_x, self.bottle_y, self.bottle_type)

        # =============================================================================
        # 5. BANNER DE REINICIO AUTOMÁTICO (OVERLAY)
        # =============================================================================
        if hasattr(self, 'state') and self.state == "waiting_restart" and hasattr(self, 'countdown') and self.countdown > 0:
            # Dibujar un banner oscuro semi-transparente
            painter.setPen(QPen(QColor(46, 204, 113, 220), 2))
            painter.setBrush(QBrush(QColor(30, 30, 36, 230)))
            rect_banner = QRectF(150, 15, 540, 70)
            painter.drawRoundedRect(rect_banner, 8, 8)
            
            # Texto del Banner
            font_title = QFont("Segoe UI", 10, QFont.Weight.Bold)
            painter.setFont(font_title)
            painter.setPen(QPen(QColor(46, 204, 113)))
            painter.drawText(rect_banner, Qt.AlignmentFlag.AlignHCenter | Qt.AlignmentFlag.AlignTop, f"\nBOTELLA DE {self.bottle_type.upper()} COMPLETADA")
            
            font_text = QFont("Segoe UI", 9)
            painter.setFont(font_text)
            painter.setPen(QPen(QColor(240, 240, 245)))
            painter.drawText(rect_banner, Qt.AlignmentFlag.AlignHCenter | Qt.AlignmentFlag.AlignBottom, f"El sistema se reiniciará automáticamente en: {self.countdown:.1f} segundos\n")

    def draw_servo(self, painter, x, y, angle, label):
        painter.setPen(QPen(QColor(50, 50, 55), 1))
        painter.setBrush(QBrush(QColor(25, 25, 30)))
        painter.drawRect(x - 12, y - 25, 24, 25)
        
        painter.setBrush(QBrush(QColor(212, 175, 55)))
        painter.drawEllipse(x - 6, y - 6, 12, 12)
        
        painter.setPen(QPen(QColor(200, 200, 200), 1))
        font = QFont("Arial", 7)
        painter.setFont(font)
        painter.drawText(x - 20, y - 30, label)
        
        painter.save()
        painter.translate(x, y)
        painter.rotate(angle)
        
        painter.setPen(QPen(QColor(220, 50, 50), 2))
        painter.setBrush(QBrush(QColor(200, 30, 30, 180)))
        painter.drawRect(-4, 0, 8, 45)
        painter.restore()

    def draw_bottle(self, painter, x, y, bottle_type):
        bx = x - 15
        by = y - 50
        
        painter.setPen(QPen(QColor(255, 255, 255, 100), 1))
        grad = QLinearGradient(bx, by, bx + 30, by)
        if bottle_type == "Metal":
            grad.setColorAt(0.0, QColor(100, 100, 105))
            grad.setColorAt(0.5, QColor(220, 220, 230))
            grad.setColorAt(1.0, QColor(120, 120, 125))
        elif bottle_type == "Vidrio":
            grad.setColorAt(0.0, QColor(20, 100, 100, 200))
            grad.setColorAt(0.4, QColor(150, 240, 240, 180))
            grad.setColorAt(1.0, QColor(30, 120, 120, 200))
        else: # Plástico
            grad.setColorAt(0.0, QColor(180, 160, 140, 200))
            grad.setColorAt(0.5, QColor(245, 240, 230, 160))
            grad.setColorAt(1.0, QColor(190, 170, 150, 200))
            
        painter.setBrush(QBrush(grad))
        painter.drawRoundedRect(QRectF(bx, by + 12, 30, 38), 4, 4)
        painter.drawRect(int(bx + 8), int(by + 3), 14, 9)
        
        painter.setBrush(QBrush(QColor(220, 50, 50) if bottle_type != "Metal" else QColor(50, 50, 50)))
        painter.drawRect(int(bx + 6), int(by), 18, 4)
        
        painter.setPen(Qt.PenStyle.NoPen)
        painter.setBrush(QBrush(QColor(40, 40, 40, 160)))
        painter.drawRect(int(bx + 2), int(by + 20), 26, 12)
        
        painter.setPen(QPen(QColor(255, 255, 255), 1))
        font = QFont("Arial", 6, QFont.Weight.Bold)
        painter.setFont(font)
        label_text = "M" if bottle_type == "Metal" else ("V" if bottle_type == "Vidrio" else "P")
        painter.drawText(int(bx + 12), int(by + 29), label_text)

# =============================================================================
# LIENZO DE MATPLOTLIB (DOS PANELES GRÁFICOS)
# =============================================================================
class RealTimeControlPlots(FigureCanvas):
    def __init__(self, parent=None):
        fig = Figure(figsize=(7, 3.2), dpi=100, facecolor='#2a2b36')
        super().__init__(fig)
        self.setParent(parent)
        
        matplotlib.rcParams['text.color'] = '#f0f0f5'
        matplotlib.rcParams['axes.labelcolor'] = '#f0f0f5'
        matplotlib.rcParams['xtick.color'] = '#f0f0f5'
        matplotlib.rcParams['ytick.color'] = '#f0f0f5'
        
        self.ax_pid = fig.add_subplot(121)
        self.ax_pid.set_facecolor('#1e1e24')
        self.ax_pid.set_title("Dinámica de Pesaje (Fuerza / Voltaje)", fontsize=9, color='#f0f0f5')
        self.ax_pid.set_xlabel("Tiempo (s)", fontsize=8)
        self.ax_pid.set_ylabel("Lectura Transmisor (V)", fontsize=8)
        self.ax_pid.grid(True, color='#444454', linestyle=':')
        
        self.line_setpoint, = self.ax_pid.plot([], [], 'r--', label='Setpoint (Peso)', linewidth=1.5)
        self.line_ol, = self.ax_pid.plot([], [], color='#e74c3c', label='Lazo Abierto (Oscilatorio)', linewidth=1.8)
        self.line_cl, = self.ax_pid.plot([], [], color='#2ecc71', label='Lazo Cerrado PID (Amortiguado)', linewidth=2.0)
        self.ax_pid.legend(loc='lower right', fontsize=7, facecolor='#2a2b36', edgecolor='#444454')
        self.ax_pid.set_xlim(0, 4.0)
        self.ax_pid.set_ylim(-1.0, 11.0)
        
        self.ax_obs = fig.add_subplot(122)
        self.ax_obs.set_facecolor('#1e1e24')
        self.ax_obs.set_title("Observador de Estados de Luenberger", fontsize=9, color='#f0f0f5')
        self.ax_obs.set_xlabel("Tiempo (s)", fontsize=8)
        self.ax_obs.set_ylabel("Estados de FCO", fontsize=8)
        self.ax_obs.grid(True, color='#444454', linestyle=':')
        
        self.line_x1_real, = self.ax_obs.plot([], [], color='#007acc', label='Deflexión Real (x1)', linewidth=1.8)
        self.line_x1_est, = self.ax_obs.plot([], [], 'w--', label='Deflexión Est. (^x1)', linewidth=1.5)
        self.line_x2_real, = self.ax_obs.plot([], [], color='#9b59b6', label='Velocidad Real (x2)', linewidth=1.5)
        self.line_x2_est, = self.ax_obs.plot([], [], 'y--', label='Velocidad Est. (^x2)', linewidth=1.2)
        self.ax_obs.legend(loc='lower right', fontsize=7, facecolor='#2a2b36', edgecolor='#444454')
        self.ax_obs.set_xlim(0, 4.0)
        self.ax_obs.set_ylim(-15.0, 15.0)
        
        fig.tight_layout()

    def reset_plots(self, setpoint):
        self.line_setpoint.set_data([], [])
        self.line_ol.set_data([], [])
        self.line_cl.set_data([], [])
        
        self.line_x1_real.set_data([], [])
        self.line_x1_est.set_data([], [])
        self.line_x2_real.set_data([], [])
        self.line_x2_est.set_data([], [])
        
        self.draw_idle()

    def update_plots(self, t, y_ol, y_cl, x_real, x_est, setpoint):
        t_arr = np.array(t)
        
        self.line_setpoint.set_data([0, 4.0], [setpoint, setpoint])
        self.line_ol.set_data(t_arr, np.array(y_ol))
        self.line_cl.set_data(t_arr, np.array(y_cl))
        
        x_real_arr = np.array(x_real)
        x_est_arr = np.array(x_est)
        
        if len(t) > 0:
            self.line_x1_real.set_data(t_arr, x_real_arr[:, 0])
            self.line_x1_est.set_data(t_arr, x_est_arr[:, 0])
            self.line_x2_real.set_data(t_arr, x_real_arr[:, 1])
            self.line_x2_est.set_data(t_arr, x_est_arr[:, 1])
            
        self.draw_idle()

# =============================================================================
# VENTANA PRINCIPAL (GUI COMPLETA)
# =============================================================================
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("UMNG - Simulador del Proceso de Pesaje y Clasificación Automática")
        self.resize(1220, 830)
        
        # Inicialización de variables de simulación
        self.sim_t = []
        self.sim_y_ol = []
        self.sim_y_cl = []
        self.sim_x_real = [] # Estados reales del lazo cerrado [x1, x2]
        self.sim_x_est = []  # Estados estimados del observador [hat_x1, hat_x2]
        
        # Estados reales e integradores de simulación
        self.x_ol = np.array([0.0, 0.0])
        self.x_cl = np.array([0.0, 0.0])
        self.x_est_state = np.array([1.0, -5.0]) # Inicializado con error de estimación
        self.pid_integral = 0.0
        
        # Parámetros del controlador PID Dinámicos
        self.kp = KP_INIT
        self.ki = KI_INIT
        self.kd = KD_INIT
        
        # Variables de enlace con PLC
        self.plc_client = None
        self.plc_connected = False
        self.plc_mode_active = False # Modo SCADA
        
        # Configuración del flujo de botellas
        self.current_bottle = "Metal"
        self.setpoint = BOTTLE_CONFIGS[self.current_bottle]["weight_v"]
        
        # Estado de la secuencia general
        self.process_state = "idle"
        self.bottle_x_pos = 50.0
        self.weighing_timer_count = 0.0
        self.is_closed_loop = True # Comparador en la visualización física
        self.restart_countdown = 0.0
        
        # QTimer para la física y animación (60 FPS -> 16 ms)
        self.timer = QTimer()
        self.timer.timeout.connect(self.simulation_step)
        
        # QTimer para lectura de PLC (SCADA - 100 ms)
        self.plc_timer = QTimer()
        self.plc_timer.timeout.connect(self.read_plc_data)
        
        # Construir la interfaz de usuario
        self.init_ui()
        self.apply_dark_theme()

    def init_ui(self):
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        main_layout = QVBoxLayout(main_widget)
        main_layout.setContentsMargins(15, 10, 15, 15)
        main_layout.setSpacing(10)
        
        # =============================================================================
        # ENCABEZADO INSTITUCIONAL
        # =============================================================================
        header_frame = QFrame()
        header_frame.setFrameShape(QFrame.Shape.StyledPanel)
        header_frame.setObjectName("HeaderFrame")
        header_layout = QHBoxLayout(header_frame)
        header_layout.setContentsMargins(15, 10, 15, 10)
        
        title_layout = QVBoxLayout()
        univ_label = QLabel("UNIVERSIDAD MILITAR NUEVA GRANADA")
        univ_label.setStyleSheet("font-size: 11px; font-weight: bold; color: #2ecc71; letter-spacing: 2px;")
        title_label = QLabel("Simulador de Control y Clasificación Lineal - Proyecto Final de Laboratorio")
        title_label.setStyleSheet("font-size: 18px; font-weight: bold; color: #ffffff;")
        dept_label = QLabel("Facultad de Ingeniería • Ingeniería en Mecatrónica • Automatización Avanzada")
        dept_label.setStyleSheet("font-size: 10px; color: #a5a5b5;")
        title_layout.addWidget(univ_label)
        title_layout.addWidget(title_label)
        title_layout.addWidget(dept_label)
        
        logo_label = QLabel("UMNG\nCONTROL")
        logo_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        logo_label.setStyleSheet("border: 2px solid #2ecc71; border-radius: 8px; font-size: 12px; font-weight: bold; color: #2ecc71; padding: 5px;")
        
        header_layout.addLayout(title_layout)
        header_layout.addStretch()
        header_layout.addWidget(logo_label)
        main_layout.addWidget(header_frame)
        
        main_splitter = QSplitter(Qt.Orientation.Horizontal)
        
        # =============================================================================
        # PANEL IZQUIERDO: CONTROL Y TEORÍA (CON PESTAÑAS)
        # =============================================================================
        left_widget = QWidget()
        left_layout = QVBoxLayout(left_widget)
        left_layout.setContentsMargins(0, 0, 5, 0)
        left_layout.setSpacing(10)
        
        self.control_tabs = QTabWidget()
        self.control_tabs.setObjectName("ControlTabs")
        
        # PESTAÑA 1: SIMULACIÓN Y CONTROL LOCAL
        sim_tab = QWidget()
        sim_tab_layout = QVBoxLayout(sim_tab)
        sim_tab_layout.setSpacing(6)
        sim_tab_layout.setContentsMargins(5, 5, 5, 5)
        
        # --- SUB-GRUPO: CONFIGURACIÓN DE ENSAYO ---
        cfg_box = QGroupBox("Configuración de Ensayo")
        cfg_box_layout = QVBoxLayout(cfg_box)
        cfg_box_layout.setSpacing(5)
        
        combo_layout = QHBoxLayout()
        combo_label = QLabel("Tipo de Botella:")
        combo_label.setStyleSheet("font-weight: bold; font-size: 10px;")
        self.bottle_selector = QComboBox()
        for key in BOTTLE_CONFIGS.keys():
            self.bottle_selector.addItem(BOTTLE_CONFIGS[key]["label"], key)
        self.bottle_selector.currentIndexChanged.connect(self.change_bottle_type)
        combo_layout.addWidget(combo_label)
        combo_layout.addWidget(self.bottle_selector)
        cfg_box_layout.addLayout(combo_layout)
        
        setpoint_layout = QHBoxLayout()
        setpoint_label = QLabel("Peso Setpoint (V):")
        setpoint_label.setStyleSheet("font-weight: bold; font-size: 10px;")
        self.spin_setpoint = QDoubleSpinBox()
        self.spin_setpoint.setRange(0.1, 10.0)
        self.spin_setpoint.setSingleStep(0.1)
        self.spin_setpoint.setValue(self.setpoint)
        self.spin_setpoint.valueChanged.connect(self.update_setpoint_manually)
        setpoint_layout.addWidget(setpoint_label)
        setpoint_layout.addWidget(self.spin_setpoint)
        cfg_box_layout.addLayout(setpoint_layout)
        
        self.btn_lazo = QPushButton("Visualizar lazo: CERRADO (Activo)")
        self.btn_lazo.setCheckable(True)
        self.btn_lazo.setChecked(True)
        self.btn_lazo.clicked.connect(self.toggle_lazo_visual)
        cfg_box_layout.addWidget(self.btn_lazo)
        
        sim_tab_layout.addWidget(cfg_box)
        
        # --- SUB-GRUPO: PARÁMETROS DEL CONTROLADOR PID ---
        pid_box = QGroupBox("Parámetros del Controlador PID")
        pid_grid = QGridLayout(pid_box)
        pid_grid.setVerticalSpacing(4)
        pid_grid.setHorizontalSpacing(6)
        
        pid_grid.addWidget(QLabel("Ganancia Kp:"), 0, 0)
        self.spin_kp = QDoubleSpinBox()
        self.spin_kp.setRange(0.0, 100.0)
        self.spin_kp.setSingleStep(0.1)
        self.spin_kp.setValue(self.kp)
        self.spin_kp.valueChanged.connect(self.update_pid_gains)
        pid_grid.addWidget(self.spin_kp, 0, 1)
        
        pid_grid.addWidget(QLabel("Ganancia Ki:"), 1, 0)
        self.spin_ki = QDoubleSpinBox()
        self.spin_ki.setRange(0.0, 500.0)
        self.spin_ki.setSingleStep(0.5)
        self.spin_ki.setValue(self.ki)
        self.spin_ki.valueChanged.connect(self.update_pid_gains)
        pid_grid.addWidget(self.spin_ki, 1, 1)
        
        pid_grid.addWidget(QLabel("Ganancia Kd:"), 2, 0)
        self.spin_kd = QDoubleSpinBox()
        self.spin_kd.setRange(0.0, 50.0)
        self.spin_kd.setSingleStep(0.02)
        self.spin_kd.setValue(self.kd)
        self.spin_kd.valueChanged.connect(self.update_pid_gains)
        pid_grid.addWidget(self.spin_kd, 2, 1)
        
        sim_tab_layout.addWidget(pid_box)
        
        # --- SUB-GRUPO: AUTO-SINTONIZACIÓN ANALÍTICA ---
        tune_box = QGroupBox("Auto-Sintonización por Asignación de Polos")
        tune_grid = QGridLayout(tune_box)
        tune_grid.setVerticalSpacing(4)
        tune_grid.setHorizontalSpacing(6)
        
        tune_grid.addWidget(QLabel("Amortiguamiento Deseado (ζd):"), 0, 0)
        self.spin_tune_zeta = QDoubleSpinBox()
        self.spin_tune_zeta.setRange(0.1, 2.0)
        self.spin_tune_zeta.setSingleStep(0.05)
        self.spin_tune_zeta.setValue(0.8)
        tune_grid.addWidget(self.spin_tune_zeta, 0, 1)
        
        tune_grid.addWidget(QLabel("Frecuencia Natural (ωnd):"), 1, 0)
        self.spin_tune_wn = QDoubleSpinBox()
        self.spin_tune_wn.setRange(1.0, 50.0)
        self.spin_tune_wn.setSingleStep(0.5)
        self.spin_tune_wn.setValue(8.0)
        tune_grid.addWidget(self.spin_tune_wn, 1, 1)
        
        tune_grid.addWidget(QLabel("Tercer Polo Rápido (p):"), 2, 0)
        self.spin_tune_p = QDoubleSpinBox()
        self.spin_tune_p.setRange(1.0, 100.0)
        self.spin_tune_p.setSingleStep(1.0)
        self.spin_tune_p.setValue(10.0)
        tune_grid.addWidget(self.spin_tune_p, 2, 1)
        
        self.btn_auto_tune = QPushButton("Calcular & Sintonizar PID")
        self.btn_auto_tune.setStyleSheet("background-color: #2ecc71; color: #1e1e24; font-weight: bold;")
        self.btn_auto_tune.clicked.connect(self.auto_tune_pid)
        tune_grid.addWidget(self.btn_auto_tune, 3, 0, 1, 2)
        
        sim_tab_layout.addWidget(tune_box)
        
        # Rodapié de Botones Operativos de la simulación
        btn_layout = QHBoxLayout()
        self.btn_start = QPushButton("Iniciar Proceso")
        self.btn_start.setObjectName("BtnStart")
        self.btn_start.clicked.connect(self.start_process)
        
        self.btn_pause = QPushButton("Pausar")
        self.btn_pause.clicked.connect(self.pause_process)
        self.btn_pause.setEnabled(False)
        
        self.btn_reset = QPushButton("Reiniciar")
        self.btn_reset.clicked.connect(self.reset_system)
        
        btn_layout.addWidget(self.btn_start)
        btn_layout.addWidget(self.btn_pause)
        btn_layout.addWidget(self.btn_reset)
        sim_tab_layout.addLayout(btn_layout)
        
        self.btn_instant = QPushButton("Generar Gráfica Instantánea (Sin Espera)")
        self.btn_instant.setStyleSheet("background-color: #007acc; color: #ffffff; font-weight: bold;")
        self.btn_instant.clicked.connect(self.generate_instant_plots)
        sim_tab_layout.addWidget(self.btn_instant)
        
        self.control_tabs.addTab(sim_tab, "Simulación Local")
        
        # PESTAÑA 2: ENLACE PLC S7-1500 (SCADA)
        plc_tab = QWidget()
        plc_tab_layout = QVBoxLayout(plc_tab)
        plc_tab_layout.setSpacing(6)
        plc_tab_layout.setContentsMargins(5, 5, 5, 5)
        
        ip_layout = QHBoxLayout()
        ip_layout.addWidget(QLabel("IP PLC:"))
        self.input_ip = QLineEdit("192.168.0.1")
        ip_layout.addWidget(self.input_ip)
        plc_tab_layout.addLayout(ip_layout)
        
        rs_layout = QHBoxLayout()
        rs_layout.addWidget(QLabel("Rack:"))
        self.spin_rack = QSpinBox()
        self.spin_rack.setValue(0)
        rs_layout.addWidget(self.spin_rack)
        
        rs_layout.addWidget(QLabel("Slot:"))
        self.spin_slot = QSpinBox()
        self.spin_slot.setValue(1)
        rs_layout.addWidget(self.spin_slot)
        plc_tab_layout.addLayout(rs_layout)
        
        db_layout = QHBoxLayout()
        db_layout.addWidget(QLabel("DB Lectura:"))
        self.spin_db = QSpinBox()
        self.spin_db.setMaximum(9999)
        self.spin_db.setValue(1)
        db_layout.addWidget(self.spin_db)
        plc_tab_layout.addLayout(db_layout)
        
        self.lbl_plc_status = QLabel("Estado: Desconectado")
        self.lbl_plc_status.setStyleSheet("color: #e74c3c; font-weight: bold;")
        plc_tab_layout.addWidget(self.lbl_plc_status)
        
        self.btn_plc_connect = QPushButton("Conectar a PLC S7-1500")
        self.btn_plc_connect.clicked.connect(self.toggle_plc_connection)
        plc_tab_layout.addWidget(self.btn_plc_connect)
        
        self.btn_scada_mode = QPushButton("Modo SCADA: DESACTIVADO")
        self.btn_scada_mode.setCheckable(True)
        self.btn_scada_mode.setEnabled(False)
        self.btn_scada_mode.clicked.connect(self.toggle_scada_mode)
        plc_tab_layout.addWidget(self.btn_scada_mode)
        
        lbl_snap7_info = QLabel("Enlace vía Ethernet S7 Protocol (python-snap7)")
        lbl_snap7_info.setStyleSheet("font-size: 9px; color: #a5a5b5; text-align: center;")
        plc_tab_layout.addWidget(lbl_snap7_info)
        
        self.control_tabs.addTab(plc_tab, "Enlace PLC S7-1500")
        
        left_layout.addWidget(self.control_tabs)
        
        # Panel Técnico / Ecuaciones de Sustentación
        tech_group = QGroupBox("Sustentación Técnica y Modelamiento")
        tech_layout = QVBoxLayout(tech_group)
        tech_layout.setContentsMargins(8, 8, 8, 8)
        
        self.tech_tabs = QTabWidget()
        self.tech_tabs.setObjectName("TechTabs")
        
        # Pestaña 1: Contexto General
        self.tech_browser = QTextBrowser()
        self.tech_browser.setHtml(self.get_technical_html())
        self.tech_browser.setMinimumWidth(340)
        self.tech_browser.setOpenLinks(False)
        self.tech_browser.anchorClicked.connect(self.handle_link_clicked)
        self.tech_tabs.addTab(self.tech_browser, "Contexto & PLC")
        
        # Pestaña 2: Modelado & F.T.
        self.modeling_browser = QTextBrowser()
        self.modeling_browser.setHtml(self.get_modeling_tab_html())
        self.modeling_browser.setOpenLinks(False)
        self.modeling_browser.anchorClicked.connect(self.handle_link_clicked)
        self.tech_tabs.addTab(self.modeling_browser, "Modelado & Planta")
        
        tech_layout.addWidget(self.tech_tabs)
        
        self.btn_open_popup = QPushButton("Abrir Modelamiento en Ventana Independiente ↗")
        self.btn_open_popup.setStyleSheet("background-color: #007acc; color: #ffffff; font-weight: bold; font-size: 9.5px; padding: 4px;")
        self.btn_open_popup.clicked.connect(self.open_modeling_dialog)
        tech_layout.addWidget(self.btn_open_popup)
        
        left_layout.addWidget(tech_group)
        
        main_splitter.addWidget(left_widget)
        
        # =============================================================================
        # PANEL DERECHO: ANIMACIÓN Y GRÁFICOS MATPLOTLIB
        # =============================================================================
        right_widget = QWidget()
        right_layout = QVBoxLayout(right_widget)
        right_layout.setContentsMargins(5, 0, 0, 0)
        right_layout.setSpacing(10)
        
        anim_group = QGroupBox("Módulo Físico y Sensores (Banda Transportadora)")
        anim_layout = QVBoxLayout(anim_group)
        anim_layout.setContentsMargins(5, 5, 5, 5)
        self.conveyor_view = ConveyorWidget()
        anim_layout.addWidget(self.conveyor_view)
        right_layout.addWidget(anim_group)
        
        plots_group = QGroupBox("Respuesta Dinámica y Estimación de Estados (Tiempo Real)")
        plots_layout = QVBoxLayout(plots_group)
        plots_layout.setContentsMargins(5, 5, 5, 5)
        self.plots_view = RealTimeControlPlots()
        plots_layout.addWidget(self.plots_view)
        right_layout.addWidget(plots_group)
        
        right_layout.setStretch(0, 4)
        right_layout.setStretch(1, 5)
        
        main_splitter.addWidget(right_widget)
        
        main_splitter.setSizes([380, 820])
        main_layout.addWidget(main_splitter)

    # =============================================================================
    # LÓGICA DE CONTROL Y EVENTOS ACTUALIZADA
    # =============================================================================
    def update_pid_gains(self):
        self.kp = self.spin_kp.value()
        self.ki = self.spin_ki.value()
        self.kd = self.spin_kd.value()
        # No reiniciamos en plena oscilación de báscula para ver cambios en vivo si se está pesando
        if self.process_state != "weighing":
            self.reset_system()

    def update_setpoint_manually(self):
        self.setpoint = self.spin_setpoint.value()
        self.reset_system()

    def change_bottle_type(self):
        self.current_bottle = self.bottle_selector.currentData()
        default_v = BOTTLE_CONFIGS[self.current_bottle]["weight_v"]
        self.spin_setpoint.setValue(default_v)
        self.setpoint = default_v
        self.reset_system()

    def auto_tune_pid(self):
        zeta = self.spin_tune_zeta.value()
        wn = self.spin_tune_wn.value()
        p = self.spin_tune_p.value()
        
        # Ecuaciones de asignación de polos deducidas teóricamente:
        # Polinomio cerrado real: s^3 + (4 + 25Kd)s^2 + (25 + 25Kp)s + 25Ki = 0
        # Polinomio cerrado objetivo: (s+p)(s^2 + 2*zeta*wn*s + wn^2)
        # = s^3 + (2*zeta*wn + p)s^2 + (wn^2 + 2*zeta*wn*p)s + p*wn^2 = 0
        # Igualando coeficientes:
        # 1) 4 + 25Kd = 2*zeta*wn + p  => Kd = (2*zeta*wn + p - 4) / 25
        # 2) 25 + 25Kp = wn^2 + 2*zeta*wn*p => Kp = (wn^2 + 2*zeta*wn*p - 25) / 25
        # 3) 25Ki = p * wn^2 => Ki = (p * wn^2) / 25
        
        kd_calc = (2.0 * zeta * wn + p - 4.0) / 25.0
        kp_calc = (wn**2 + 2.0 * zeta * wn * p - 25.0) / 25.0
        ki_calc = (p * (wn**2)) / 25.0
        
        # Actualizar los controles visuales de ganancias
        self.spin_kp.setValue(max(0.0, kp_calc))
        self.spin_ki.setValue(max(0.0, ki_calc))
        self.spin_kd.setValue(max(0.0, kd_calc))
        
        # Actualizar variables internas
        self.kp = self.spin_kp.value()
        self.ki = self.spin_ki.value()
        self.kd = self.spin_kd.value()
        
        # Imprimir en el panel técnico para sustentación ante los jurados
        poles_text = f"<br><hr><b style='color:#2ecc71;'>[Auto-Sintonización Activa]</b><br>" \
                     f"Parámetros deseados: &zeta;<sub>d</sub> = {zeta}, &omega;<sub>nd</sub> = {wn} rad/s, p = {p}<br>" \
                     f"Polos asignados en lazo cerrado:<br>" \
                     f"&bull; s<sub>1,2</sub> = -{zeta*wn:.2f} &plusmn; j{wn*np.sqrt(max(0.0, 1.0 - zeta**2)):.2f}<br>" \
                     f"&bull; s<sub>3</sub> = -{p:.2f}<br>" \
                     f"<b>Ganancias resultantes calculadas por Python:</b><br>" \
                     f"&bull; K<sub>p</sub> = {self.kp:.3f}<br>" \
                     f"&bull; K<sub>i</sub> = {self.ki:.3f}<br>" \
                     f"&bull; K<sub>d</sub> = {self.kd:.3f}"
        
        current_html = self.get_technical_html()
        # Insertar reporte matemático dinámico antes del cierre de body
        new_html = current_html.replace("</body>", poles_text + "</body>")
        self.tech_browser.setHtml(new_html)
        
        self.reset_system()
        
        QMessageBox.information(self, "Auto-Sintonización Exitosa", 
                                f"Se han calculado las ganancias óptimas:\n"
                                f"Kp = {self.kp:.3f}\n"
                                f"Ki = {self.ki:.3f}\n"
                                f"Kd = {self.kd:.3f}\n\n"
                                f"Polos asignados en lazo cerrado con damping de {zeta} y ancho de banda de {wn} rad/s.")

    def start_process(self):
        if self.plc_mode_active:
            self.reset_sim_variables()
            self.timer.start(16)
            self.btn_start.setEnabled(False)
            self.btn_pause.setEnabled(True)
            return

        if self.process_state == "idle" or self.process_state == "completed":
            self.reset_sim_variables()
            self.process_state = "moving_to_sensors"
            self.conveyor_view.reset_simulation(self.current_bottle)
            self.plots_view.reset_plots(self.setpoint)
            
        self.timer.start(16)
        self.btn_start.setEnabled(False)
        self.btn_pause.setEnabled(True)
        self.bottle_selector.setEnabled(False)

    def pause_process(self):
        self.timer.stop()
        self.btn_start.setEnabled(True)
        self.btn_pause.setEnabled(False)

    def reset_system(self):
        self.timer.stop()
        self.reset_sim_variables()
        self.process_state = "idle"
        self.bottle_x_pos = 50.0
        self.weighing_timer_count = 0.0
        
        self.conveyor_view.reset_simulation(self.current_bottle)
        self.conveyor_view.conveyor_running = False
        self.plots_view.reset_plots(self.setpoint)
        
        self.btn_start.setEnabled(True)
        self.btn_pause.setEnabled(False)
        self.bottle_selector.setEnabled(True)
        self.conveyor_view.update()

    def reset_sim_variables(self):
        self.sim_t = []
        self.sim_y_ol = []
        self.sim_y_cl = []
        self.sim_x_real = []
        self.sim_x_est = []
        
        self.x_ol = np.array([0.0, 0.0])
        self.x_cl = np.array([0.0, 0.0])
        self.x_est_state = np.array([1.0, -5.0])
        self.pid_integral = 0.0

    def toggle_lazo_visual(self):
        self.is_closed_loop = self.btn_lazo.isChecked()
        if self.is_closed_loop:
            self.btn_lazo.setText("Visualizar lazo: CERRADO (Activo)")
            self.btn_lazo.setStyleSheet("background-color: #2ecc71; color: #1e1e24; font-weight: bold;")
        else:
            self.btn_lazo.setText("Visualizar lazo: ABIERTO (Natural)")
            self.btn_lazo.setStyleSheet("background-color: #e74c3c; color: #ffffff; font-weight: bold;")

    # =============================================================================
    # SIMULACIÓN OFFLINE INSTANTÁNEA
    # =============================================================================
    def generate_instant_plots(self):
        self.timer.stop()
        self.btn_start.setEnabled(True)
        self.btn_pause.setEnabled(False)
        self.bottle_selector.setEnabled(True)
        
        self.reset_sim_variables()
        
        t_total = 4.0
        dt = 0.005
        n_steps = int(t_total / dt)
        
        t_count = 0.0
        for _ in range(n_steps):
            t_count += dt
            
            # 1. Simulación Lazo Abierto
            u_ol = self.setpoint
            dx_ol = A_PLANT.dot(self.x_ol) + B_PLANT.flatten() * u_ol
            self.x_ol += dx_ol * dt
            
            # 2. Simulación Lazo Cerrado PID con las ganancias dinámicas
            r_cl = self.setpoint
            y_cl_current = self.x_cl[0]
            err = r_cl - y_cl_current
            self.pid_integral += err * dt
            
            dy_dt = -4.0 * self.x_cl[0] + self.x_cl[1]
            derr_dt = -dy_dt
            
            u_pid = self.kp * err + self.ki * self.pid_integral + self.kd * derr_dt
            dx_cl = A_PLANT.dot(self.x_cl) + B_PLANT.flatten() * u_pid
            self.x_cl += dx_cl * dt
            
            # 3. Simulación Observador
            dy_est = (A_PLANT - L_OBS.dot(C_PLANT)).dot(self.x_est_state) + B_PLANT.flatten() * u_pid + L_OBS.flatten() * y_cl_current
            self.x_est_state += dy_est * dt
            
            self.sim_t.append(t_count)
            self.sim_y_ol.append(self.x_ol[0])
            self.sim_y_cl.append(self.x_cl[0])
            self.sim_x_real.append(self.x_cl.copy())
            self.sim_x_est.append(self.x_est_state.copy())
            
        self.plots_view.update_plots(self.sim_t, self.sim_y_ol, self.sim_y_cl, self.sim_x_real, self.sim_x_est, self.setpoint)
        
        self.process_state = "weighing"
        self.bottle_x_pos = self.conveyor_view.scale_x + (self.conveyor_view.scale_width / 2.0) - 10
        self.conveyor_view.update_animation(self.bottle_x_pos, "weighing", self.setpoint, self.setpoint, True, self.setpoint)
        
        QMessageBox.information(self, "Simulación Matemática Descargada", 
                                f"Se ha simulado e impreso de manera instantánea el transitorio completo ({t_total} segundos) "
                                f"con las ganancias actuales:\n"
                                f"Kp = {self.kp:.3f}, Ki = {self.ki:.3f}, Kd = {self.kd:.3f}\n"
                                f"para una entrada escalón de {self.setpoint}V ({self.current_bottle}).")

    # =============================================================================
    # ENLACE CON PLC REAL - CLIENTE SNAP7
    # =============================================================================
    def toggle_plc_connection(self):
        if not SNAP7_AVAILABLE:
            QMessageBox.critical(self, "Error de Librería", 
                                 "python-snap7 no está correctamente enlazado. "
                                 "Instala la biblioteca y asegúrate de tener snap7.dll en tu SYSTEM PATH de Windows.")
            return
            
        if self.plc_connected:
            self.plc_timer.stop()
            self.btn_scada_mode.setChecked(False)
            self.btn_scada_mode.setEnabled(False)
            self.btn_scada_mode.setText("Modo SCADA: DESACTIVADO")
            self.plc_mode_active = False
            
            try:
                self.plc_client.disconnect()
            except:
                pass
            self.plc_connected = False
            self.lbl_plc_status.setText("Estado: Desconectado")
            self.lbl_plc_status.setStyleSheet("color: #e74c3c; font-weight: bold;")
            self.btn_plc_connect.setText("Conectar a PLC S7-1500")
            self.reset_system()
        else:
            ip = self.input_ip.text()
            rack = self.spin_rack.value()
            slot = self.spin_slot.value()
            
            self.plc_client = snap7.client.Client()
            self.lbl_plc_status.setText("Estado: Conectando...")
            self.lbl_plc_status.setStyleSheet("color: #f1c40f; font-weight: bold;")
            QApplication.processEvents()
            
            try:
                self.plc_client.connect(ip, rack, slot)
                if self.plc_client.get_connected():
                    self.plc_connected = True
                    self.lbl_plc_status.setText("Estado: Conectado a PLC")
                    self.lbl_plc_status.setStyleSheet("color: #2ecc71; font-weight: bold;")
                    self.btn_plc_connect.setText("Desconectar PLC")
                    self.btn_scada_mode.setEnabled(True)
                    QMessageBox.information(self, "Conexión Exitosa", 
                                            f"Enlazado correctamente con el PLC S7-1500 en {ip}. "
                                            f"¡Puedes activar el Modo SCADA para control en tiempo real!")
                else:
                    raise Exception("No se pudo establecer la conexión activa S7.")
            except Exception as e:
                self.plc_connected = False
                self.lbl_plc_status.setText("Estado: Error de Conexión")
                self.lbl_plc_status.setStyleSheet("color: #e74c3c; font-weight: bold;")
                QMessageBox.critical(self, "Fallo de Conexión", 
                                     f"No se pudo conectar al PLC en {ip}.\n"
                                     f"Detalle: {str(e)}\n\n"
                                     f"Asegúrate de:\n"
                                     f"1. Estar en la misma subred ethernet.\n"
                                     f"2. Habilitar la conexión PUT/GET en el PLC Siemens TIA Portal.\n"
                                     f"3. Configurar la DB de lectura como 'No optimizada'.")

    def toggle_scada_mode(self):
        self.plc_mode_active = self.btn_scada_mode.isChecked()
        if self.plc_mode_active:
            self.btn_scada_mode.setText("Modo SCADA: PLC REAL ACTIVO")
            self.btn_scada_mode.setStyleSheet("background-color: #2ecc71; color: #1e1e24; font-weight: bold;")
            self.bottle_selector.setEnabled(False)
            self.spin_setpoint.setEnabled(False)
            self.btn_lazo.setEnabled(False)
            self.btn_instant.setEnabled(False)
            
            self.reset_sim_variables()
            self.plc_timer.start(100)
            self.start_process()
        else:
            self.btn_scada_mode.setText("Modo SCADA: DESACTIVADO")
            self.btn_scada_mode.setStyleSheet("")
            self.bottle_selector.setEnabled(True)
            self.spin_setpoint.setEnabled(True)
            self.btn_lazo.setEnabled(True)
            self.btn_instant.setEnabled(True)
            
            self.plc_timer.stop()
            self.reset_system()

    def read_plc_data(self):
        if not self.plc_connected or not self.plc_mode_active:
            return
            
        try:
            db_num = self.spin_db.value()
            data = self.plc_client.db_read(db_num, 0, 12)
            
            ir_sensor = get_bool(data, 0, 0)
            ind_sensor = get_bool(data, 0, 1)
            cap_sensor = get_bool(data, 0, 2)
            real_weight = get_real(data, 2)
            angle_ejector1 = get_int(data, 6)
            angle_ejector2 = get_int(data, 8)
            plc_pos_x = get_int(data, 10)
            
            self.conveyor_view.sensor_ir_active = ir_sensor
            self.conveyor_view.sensor_ind_active = ind_sensor
            self.conveyor_view.sensor_cap_active = cap_sensor
            self.conveyor_view.ejector1_angle = float(angle_ejector1)
            self.conveyor_view.ejector2_angle = float(angle_ejector2)
            
            if ind_sensor:
                self.current_bottle = "Metal"
            elif cap_sensor and not ind_sensor:
                if real_weight > 5.5:
                    self.current_bottle = "Vidrio"
                else:
                    self.current_bottle = "Plástico"
            
            self.setpoint = BOTTLE_CONFIGS[self.current_bottle]["weight_v"]
            
            if plc_pos_x > 0:
                self.bottle_x_pos = 50.0 + (plc_pos_x / 1000.0) * 780.0
            else:
                if ir_sensor and self.process_state == "moving_to_sensors":
                    self.process_state = "sensing"
                    self.bottle_x_pos = self.conveyor_view.sensor_x + 10
                elif not ir_sensor and self.process_state == "sensing":
                    self.process_state = "moving_to_scale"
                    self.bottle_x_pos = self.conveyor_view.scale_x - 30
                    
            if real_weight > 0.5:
                if self.process_state != "weighing":
                    self.process_state = "weighing"
                    self.weighing_timer_count = 0.0
                    self.reset_sim_variables()
                
                self.weighing_timer_count += 0.1
                
                # Simulación de lazo abierto teórica paralela
                dx_ol = A_PLANT.dot(self.x_ol) + B_PLANT.flatten() * self.setpoint
                self.x_ol += dx_ol * 0.1
                
                y_plc_weight = real_weight
                
                # Observador estimando sobre los datos del PLC en vivo
                dy_est = (A_PLANT - L_OBS.dot(C_PLANT)).dot(self.x_est_state) + B_PLANT.flatten() * self.setpoint + L_OBS.flatten() * y_plc_weight
                self.x_est_state += dy_est * 0.1
                
                self.sim_t.append(self.weighing_timer_count)
                self.sim_y_ol.append(self.x_ol[0])
                self.sim_y_cl.append(y_plc_weight)
                
                x_cl_scada = np.array([y_plc_weight, (y_plc_weight - (self.sim_y_cl[-2] if len(self.sim_y_cl)>1 else 0.0))/0.1])
                self.sim_x_real.append(x_cl_scada)
                self.sim_x_est.append(self.x_est_state.copy())
                
                self.plots_view.update_plots(self.sim_t, self.sim_y_ol, self.sim_y_cl, self.sim_x_real, self.sim_x_est, self.setpoint)
            else:
                if self.process_state == "weighing":
                    self.process_state = "weighed"
                    
            if angle_ejector1 > 10 or angle_ejector2 > 10:
                self.process_state = "ejecting"
            
        except Exception as e:
            self.plc_timer.stop()
            self.btn_scada_mode.setChecked(False)
            self.toggle_scada_mode()
            QMessageBox.warning(self, "Error de Enlace SCADA", 
                                f"Fallo al leer datos del DB del PLC Siemens.\n"
                                f"Detalle: {str(e)}")

    # =============================================================================
    # PASO DE LA SIMULACIÓN DINÁMICA (MODO SIMULADOR)
    # =============================================================================
    def simulation_step(self):
        if self.plc_mode_active:
            if self.process_state != "weighing":
                self.bottle_x_pos += 2.0
                if self.bottle_x_pos > 850:
                    self.bottle_x_pos = 50.0
                    self.process_state = "moving_to_sensors"
                    
            y_ol_val = self.x_ol[0] if len(self.sim_y_ol) > 0 else 0.0
            y_cl_val = self.sim_y_cl[-1] if len(self.sim_y_cl) > 0 else 0.0
            self.conveyor_view.update_animation(
                self.bottle_x_pos, 
                self.process_state, 
                y_ol_val, 
                y_cl_val, 
                True,
                self.setpoint
            )
            return

        dt = 0.016
        
        if self.process_state == "moving_to_sensors":
            self.bottle_x_pos += 2.2
            if self.bottle_x_pos >= self.conveyor_view.sensor_x:
                self.process_state = "sensing"
                
        elif self.process_state == "sensing":
            self.bottle_x_pos += 1.5
            if self.bottle_x_pos > self.conveyor_view.sensor_x + 30:
                self.process_state = "moving_to_scale"
                
        elif self.process_state == "moving_to_scale":
            self.bottle_x_pos += 2.2
            if self.bottle_x_pos >= self.conveyor_view.scale_x + (self.conveyor_view.scale_width / 2.0) - 10:
                self.bottle_x_pos = self.conveyor_view.scale_x + (self.conveyor_view.scale_width / 2.0) - 10
                self.process_state = "weighing"
                self.weighing_timer_count = 0.0
                self.reset_sim_variables()
                
        elif self.process_state == "weighing":
            self.weighing_timer_count += dt
            
            # 1. Simulación Lazo Abierto
            u_ol = self.setpoint
            dx_ol = A_PLANT.dot(self.x_ol) + B_PLANT.flatten() * u_ol
            self.x_ol += dx_ol * dt
            y_ol_current = self.x_ol[0]
            
            # 2. Simulación Lazo Cerrado PID con constantes del usuario
            r_cl = self.setpoint
            y_cl_current = self.x_cl[0]
            
            err = r_cl - y_cl_current
            self.pid_integral += err * dt
            
            dy_dt = -4.0 * self.x_cl[0] + self.x_cl[1]
            derr_dt = -dy_dt
            
            u_pid = self.kp * err + self.ki * self.pid_integral + self.kd * derr_dt
            
            dx_cl = A_PLANT.dot(self.x_cl) + B_PLANT.flatten() * u_pid
            self.x_cl += dx_cl * dt
            
            # 3. Simulación del Observador
            dy_est = (A_PLANT - L_OBS.dot(C_PLANT)).dot(self.x_est_state) + B_PLANT.flatten() * u_pid + L_OBS.flatten() * y_cl_current
            self.x_est_state += dy_est * dt
            
            self.sim_t.append(self.weighing_timer_count)
            self.sim_y_ol.append(y_ol_current)
            self.sim_y_cl.append(y_cl_current)
            
            self.sim_x_real.append(self.x_cl.copy())
            self.sim_x_est.append(self.x_est_state.copy())
            
            self.plots_view.update_plots(self.sim_t, self.sim_y_ol, self.sim_y_cl, self.sim_x_real, self.sim_x_est, self.setpoint)
            
            if self.weighing_timer_count >= 4.0:
                self.process_state = "weighed"
                
        elif self.process_state == "weighed":
            self.bottle_x_pos += 2.2
            self.process_state = "moving_to_ejector"
            
        elif self.process_state == "moving_to_ejector":
            self.bottle_x_pos += 2.2
            cfg = BOTTLE_CONFIGS[self.current_bottle]
            if cfg["ejector"] == 1 and self.bottle_x_pos >= self.conveyor_view.ejector1_x - 10:
                self.bottle_x_pos = self.conveyor_view.ejector1_x - 10
                self.process_state = "ejecting"
            elif cfg["ejector"] == 2 and self.bottle_x_pos >= self.conveyor_view.ejector2_x - 10:
                self.bottle_x_pos = self.conveyor_view.ejector2_x - 10
                self.process_state = "ejecting"
            elif cfg["ejector"] == 3 and self.bottle_x_pos >= self.conveyor_view.bin_plastic_x:
                self.bottle_x_pos = self.conveyor_view.bin_plastic_x
                self.process_state = "completed"
                
        elif self.process_state == "ejecting":
            if self.current_bottle == "Metal" and self.conveyor_view.ejector1_angle >= 45.0:
                self.process_state = "completed"
            elif self.current_bottle == "Vidrio" and self.conveyor_view.ejector2_angle >= 45.0:
                self.process_state = "completed"
                
        elif self.process_state == "completed":
            if self.current_bottle in ["Metal", "Vidrio"]:
                self.process_state = "waiting_restart"
                self.restart_countdown = 30.0
            else:
                self.timer.stop()
                self.btn_start.setEnabled(True)
                self.btn_pause.setEnabled(False)
                self.bottle_selector.setEnabled(True)
                
        elif self.process_state == "waiting_restart":
            self.restart_countdown -= dt
            if self.restart_countdown <= 0.0:
                self.restart_countdown = 0.0
                self.reset_sim_variables()
                self.process_state = "moving_to_sensors"
                self.conveyor_view.reset_simulation(self.current_bottle)
                self.plots_view.reset_plots(self.setpoint)
            
        y_ol_val = self.x_ol[0] if len(self.sim_y_ol) > 0 else 0.0
        y_cl_val = self.x_cl[0] if len(self.sim_y_cl) > 0 else 0.0
        
        self.conveyor_view.update_animation(
            self.bottle_x_pos, 
            self.process_state, 
            y_ol_val, 
            y_cl_val, 
            self.is_closed_loop,
            self.setpoint,
            getattr(self, 'restart_countdown', 0.0)
        )

    def handle_link_clicked(self, url):
        if url.toString() == "abrir_modelado":
            self.open_modeling_dialog()

    def open_modeling_dialog(self):
        dialog = ModelingDialog(self)
        dialog.exec()

    def get_modeling_tab_html(self):
        return """
        <html>
        <body style="font-family:'Segoe UI', Arial, sans-serif; color:#dcdce6; background-color:#2a2b36; font-size:12px; line-height:1.5;">
            <h3 style="color:#2ecc71; border-bottom:1px solid #444454; padding-bottom:3px; margin-top:0px;">MODELADO DE LA PLANTA G(s)</h3>
            <p>
                La celda de carga de 5 kg se modela mecánicamente como un sistema <b>Masa-Resorte-Amortiguador</b>:
            </p>
            <div style="background-color:#1e1e24; padding:8px; border-radius:4px; text-align:center; font-family:'Courier New', monospace; font-weight:bold; color:#007acc; border:1px solid #444454;">
                m &bull; d²y(t)/dt² + c &bull; dy(t)/dt + k &bull; y(t) = f(t)
            </div>
            <p>Aplicando condiciones iniciales nulas y la Transformada de Laplace:</p>
            <div style="background-color:#1e1e24; padding:8px; border-radius:4px; text-align:center; font-family:'Courier New', monospace; font-weight:bold; color:#007acc; border:1px solid #444454;">
                G(s) = Y(s)/F(s) = (1/m) / [s<sup>2</sup> + (c/m)s + (k/m)]
            </div>
            <p>Comparando con el modelo estándar de segundo orden:</p>
            <div style="background-color:#1e1e24; padding:8px; border-radius:4px; text-align:center; font-family:'Courier New', monospace; font-weight:bold; color:#e74c3c; border:1px solid #444454;">
                G(s) = K&bull;&omega;<sub>n</sub><sup>2</sup> / [s<sup>2</sup> + 2&zeta;&omega;<sub>n</sub>s + &omega;<sub>n</sub><sup>2</sup>]
            </div>
            <p>Utilizando los coeficientes físicos calibrados:</p>
            <ul>
                <li>Ganancia estática: <b>K = 1</b> (1V de fuerza estable = 1V de voltaje)</li>
                <li>Frecuencia natural: <b>&omega;<sub>n</sub> = 5 rad/s</b></li>
                <li>Tasa de amortiguamiento: <b>&zeta; = 0.4</b> (rebote físico)</li>
            </ul>
            <p>Obtenemos la función de transferencia continua final:</p>
            <div style="background-color:#1e1e24; padding:8px; border-radius:4px; text-align:center; font-family:'Courier New', monospace; font-weight:bold; color:#2ecc71; border:1px solid #444454;">
                G(s) = 25 / (s<sup>2</sup> + 4s + 25)
            </div>
            <p style="text-align:center; margin-top:8px;">
                <a href="abrir_modelado" style="color:#2ecc71; font-weight:bold; text-decoration:underline;">[Ver ventana de deducción matemática y variables de estado]</a>
            </p>
        </body>
        </html>
        """

    # =============================================================================
    # TEXTO ACADÉMICO PARA LA SUSTENTACIÓN ANTE JURADOS
    # =============================================================================
    def get_technical_html(self):
        return """
        <html>
        <body style="font-family:'Segoe UI', Arial, sans-serif; color:#dcdce6; background-color:#2a2b36; font-size:12px; line-height:1.5;">
            
            <h3 style="color:#2ecc71; border-bottom:1px solid #444454; padding-bottom:3px; margin-top:0px;">1. CONTEXTO MECATRÓNICO Y ENLACE PLC REAL</h3>
            <p>
                El sistema simula una banda transportadora de clasificación lineal, un diseño común en celdas de manufactura flexible integradas con <b>Factory I/O</b> y controladas por un PLC <b>Siemens S7-1500</b>. 
                El flujo físico consta de:
            </p>
            <ul>
                <li><b>Pre-clasificación:</b> Tres sensores montados al inicio detectan y pre-clasifican la botella. El sensor infrarrojo <b>E18-D80NK</b> detecta presencia. Si es metálica, el sensor inductivo <b>LJ12A3-Z/BX</b> conmuta; si es plástica o de vidrio, el sensor capacitivo <b>LJC18A3-B-Z/BX</b> hace lo propio en conjunto con la lectura de peso.</li>
                <li><b>Estación de Pesaje Dinámico:</b> La botella frena sobre una balanza acrílica acoplada a una <b>Celda de Carga de 5kg</b> y un transmisor analógico <b>JY-S60 (0-10V)</b>. El impacto genera vibraciones mecánicas debido a la elasticidad de la celda.</li>
                <li><b>Clasificación por Actuadores:</b> Un microcontrolador <b>ESP32</b> recibe comandos del PLC para mover servomotores <b>MG995</b> que desvían las botellas hacia sus respectivos contenedores (Metal primero, Vidrio segundo, Plástico al final).</li>
                <li><b>Monitoreo SCADA / Enlace PLC Real:</b> Esta herramienta integra un cliente industrial **Snap7** (Ethernet TCP/IP). Al conectarse al PLC, recopila y grafica el transitorio real del transmisor JY-S60 en vivo, convirtiéndose en un SCADA interactivo para tus laboratorios prácticos.</li>
            </ul>

            <h3 style="color:#2ecc71; border-bottom:1px solid #444454; padding-bottom:3px;">2. MODELO MATEMÁTICO DE SEGUNDO ORDEN</h3>
            <p>
                La elasticidad de la celda de carga y la inercia/impacto al detener la banda provocan un rebote físico subamortiguado modelado por la función de transferencia:
            </p>
            <div style="background-color:#1e1e24; padding:8px; border-radius:4px; text-align:center; font-family:'Courier New', monospace; font-weight:bold; color:#007acc; border:1px solid #444454;">
                G(s) = 25 / (s<sup>2</sup> + 4s + 25)
            </div>
            <p style="text-align:center; margin-top:5px;">
                <a href="abrir_modelado" style="color:#2ecc71; font-weight:bold; text-decoration:underline;">[Ver Ventana de Modelamiento y Deducción de G(s)]</a>
            </p>

            <h3 style="color:#2ecc71; border-bottom:1px solid #444454; padding-bottom:3px;">3. CONTROLADOR PID ACTIVO POR ASIGNACIÓN DE POLOS</h3>
            <p>
                En lazo abierto, las oscilaciones mecánicas tardan más de 2 segundos en asentarse en un rango del 2%, retrasando el ciclo del PLC. Diseñamos un controlador PID en lazo cerrado para amortiguar drásticamente la señal.
            </p>
            <p>Buscamos un comportamiento con polos dominantes rápidos <b>&omega;<sub>nd</sub> = 8 rad/s, &zeta;<sub>d</sub> = 0.8</b> y un tercer polo rápido en <b>s = -10</b> para contrarrestar el cero del controlador, obteniendo el polinomio característico deseado:</p>
            <div style="background-color:#1e1e24; padding:8px; border-radius:4px; text-align:center; font-family:'Courier New', monospace; font-size:11px; font-weight:bold; color:#e74c3c; border:1px solid #444454;">
                P_d(s) = s<sup>3</sup> + 22.8 s<sup>2</sup> + 192 s + 640 = 0
            </div>
            <p>Igualando coeficientes con la ecuación del lazo cerrado <i>s<sup>3</sup> + (4 + 25K_d)s<sup>2</sup> + (25 + 25K_p)s + 25K_i = 0</i>, se obtienen las ganancias exactas:</p>
            <ul>
                <li>Proporcional: <b>K<sub>p</sub> = 6.680</b></li>
                <li>Integral: <b>K<sub>i</sub> = 25.600</b></li>
                <li>Derivativa: <b>K<sub>d</sub> = 0.752</b></li>
            </ul>
            <p><b>Logro del PID:</b> Elimina el sobrepico mecánico e impone un tiempo de asentamiento de solo <b>0.8 segundos</b>, acelerando la decisión del clasificador en un 150%.</p>

            <h3 style="color:#2ecc71; border-bottom:1px solid #444454; padding-bottom:3px;">4. OBSERVADOR DE ESTADOS (LUENBERGER)</h3>
            <p>
                Aunque físicamente solo se mide el voltaje de salida (<i>y = x<sub>1</sub></i>), para implementar el control avanzado es valioso conocer la velocidad de deflexión interna (<i>x<sub>2</sub></i>).
                Transformamos el sistema a su <b>Forma Canónica Observable (FCO)</b>:
            </p>
            <div style="background-color:#1e1e24; padding:8px; border-radius:4px; text-align:center; font-family:'Courier New', monospace; font-size:10px; color:#9b59b6; border:1px solid #444454;">
                A = [ -4  1 ; -25  0 ]<br>
                B = [  0 ; 25 ]<br>
                C = [  1  0 ]
            </div>
            <p>
                Para garantizar que el observador estime el estado antes de que se complete el transitorio, colocamos polos dobles rápidos en <b>s = -25 rad/s</b> (3 veces más rápido que la velocidad del control).
                Esto arroja el vector de ganancia de Luenberger:
            </p>
            <div style="background-color:#1e1e24; padding:8px; border-radius:4px; text-align:center; font-family:'Courier New', monospace; font-weight:bold; color:#9b59b6; border:1px solid #444454;">
                L = [ 46 ; 600 ] <sup>T</sup>
            </div>
            <p>
                El gráfico de la derecha demuestra cómo el estimador inicializado con un error severo <b>[^x<sub>1</sub>(0) = 1.0, ^x<sub>2</sub>(0) = -5.0]</b> converge perfectamente con los valores reales del proceso en menos de <b>0.2 segundos</b>, validando matemáticamente el filtro de Luenberger.
            </p>
        </body>
        </html>
        """

    # =============================================================================
    # ESTILIZACIÓN DE LA INTERFAZ (HOJA DE ESTILOS PREMIUM)
    # =============================================================================
    def apply_dark_theme(self):
        self.setStyleSheet("""
            QMainWindow {
                background-color: #1e1e24;
            }
            
            #HeaderFrame {
                background-color: #2a2b36;
                border: 1px solid #444454;
                border-radius: 8px;
            }
            
            QGroupBox {
                background-color: #2a2b36;
                border: 1px solid #444454;
                border-radius: 8px;
                margin-top: 10px;
                font-weight: bold;
                font-size: 11px;
                color: #2ecc71;
                padding-top: 12px;
            }
            
            QGroupBox::title {
                subcontrol-origin: margin;
                subcontrol-position: top left;
                left: 15px;
                padding: 0px 5px 0px 5px;
            }
            
            QLabel {
                color: #f0f0f5;
                font-size: 10px;
            }
            
            QComboBox {
                background-color: #1e1e24;
                border: 1px solid #444454;
                border-radius: 4px;
                padding: 3px 6px;
                color: #f0f0f5;
                font-size: 10px;
                min-width: 140px;
            }
            
            QComboBox::drop-down {
                border-left: 1px solid #444454;
            }
            
            QPushButton {
                background-color: #3b3c4d;
                border: 1px solid #555566;
                border-radius: 4px;
                padding: 5px 10px;
                color: #f0f0f5;
                font-weight: bold;
                font-size: 10px;
            }
            
            QPushButton:hover {
                background-color: #4a4b5d;
                border: 1px solid #66667c;
            }
            
            QPushButton:pressed {
                background-color: #252630;
            }
            
            QPushButton#BtnStart {
                background-color: #2ecc71;
                color: #1e1e24;
                border: 1px solid #27ae60;
            }
            
            QPushButton#BtnStart:hover {
                background-color: #27ae60;
            }
            
            QPushButton#BtnStart:disabled {
                background-color: #304d3c;
                color: #85a593;
                border: 1px solid #2d4538;
            }
            
            QPushButton:disabled {
                color: #66667c;
                background-color: #252630;
                border: 1px solid #3b3c4d;
            }
            
            QTextBrowser {
                background-color: #1e1e24;
                border: 1px solid #444454;
                border-radius: 6px;
            }
            
            QSplitter::handle {
                background-color: #1e1e24;
            }
            
            #ControlTabs::pane, #TechTabs::pane {
                border: 1px solid #444454;
                background: #2a2b36;
                border-radius: 4px;
            }
            
            QTabBar::tab {
                background: #1e1e24;
                border: 1px solid #444454;
                border-bottom-color: none;
                border-top-left-radius: 4px;
                border-top-right-radius: 4px;
                padding: 5px 10px;
                color: #a5a5b5;
                font-size: 9px;
                font-weight: bold;
            }
            
            QTabBar::tab:selected, QTabBar::tab:hover {
                background: #2a2b36;
                color: #ffffff;
                border-bottom: 2px solid #2ecc71;
            }
            
            QLineEdit {
                background-color: #1e1e24;
                border: 1px solid #444454;
                border-radius: 4px;
                padding: 3px;
                color: #ffffff;
                font-size: 10px;
            }
            
            QSpinBox {
                background-color: #1e1e24;
                border: 1px solid #444454;
                border-radius: 4px;
                padding: 3px;
                color: #ffffff;
                font-size: 10px;
            }
            
            QDoubleSpinBox {
                background-color: #1e1e24;
                border: 1px solid #444454;
                border-radius: 4px;
                padding: 3px;
                color: #ffffff;
                font-size: 10px;
            }
        """)
        
        self.btn_lazo.setStyleSheet("background-color: #2ecc71; color: #1e1e24; font-weight: bold;")

# =============================================================================
# INICIALIZACIÓN DE LA APLICACIÓN
# =============================================================================
if __name__ == "__main__":
    app = QApplication(sys.argv)
    
    font = QFont("Segoe UI", 9)
    app.setFont(font)
    
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
