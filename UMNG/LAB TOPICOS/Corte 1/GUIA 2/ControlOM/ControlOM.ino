#include <Arduino.h>
#include "BluetoothSerial.h"
#include "esp_timer.h"
#include <math.h>

#define BOOT_BUTTON 0

// ---------- Pines QTR8RC ----------
const uint8_t SensorCount = 8;
const uint8_t sensorPins[SensorCount] = {4, 15, 14, 27, 26, 25, 33, 32};
#define LED_ON 12

// ---------- Pines puente H ----------
#define IN1 19
#define IN2 18
#define IN3 5
#define IN4 17
#define ENA 23
#define ENB 22

// ---------- Geometría del robot ----------
const float distEje = 133.0;    // mm
const float distSens = 9.525;   // mm

// ---------- Variables sensor ----------
unsigned int rawValues[SensorCount];
unsigned int minVals[SensorCount];
unsigned int maxVals[SensorCount];
float thetaSensor[SensorCount];
volatile int sensor_activo[SensorCount];
uint16_t activo = 0;
volatile double theta = 0;
float entrada = 0;
int TH_ACTIVO = 650;
const unsigned int TIMEOUT_US = 3000;

// ---------- Variables motor ----------
const int v_max = 255;
const int v_min = 250;

// ---------- Variables envío ----------
volatile float envioValores[1000];
volatile int n = 0;

// ---------- Bluetooth ----------
BluetoothSerial SerialBT;
const unsigned long Ts = 10000;

// ---------- Timer ----------
bool started = false;
esp_timer_handle_t timer;

// ---------- Controlador ----------
volatile float uk, u_prev, e_prev;

// ---------- Prototipos ----------
void periodic_timer_callback(void* arg);
void Control(float ang, float in);
void cerrar_izquierda(int v);
void cerrar_derecha(int v);
void parar();
void readQTRRC(unsigned int *sensorValues);
void doCalibration(int samples = 300, int delayMs = 20);
void printCalibrationSummary();
void calcularTheta();

void setup()
{
  Serial.begin(115200);
  SerialBT.begin("ESP32_Topicos");

  pinMode(LED_ON, OUTPUT);
  digitalWrite(LED_ON, HIGH);

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  pinMode(ENA, OUTPUT);
  pinMode(ENB, OUTPUT);
  pinMode(BOOT_BUTTON, INPUT_PULLUP);

  const esp_timer_create_args_t timer_args = {
    .callback = &periodic_timer_callback,
    .name = "mi_timer"
  };
  esp_timer_create(&timer_args, &timer);

  for (uint8_t i = 0; i < SensorCount; i++) {
    minVals[i] = TIMEOUT_US;
    maxVals[i] = 0;
  }

  calcularTheta();

  delay(500);
  Serial.println("Iniciando calibración automática...");
  doCalibration(400, 5);
  Serial.println("Calibración automática completada.");
}

void loop()
{
  char comando = 0;   // Declarar fuera del if para que sea visible en todo loop

  if (Serial.available()) {
    comando = Serial.read();

    if (comando == 'c') {
      Serial.println("Iniciando calibración manual...");
      parar();  // ← Detiene los motores antes de calibrar
      doCalibration(400, 5);
      Serial.println("Calibración manual completada.");
    } 
    else if (comando == 'p') {
      printCalibrationSummary();
    }
  }

  // --- Procesamiento de sensores ---
  activo = 0;
  readQTRRC(rawValues);

  float num = 0;
  float den = 0;
  int idxDominante = -1;
  int maxValNorm = -1;

  for (uint8_t i = 0; i < SensorCount; i++) {
    int norm;
    if (maxVals[i] > minVals[i]) {
      long tmp = map(rawValues[i], minVals[i], maxVals[i], 0, 1000);
      tmp = constrain(tmp, 0, 1000);
      norm = (int)tmp;
    } else {
      norm = 0;
    }

    if (norm > TH_ACTIVO) {
      sensor_activo[activo] = i;
      activo++;
      num += thetaSensor[i] * norm;
      den += norm;
      if (norm > maxValNorm) {
        maxValNorm = norm;
        idxDominante = i;
      }
    }
  }

  if (activo == 1 && idxDominante >= 0) {
    theta = thetaSensor[idxDominante];
  } else if (activo > 1 && den > 0) {
    theta = num / den;
  } else {
    theta = 0;
  }

  // --- Mapa ASCII ---
  String mapa = "";
  for (uint8_t i = 0; i < SensorCount; i++) {
    int norm;
    if (maxVals[i] > minVals[i]) {
      long tmp = map(rawValues[i], minVals[i], maxVals[i], 0, 1000);
      tmp = constrain(tmp, 0, 1000);
      norm = (int)tmp;
    } else {
      norm = 0;
    }
    mapa += (norm > TH_ACTIVO) ? "⬛" : "⬜";
  }

  Serial.print("Mapa: ");
  Serial.println(mapa);
  Serial.print("Ángulo medido: ");
  Serial.print(theta, 2);
  Serial.println("°");
  Serial.println("-----------------------------");

  for (uint8_t i = 0; i < SensorCount; i++) {
    sensor_activo[i] = 0;
  }

  if (!started) {
    esp_timer_start_periodic(timer, Ts);
    started = true;
  }
}

