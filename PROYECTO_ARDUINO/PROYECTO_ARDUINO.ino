#include <SPI.h>          // Librería para comunicación SPI
#include <MFRC522.h>      // Librería del lector RFID RC522
#include <Servo.h>        //Libreria para el servo

//pines de conexion
#define buzzerPin 8
#define SS_PIN 10          // Pin para SDA (selección de esclavo)
#define RST_PIN 9          // Pin de reset del módulo RFID
#define ledVerde 6        //Conectamos led rojo 
#define ledRojo 7         //conectamos led verde
#define Servopin 5    //servo conectado al pin 5

MFRC522 mfrc522(SS_PIN, RST_PIN);  // Crea el objeto del lector RFID
Servo servo;            //creamos el objeto del Servo

//antes teniamos Struct y String pero ya no es necesario

void setup() {
  Serial.begin(9600);      // Inicia comunicación serial con la PC
  SPI.begin();             // Inicia comunicación SPI
  mfrc522.PCD_Init();      // Inicializa el lector RFID
  servo.attach(Servopin);   //Para inicializar servo 
  servo.write(0);   //Posicion inicial del Servo (Puerta Cerrada)
  pinMode(ledRojo, OUTPUT);
  pinMode(ledVerde, OUTPUT);
  digitalWrite(ledRojo, LOW);
  digitalWrite(ledVerde, LOW);

  pinMode(buzzerPin, OUTPUT);
  digitalWrite(buzzerPin, LOW);
  Serial.println("SISTEMA INICIADO.");  // Mensaje de inicio
}

void loop() {
  //revisamos si llego comando de processing
 if (Serial.available() > 0) {
    String comando = Serial.readStringUntil('\n');
    comando.trim();
    if (comando == "99") {
      abrirPuerta();
    } else if (comando == "DENY") {
      digitalWrite(ledRojo, HIGH);
      
      for(int i=0; i<3; i++){
       digitalWrite(buzzerPin, HIGH);
       delay(100);
       digitalWrite(buzzerPin, LOW);
       delay(100);
      }

      delay(3000);
      digitalWrite(ledRojo, LOW);
    }else if(comando == "1"){
      //registrar tarjeta
      registrarTarjeta();
    }else if(comando == "2"){
      //eliminar tarjeta
      eliminarTarjeta();
    }else if(comando == "3"){
      //listar tarjetas, solo mensaje, porque processing maneja eso
    } 
  }

  String idTarjeta = leerTarjeta();
  if (idTarjeta != "") {
    //Mandamos UID a processing
    Serial.println("UID:"+ idTarjeta);
  }
}

//funcion para leer Tarjeta
String leerTarjeta() {
  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) {
    return "";
  }

  String idTarjeta = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    idTarjeta += (mfrc522.uid.uidByte[i] < 0x10 ? "0" : "");
    idTarjeta += String(mfrc522.uid.uidByte[i], HEX);
  }
  idTarjeta.toUpperCase();
  Serial.println("TARJETA DETECTADA");
  
  //liberamos la tarjeta para que se lea otra
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
  
  return idTarjeta;
}

void registrarTarjeta() {
  Serial.println("MODO REGISTRO ACTIVADO. Acerca la tarjeta a registrar");

  String idTarjeta = "";
  unsigned long tiempoInicio = millis();
  while (true) {
    idTarjeta = leerTarjeta();
    if (idTarjeta != "") {
      break;
    }
    if (millis() - tiempoInicio > 5000) {
      Serial.println("TIEMPO DE ESPERA AGOTADO, INTENTA DE NUEVO...");
      return;
    }
    delay(100);
  }

  Serial.println("INGRESE EL NOMBRE: ");
  while (Serial.available() == 0) {}
  String nombre = Serial.readStringUntil('\n');
  nombre.trim();

  Serial.println("INGRESE EL CARGO: ");
  while (Serial.available() == 0) {}
  String cargo = Serial.readStringUntil('\n');
  cargo.trim();

  Serial.println("OK:" + idTarjeta + ":" + nombre + ":" + cargo);
}

void eliminarTarjeta() {
  Serial.println("Acerque la tarjeta para eliminarla...");

  String idTarjeta = "";
  unsigned long tiempoInicio = millis();
  while (true) {
    idTarjeta = leerTarjeta();
    if (idTarjeta != "") {
      break;
    }
    if (millis() - tiempoInicio > 5000) {
      Serial.println("TIEMPO DE ESPERA AGOTADO, INTENTA DE NUEVO...");
      return;
    }
    delay(100);
  }
  Serial.println("DEL:" + idTarjeta);
}

void listarTarjetas() {
  Serial.println("TARJETAS REGISTRADAS:");
}

void abrirPuerta(){
  digitalWrite(buzzerPin, HIGH)
  digitalWrite(ledRojo, LOW);
  digitalWrite(ledVerde, HIGH);
  servo.write(75);
  delay(3000);
  servo.write(0);
  digitalWrite(ledRojo, LOW);
  digitalWrite(ledVerde, LOW);
  digitalWrite(buzzerPin, LOW);
}