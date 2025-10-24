//probando cambios
#include <SPI.h>          // Librería para comunicación SPI
#include <MFRC522.h>      // Librería del lector RFID RC522

#include <Servo.h>        //Libreria para el servo

#define SS_PIN 10          // Pin para SDA (selección de esclavo)
#define RST_PIN 9          // Pin de reset del módulo RFID
#define LedVerde 6        //Conectamos led rojo 
#define LedRojo 7         //conectamos led verde

#define Servopin 5    //servo conectado al pin 5

MFRC522 mfrc522(SS_PIN, RST_PIN);  // Crea el objeto del lector RFID

Servo servo;            //creamos el objeto del Servo

void setup() {
  Serial.begin(9600);      // Inicia comunicación serial con la PC
  SPI.begin();             // Inicia comunicación SPI
  mfrc522.PCD_Init();      // Inicializa el lector RFID

  servo.attach(Servopin);   //Para inicializar servo 
  servo.write(0);   //Posicion inicial del Servo (Puerta Cerrada)

  pinMode(LedRojo, OUTPUT);
  pinMode(LedVerde, OUTPUT);

  digitalWrite(LedRojo, HIGH); //led rojo encendido al inicio 
  digitalWrite(LedVerde, LOW);

  Serial.println("Acerca una tarjeta...");  // Mensaje de inicio
}

void loop() {
  // Si no hay una nueva tarjeta, vuelve al inicio del loop
  if (!mfrc522.PICC_IsNewCardPresent()) return;

  // Si no puede leer la tarjeta, vuelve al inicio del loop
  if (!mfrc522.PICC_ReadCardSerial()) return;

  // Si la tarjeta se detecta correctamente:
  //Serial.print("Tarjeta detectada: ");

  // Muestra en el monitor serie el ID (UID) de la tarjeta
  //for (byte i = 0; i < mfrc522.uid.size; i++) {
    //Serial.print(mfrc522.uid.uidByte[i], HEX);
  //}
  //Serial.println();  // Salto de línea para la siguiente lectura
  
    // Si la tarjeta se detecta correctamente:
  Serial.print("Tarjeta detectada: ");
  String idTarjeta = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    idTarjeta += (mfrc522.uid.uidByte[i] < 0x10 ? "0" : "");
    idTarjeta += String(mfrc522.uid.uidByte[i], HEX);
  }
  Serial.println(idTarjeta);  // Muestra el ID de la tarjeta

  digitalWrite(LedRojo, LOW);
  digitalWrite(LedVerde, HIGH);

  servo.write(90); //abre la puerta a 90 grados

  delay(3000);       // Espera 3 segundo antes de leer otra tarjeta

  servo.write(0); //cierra la puerta 

  digitalWrite(LedVerde, LOW);
  digitalWrite(LedRojo, HIGH);
  
}
