#include <Arduino.h>

// ---------- Pines puente H ----------
#define IN1 19
#define IN2 18
#define IN3 5
#define IN4 17
#define ENA 23
#define ENB 22

// ---------- Variables motor ----------
const int v_max = 255;

// ---------- Prototipos ----------
void avanzar(int v);

void setup() {
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  pinMode(ENA, OUTPUT);
  pinMode(ENB, OUTPUT);

  avanzar(v_max);  // ¡Arranca recto al encender
}

void loop() {
  // Nada que hacer aquí. El robot sigue avanzando
}

void avanzar(int v) {
  analogWrite(ENA, v);
  analogWrite(ENB, v);
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
}