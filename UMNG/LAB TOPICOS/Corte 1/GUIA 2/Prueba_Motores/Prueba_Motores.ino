#include <Arduino.h>
#include <math.h>

// Configuración QTR-8RC
const uint8_t NUM_SENSORS = 8;
const uint8_t sensorPins[NUM_SENSORS] = {4, 15, 14, 27, 26, 25, 33, 32};
const uint8_t LEDON_PIN = 12;
const unsigned int TIMEOUT_US = 3000;

unsigned int rawValues[NUM_SENSORS];
unsigned int minVals[NUM_SENSORS];
unsigned int maxVals[NUM_SENSORS];

// Distancias
const float distEje = 133.0;    // mm eje → línea de sensores
const float distSens = 9.525;   // mm entre sensores

// Precalcular ángulos en grados
float theta[NUM_SENSORS];

// Umbral de detección normalizado (0..1000). Se puede ajustar o dejar automático.
int TH_ACTIVO = 650; // valor conservador después de calibración

// --- Prototipos ---
void calcularTheta();
void readQTRRC(unsigned int *sensorValues);
void doCalibration(int samples, int delayMs);
void printCalibrationSummary();

void calcularTheta() {
  for (uint8_t i = 0; i < NUM_SENSORS; i++) {
    float xi = (i - 3.5) * distSens;
    theta[i] = atan2(xi, distEje) * 180.0 / PI;
  }
}

void readQTRRC(unsigned int *sensorValues) {
  // Cargar capacitores
  for (uint8_t i = 0; i < NUM_SENSORS; i++) {
    pinMode(sensorPins[i], OUTPUT);
    digitalWrite(sensorPins[i], HIGH);
  }
  delayMicroseconds(10);

  // Cambiar a entrada y medir tiempo hasta que el pin pase a LOW
  for (uint8_t i = 0; i < NUM_SENSORS; i++) {
    pinMode(sensorPins[i], INPUT);
  }

  unsigned long startTime = micros();
  bool done[NUM_SENSORS] = {false};

  while ((micros() - startTime) < TIMEOUT_US) {
    unsigned long elapsed = micros() - startTime;
    for (uint8_t i = 0; i < NUM_SENSORS; i++) {
      if (!done[i] && digitalRead(sensorPins[i]) == LOW) {
        sensorValues[i] = elapsed;
        done[i] = true;
      }
    }
  }

  for (uint8_t i = 0; i < NUM_SENSORS; i++) {
    if (!done[i]) sensorValues[i] = TIMEOUT_US;
  }
}

void doCalibration(int samples = 300, int delayMs = 20) {
  Serial.println();
  Serial.println("=== CALIBRACION INICIADA ===");
  Serial.println("Instrucciones: mueve el robot por la superficie blanca y la linea negra repetidamente.");
  Serial.print("Recolectando ");
  Serial.print(samples);
  Serial.println(" lecturas (~6 s) ...");

  // inicializar
  for (uint8_t i = 0; i < NUM_SENSORS; i++) {
    minVals[i] = TIMEOUT_US; // valores grandes inicialmente
    maxVals[i] = 0;
  }

  unsigned int temp[NUM_SENSORS];
  for (int k = 0; k < samples; k++) {
    readQTRRC(temp);
    for (uint8_t i = 0; i < NUM_SENSORS; i++) {
      if (temp[i] < minVals[i]) minVals[i] = temp[i];
      if (temp[i] > maxVals[i]) maxVals[i] = temp[i];
    }
    delay(delayMs);
  }

  // Saneamiento: evitar min == max
  for (uint8_t i = 0; i < NUM_SENSORS; i++) {
    if (maxVals[i] <= minVals[i]) {
      // fuerza un rango mínimo pequeño
      maxVals[i] = minVals[i] + 1;
    }
  }

  Serial.println("Calibracion completada.");
  printCalibrationSummary();

  // Ajuste simple del umbral: 60% del rango normalizado (0..1000)
  TH_ACTIVO = 600;
  Serial.print("Umbral TH_ACTIVO ajustado a ");
  Serial.print(TH_ACTIVO);
  Serial.println(" (normalizado 0..1000).");
  Serial.println("============================");
  Serial.println();
}

void printCalibrationSummary() {
  Serial.println("Resumen min/max (us):");
  for (uint8_t i = 0; i < NUM_SENSORS; i++) {
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

void setup() {
  Serial.begin(115200);
  pinMode(LEDON_PIN, OUTPUT);
  digitalWrite(LEDON_PIN, HIGH);

  // valores iniciales por si no se calibra
  for (uint8_t i = 0; i < NUM_SENSORS; i++) {
    minVals[i] = TIMEOUT_US;
    maxVals[i] = 0;
  }

  calcularTheta();
  Serial.println("Iniciando. Enviar 'c' por serial para calibrar.");
}

void loop() {
  // chequeo sencillo de comando serial
  if (Serial.available()) {
    char c = Serial.read();
    if (c == 'c' || c == 'C') {
      doCalibration(300, 20); // ~6 s de calibración; ajusta si quieres
    } else if (c == 'p' || c == 'P') {
      printCalibrationSummary();
    }
  }

  readQTRRC(rawValues);

  // ---- Imprimir valores y calcular método 2 ----
  float num = 0;   // numerador ponderado
  float den = 0;   // denominador
  int activos = 0;
  int idxDominante = -1;
  int maxValNorm = -1;

  for (uint8_t i = 0; i < NUM_SENSORS; i++) {
    int norm;
    if (maxVals[i] > minVals[i]) {
      long tmp = map(rawValues[i], (long)minVals[i], (long)maxVals[i], 0, 1000);
      if (tmp < 0) tmp = 0;
      if (tmp > 1000) tmp = 1000;
      norm = (int)tmp;
    } else {
      norm = 0;
    }

    Serial.print("s");
    Serial.print(i);
    Serial.print("=");
    Serial.print(norm);
    Serial.print(" (θ=");
    Serial.print(theta[i], 1);
    Serial.print("°)\t");

    if (norm > TH_ACTIVO) {
      num += theta[i] * norm;
      den += norm;
      activos++;
      if (norm > maxValNorm) {
        maxValNorm = norm;
        idxDominante = i;
      }
    }
  }
  Serial.println();

  // ---- Mapa ASCII usando el umbral calibrado ----
  String mapa = "";
  for (uint8_t i = 0; i < NUM_SENSORS; i++) {
    int norm;
    if (maxVals[i] > minVals[i]) {
      long tmp = map(rawValues[i], (long)minVals[i], (long)maxVals[i], 0, 1000);
      tmp = constrain(tmp, 0, 1000);
      norm = (int)tmp;
    } else {
      norm = 0;
    }
    mapa += (norm > TH_ACTIVO) ? "⬛" : "⬜";
  }

  Serial.print("Mapa: ");
  Serial.println(mapa);

  // ---- Decisión método 2 ----
  if (activos == 1 && idxDominante >= 0) {
    Serial.print("Ángulo medido (dominante): ");
    Serial.print(theta[idxDominante], 2);
    Serial.println("°");
  } else if (activos > 1 && den > 0) {
    float thetaMedido = num / den;
    Serial.print("Ángulo medido (promedio): ");
    Serial.print(thetaMedido, 2);
    Serial.println("°");
  } else {
    Serial.println("⚠️ Sin línea detectada");
  }

  Serial.println("-----------------------------");
  delay(250);
}