//OSCILACIONES MUERTAS.
void Control(float ang, float in) {
  static float y1 = 0.0f, y2 = 0.0f;  
  static float u1 = 0.0f, u2 = 0.0f;  

  static unsigned long tiempoPerdida = 0;    // momento en que se perdió la línea
  static int ultimaDireccion = 0;            // -1 izquierda, +1 derecha, 0 nada

  float error = in - ang;
  float u = error;

  // Coeficientes discretos (ejemplo)
  const float a1 = -0.5148f;
  const float a2 = -0.4852f;
  const float b0 = 71.9925f;
  const float b1 = -131.2399f;
  const float b2 = 60.2469f;

  float y = -a1 * y1 - a2 * y2 + b0 * u + b1 * u1 + b2 * u2;
  y = constrain(y, -14.02f, 14.02f);

  // ------------------- CONTROL DE VELOCIDAD -------------------
  int velocidad;
  const float k_vel = 5.0f;   // más bajo → frena más en curvas
  const float umbralCurva = 2.05f;  // error grande → curva cerrada //2.05

  if (fabs(error) < 2.05f && activo > 0) {
    // Robot centrado → máxima velocidad
    velocidad = v_max;
    avanzar(velocidad);
  } 
  else if (fabs(error) > umbralCurva) {
    // Curva fuerte → velocidad mínima
    velocidad = v_min;
  } 
  else {
    // Correcciones suaves → velocidad proporcional cuadrática
    velocidad = constrain(v_max - (int)(k_vel * error * error), v_min, v_max);
  }

  // actualizar estados
  y2 = y1; y1 = y;
  u2 = u1; u1 = u;
  uk = y; u_prev = y; e_prev = error;

  // ------------------- LÓGICA DE MOVIMIENTO -------------------
  if (error >= 12.0f) { //8.05 - 12.0
    cerrar_derecha(velocidad);
    ultimaDireccion = +1;
    tiempoPerdida = 0;  // resetea el temporizador
  } 
  else if (error <= -12.0f) {
    cerrar_izquierda(velocidad);
    ultimaDireccion = -1;
    tiempoPerdida = 0;
  } 
  else if (activo > 0) {
    avanzar(velocidad);
    ultimaDireccion = 0;
    tiempoPerdida = 0;
  } 
  else {
    // No hay línea
    if (tiempoPerdida == 0) {
      tiempoPerdida = millis();   // marca el inicio de la pérdida
    }

    if (millis() - tiempoPerdida <= 1500) {
      // hasta 1.5s sigue en la última dirección, pero con v_min
      if (ultimaDireccion == +1) {
        cerrar_derecha(v_min);
      } else if (ultimaDireccion == -1) {
        cerrar_izquierda(v_min);
      } else {
        parar();
      }
    } else {
      // ya pasó 1s sin línea -> parar
      parar();
      ultimaDireccion = 0;
    }
  }
}



void cerrar_derecha(int v) {
  // Motor izquierdo avanza más rápido
  int v_izq = constrain(v + 40, v_min, v_max);  
  // Motor derecho retrocede proporcionalmente
  int v_der = constrain(v + 40, v_min, v_max);

  analogWrite(ENA, v_izq);
  analogWrite(ENB, v_der);

  digitalWrite(IN1, HIGH);  // Izquierdo adelante
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);   // Derecho atrás
  digitalWrite(IN4, HIGH);
}

void cerrar_izquierda(int v) {
  int v_izq = constrain(v + 40, v_min, v_max);
  int v_der = constrain(v + 40, v_min, v_max);

  analogWrite(ENA, v_izq);
  analogWrite(ENB, v_der);

  digitalWrite(IN1, LOW);   // Izquierdo atrás
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, HIGH);  // Derecho adelante
  digitalWrite(IN4, LOW);
}

