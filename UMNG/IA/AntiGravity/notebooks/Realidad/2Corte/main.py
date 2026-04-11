import sys
import os
import subprocess
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QLabel, QFrame, QGroupBox, QMessageBox
)
from PySide6.QtCore import Qt, QTimer
from PySide6.QtGui import QColor, QPixmap

# --- RUTAS DE LOS SHORTCUTS (.lnk) ---
HAPTICDESK_LNK  = r"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Force Dimension\sdk-3.17.6\HapticDesk.lnk"
H3DVIEWER_LNK   = r"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\H3D\H3DViewer.lnk"
H3DVIEWER_EXE   = r"C:\H3D\bin64\H3DViewer.exe"
CURRENT_DIR     = os.path.dirname(os.path.abspath(__file__))

# ──────────────────────────────────────────────────────────────────────────────
# DETECCION USB del Falcon via WMI (sin abrir el dispositivo)
# ──────────────────────────────────────────────────────────────────────────────
def falcon_usb_connected() -> bool:
    """Consulta el Administrador de dispositivos de Windows buscando el Falcon."""
    try:
        import winreg
        # Buscamos usando WMI via Python para ver si el USB está presente
        result = subprocess.run(
            ["wmic", "path", "Win32_PnPEntity", "where",
             "Name like '%Falcon%' or Name like '%Force Dimension%'",
             "get", "Name,Status", "/format:csv"],
            capture_output=True, text=True, timeout=3,
            creationflags=subprocess.CREATE_NO_WINDOW
        )
        output = result.stdout.strip()
        # Si hay alguna línea de datos (más que el encabezado)
        lines = [l for l in output.splitlines() if l.strip() and "Node" not in l and "Name" not in l]
        return len(lines) > 0
    except Exception:
        return False


class HapticLabUmng(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("UMNG | LABORATORIO HAPTICO - Sistema de Control")
        self.resize(1050, 680)
        self.setStyleSheet("""
            QMainWindow { background-color: #f5f5f7; }
            QWidget { background-color: #f5f5f7; font-family: 'Segoe UI'; }
            QLabel { color: #1d1d1f; }
            QGroupBox {
                font-weight: bold; border: 1px solid #d2d2d7;
                border-radius: 10px; margin-top: 16px; padding: 16px;
                background: white;
            }

            QPushButton#BtnLaunch {
                background-color: #0071e3; color: white;
                border: none; border-radius: 12px;
                padding: 16px; font-size: 14px; font-weight: bold;
            }
            QPushButton#BtnLaunch:hover { background-color: #0077ed; }

            QPushButton#BtnTool {
                background-color: #e8e8ed; color: #1d1d1f;
                border: none; border-radius: 8px;
                padding: 12px; font-size: 13px;
            }
            QPushButton#BtnTool:hover { background-color: #d2d2d7; }
        """)
        self._build_ui()
        # Timer: comprueba USB cada 2 segundos
        self._timer = QTimer(self)
        self._timer.timeout.connect(self._update_status)
        self._timer.start(2000)
        self._update_status()  # primera comprobacion inmediata

    # ──────────────────────────────────────────────────────────────────────
    def _build_ui(self):
        root = QWidget()
        self.setCentralWidget(root)
        vbox = QVBoxLayout(root)
        vbox.setContentsMargins(36, 36, 36, 24)
        vbox.setSpacing(20)

        # ── Header ──────────────────────────────────────────────────────
        header = QHBoxLayout()
        
        # Logo UMNG
        logo_path = r"C:\Users\pinzo\OneDrive\Pictures\log.png"
        if os.path.exists(logo_path):
            lbl_logo = QLabel()
            pixmap = QPixmap(logo_path).scaledToHeight(40, Qt.SmoothTransformation)
            lbl_logo.setPixmap(pixmap)
            lbl_logo.setStyleSheet("background: transparent;")
            header.addWidget(lbl_logo)

        lbl_title = QLabel("<b>UMNG | MECATRÓNICA</b>")
        lbl_title.setStyleSheet("font-size: 22px; color: #0071e3; background: transparent;")
        header.addWidget(lbl_title)
        header.addStretch()
        lbl_ver = QLabel("H3D API v2.4.0")
        lbl_ver.setStyleSheet("color: #6e6e73; font-size: 12px;")
        header.addWidget(lbl_ver)
        vbox.addLayout(header)

        # ── Estado del Falcon ────────────────────────────────────────────
        self.status_frame = QFrame()
        self.status_frame.setFixedHeight(52)
        self.status_frame.setStyleSheet("border-radius: 10px;")
        st_layout = QHBoxLayout(self.status_frame)
        self.dot = QLabel("●")
        self.dot.setStyleSheet("font-size: 22px;")
        self.status_lbl = QLabel("Verificando conexión…")
        self.status_lbl.setStyleSheet("font-size: 14px; font-weight: bold;")
        st_layout.addWidget(self.dot)
        st_layout.addWidget(self.status_lbl)
        st_layout.addStretch()
        vbox.addWidget(self.status_frame)

        # ── Cards de Fases ───────────────────────────────────────────────
        cards = QHBoxLayout()
        cards.setSpacing(20)

        card1 = QGroupBox("FASE I: MAPA HÁPTICO")
        c1v = QVBoxLayout(card1)
        c1v.addWidget(QLabel(
            "Exploración de 4 superficies industriales:\n"
            "  •  Acero Pulido   •  Caucho\n"
            "  •  Espuma         •  Lubricante"
        ))
        c1v.addStretch()
        b1 = QPushButton("LANZAR MAPA (X3D)")
        b1.setObjectName("BtnLaunch")
        b1.clicked.connect(lambda: self._run_scene("fase1_mapa.x3d"))
        c1v.addWidget(b1)
        cards.addWidget(card1)

        card2 = QGroupBox("FASE II: ESTACIÓN INDUSTRIAL")
        c2v = QVBoxLayout(card2)
        c2v.addWidget(QLabel(
            "Mini planta con animaciones interactivas:\n"
            "  •  Rodillo giratorio (Caucho)\n"
            "  •  Prensa hidráulica (Espuma)\n"
            "  •  Mesa de Inspección (Lubricado)"
        ))
        c2v.addStretch()
        b2 = QPushButton("LANZAR ESTACIÓN (X3D)")
        b2.setObjectName("BtnLaunch")
        b2.clicked.connect(lambda: self._run_scene("fase2_industria.x3d"))
        c2v.addWidget(b2)
        cards.addWidget(card2)
        vbox.addLayout(cards)

        # ── Herramientas ─────────────────────────────────────────────────
        tools = QGroupBox("Diagnóstico y Herramientas del Novint Falcon")
        tl = QHBoxLayout(tools)

        btn_hd = QPushButton("Abrir SDK Diagnóstico  (HapticDesk)")
        btn_hd.setObjectName("BtnTool")
        btn_hd.clicked.connect(self._open_hapticdesk)
        tl.addWidget(btn_hd)

        btn_v = QPushButton("Abrir Visor H3D  (H3DViewer)")
        btn_v.setObjectName("BtnTool")
        btn_v.clicked.connect(self._open_h3dviewer)
        tl.addWidget(btn_v)
        vbox.addWidget(tools)

        # ── Footer ────────────────────────────────────────────────────────
        vbox.addStretch()
        footer = QLabel("UNIVERSIDAD MILITAR NUEVA GRANADA  ·  Ingeniería Mecatrónica  ·  Laboratorio de Realidad Virtual y Haptics")
        footer.setAlignment(Qt.AlignCenter)
        footer.setStyleSheet("color: #6e6e73; font-size: 11px;")
        vbox.addWidget(footer)

    # ──────────────────────────────────────────────────────────────────────
    def _update_status(self):
        connected = falcon_usb_connected()
        if connected:
            self.dot.setStyleSheet("font-size: 22px; color: #30d158;")
            self.status_lbl.setText("Novint Falcon CONECTADO  ✔  (listo para calibrar)")
            self.status_lbl.setStyleSheet("font-size: 14px; font-weight: bold; color: #1a7f37;")
            self.status_frame.setStyleSheet("background: #d4f7df; border-radius: 10px;")
        else:
            self.dot.setStyleSheet("font-size: 22px; color: #ff453a;")
            self.status_lbl.setText("Novint Falcon DESCONECTADO  ✘  (conecta el cable USB)")
            self.status_lbl.setStyleSheet("font-size: 14px; font-weight: bold; color: #b22222;")
            self.status_frame.setStyleSheet("background: #ffe5e5; border-radius: 10px;")

    # ──────────────────────────────────────────────────────────────────────
    def _open_hapticdesk(self):
        try:
            os.startfile(HAPTICDESK_LNK)
        except Exception as e:
            QMessageBox.critical(self, "Error", f"No se pudo abrir HapticDesk:\n{e}")

    def _open_h3dviewer(self):
        try:
            # El acceso directo (.lnk) es manejado perfectamente por Windows
            os.startfile(H3DVIEWER_LNK)
        except Exception as e:
            QMessageBox.critical(self, "Error", f"No se pudo abrir H3DViewer:\n{e}")

    def _run_scene(self, filename):
        path = os.path.join(CURRENT_DIR, filename)
        if not os.path.exists(path):
            QMessageBox.critical(self, "Error", f"Archivo no encontrado:\n{filename}")
            return
        if not os.path.exists(H3DVIEWER_EXE):
            QMessageBox.critical(self, "Error",
                f"No se encontró H3DViewer.exe en:\n{H3DVIEWER_EXE}\n\nVerifica la instalación de H3DAPI 2.4.0.")
            return
        try:
            # INYECCION DE PATH: VSCode/Python no conocen la nueva ruta de librerias de H3D
            env = os.environ.copy()
            h3d_bin = os.path.dirname(H3DVIEWER_EXE)
            h3d_ext = os.path.join(os.path.dirname(h3d_bin), "External", "bin64")
            if os.path.exists(h3d_ext):
                # Forzamos que Windows busque las DLLs faltantes de wxWidgets en External/bin64
                env["PATH"] = h3d_ext + os.pathsep + h3d_bin + os.pathsep + env.get("PATH", "")
                
            subprocess.Popen([H3DVIEWER_EXE, path], cwd=h3d_bin, env=env)
        except Exception as e:
            QMessageBox.critical(self, "Error al lanzar escena", str(e))


if __name__ == "__main__":
    app = QApplication(sys.argv)
    w = HapticLabUmng()
    w.show()
    sys.exit(app.exec())