void avanzar(int v) {
  analogWrite(ENA, v);
  analogWrite(ENB, v);
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
}

void parar() {
  analogWrite(ENA, 0);
  analogWrite(ENB, 0);
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}
// =========== CALLBACK DEL TIMER (EJECUTADO CADA Ts = 10 ms) ============
// =======================================================================
void periodic_timer_callback(void* arg) {

  Control(theta, entrada); 

  static float uk_ = 0.0f;
  const float alpha = 0.15f;
  uk_ = alpha * uk + (1 - alpha) * uk_;

  // --- (3) Variables enviadas a MATLAB ---
  float error_env = entrada - theta;
  float ref_env   = entrada;
  float sal_env   = theta;
  float ctrl_env  = uk_;

  // --- (4) Empaquetar y enviar 4 floats (16 bytes) ---
  byte buffer[16];
  memcpy(&buffer[0],  &error_env, sizeof(float));
  memcpy(&buffer[4],  &ref_env,   sizeof(float));
  memcpy(&buffer[8],  &sal_env,   sizeof(float));
  memcpy(&buffer[12], &ctrl_env,  sizeof(float));

  SerialBT.write(buffer, 16);

  if (n < 1000) n++;
}
void readQTRRC(unsigned int *sensorValues) {
  for (uint8_t i = 0; i < SensorCount; i++) {
    pinMode(sensorPins[i], OUTPUT);
    digitalWrite(sensorPins[i], HIGH);
  }
  delayMicroseconds(10);
  for (uint8_t i = 0; i < SensorCount; i++) {
    pinMode(sensorPins[i], INPUT);
  }

  unsigned long startTime = micros();
  bool done[SensorCount] = {false};

  while ((micros() - startTime) < TIMEOUT_US) {
    unsigned long elapsed = micros() - startTime;
    for (uint8_t i = 0; i < SensorCount; i++) {
      if (!done[i] && digitalRead(sensorPins[i]) == LOW) {
        sensorValues[i] = elapsed;
        done[i] = true;
      }
    }
  }

  for (uint8_t i = 0; i < SensorCount; i++) {
    if (!done[i]) sensorValues[i] = TIMEOUT_US;
  }
}

void doCalibration(int samples, int delayMs) {
  Serial.println("=== CALIBRACIÓN INICIADA ===");
  Serial.println("Mueve el robot sobre fondo blanco y línea negra repetidamente.");

  for (uint8_t i = 0; i < SensorCount; i++) {
    minVals[i] = TIMEOUT_US;
    maxVals[i] = 0;
  }

  unsigned int temp[SensorCount];
  for (int k = 0; k < samples; k++) {
    readQTRRC(temp);
    for (uint8_t i = 0; i < SensorCount; i++) {
      if (temp[i] < minVals[i]) minVals[i] = temp[i];
      if (temp[i] > maxVals[i]) maxVals[i] = temp[i];
    }
    delay(delayMs);
  }

  for (uint8_t i = 0; i < SensorCount; i++) {
    if (maxVals[i] <= minVals[i]) {
      maxVals[i] = minVals[i] + 1;
    }
  }

  printCalibrationSummary();
  TH_ACTIVO = 600;
  Serial.print("Umbral ajustado a ");
  Serial.println(TH_ACTIVO);
  Serial.println("============================");

  // ===== Envío de datos al final de la calibración =====
  Serial.println("=== DATOS DE CALIBRACIÓN PARA PROMEDIO ===");
  Serial.print("minVals: ");
  for (uint8_t i = 0; i < SensorCount; i++) {
    Serial.print(minVals[i]);
    if (i < SensorCount - 1) Serial.print(", ");
  }
  Serial.println();

  Serial.print("maxVals: ");
  for (uint8_t i = 0; i < SensorCount; i++) {
    Serial.print(maxVals[i]);
    if (i < SensorCount - 1) Serial.print(", ");
  }
  Serial.println();
  Serial.println("==========================================");
}

void printCalibrationSummary() {
  Serial.println("Resumen de calibración:");
  for (uint8_t i = 0; i < SensorCount; i++) {
    Serial.print("s");
    Serial.print(i);
    Serial.print(": min=");
    Serial.print(minVals[i]);
    Serial.print(" max=");
    Serial.print(maxVals[i]);
    Serial.print(" diff=");
    Serial.println(maxVals[i] - minVals[i]);
  }
}

void calcularTheta() {
  for (uint8_t i = 0; i < SensorCount; i++) {
    float xi = (i - 3.5) * distSens;
    thetaSensor[i] = -atan2(xi, distEje) * 180.0 / PI;
  }
}