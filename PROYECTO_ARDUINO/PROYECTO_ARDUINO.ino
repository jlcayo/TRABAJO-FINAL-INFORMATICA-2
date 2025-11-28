//probando cambios
#include <SPI.h>          // Librería para comunicación SPI
#include <MFRC522.h>      // Librería del lector RFID RC522

#include <Servo.h>        //Libreria para el servo

#define SS_PIN 10          // Pin para SDA (selección de esclavo)
#define RST_PIN 9          // Pin de reset del módulo RFID
#define ledVerde 6        //Conectamos led rojo 
#define ledRojo 7         //conectamos led verde

#define Servopin 5    //servo conectado al pin 5

MFRC522 mfrc522(SS_PIN, RST_PIN);  // Crea el objeto del lector RFID

Servo servo;            //creamos el objeto del Servo

struct tarjeta{
  String id;
  String nombre;
  String cargo;
};

tarjeta tarjetasHabilitadas[15];
int numTarjetas = 0;
const String tarjetaMaestra = "432A4B1A";

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

  Serial.println("SISTEMA INICIADO");  // Mensaje de inicio
  mostrarMenu();
}

void loop() {
 if (Serial.available() > 0) {
    String comando = Serial.readStringUntil('\n');
    comando.trim();
    if (comando == "99") {
      abrirPuerta();
    } else if (comando == "DENY") {
      digitalWrite(ledRojo, HIGH);
      delay(3000);
      digitalWrite(ledRojo, LOW);
    } else {
      int opcion = comando.toInt();
      if (opcion > 0) {
        procesarComando(opcion);
      }
    }
  }

  String idTarjeta = leerTarjeta();
  if (idTarjeta != "") {
    verificarAcceso(idTarjeta);
  }
}

void mostrarMenu(){
  Serial.println("---MENU---");
  Serial.println("1. REGISTRAR TARJETA");
  Serial.println("2. ELIMINAR TARJETA");
  Serial.println("3. LISTAR TARJETAS");
  Serial.println("Selecciona una opcion (1-3)");
}

void procesarComando(int opcion) {
  switch (opcion) {
    case 1:
      registrarTarjeta();
      break;
    case 2:
      eliminarTarjeta();
      break;
    case 3:
      listarTarjetas();
      break;
    case 99:
      abrirPuerta();
      break;
    default:
      Serial.println("Opcion no valida, ingrese un numero del 1 al 3");
      mostrarMenu();
  }
}

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
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
  
  return idTarjeta;
}

void verificarAcceso(String id) {
  Serial.println("UID: " + id);
}
 

int buscarTarjeta(String id) {
  for (int i = 0; i < numTarjetas; i++) {
    if (tarjetasHabilitadas[i].id == id) {
      return i;
    }
  }
  return -1;
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

  if (numTarjetas >= 15) {
    Serial.println("NO SE PUEDEN AGREGAR MAS TARJETAS.");
    return;
  }

  int indice = buscarTarjeta(idTarjeta);
  if (indice != -1) {
    Serial.println("ESTA TARJETA YA ESTA REGISTRADA");
    return;
  }

  Serial.println("INGRESE EL NOMBRE: ");
  while (Serial.available() == 0) {}
  String nombre = Serial.readStringUntil('\n');
  nombre.trim();

  Serial.println("INGRESE EL CARGO: ");
  while (Serial.available() == 0) {}
  String cargo = Serial.readStringUntil('\n');
  cargo.trim();

  tarjetasHabilitadas[numTarjetas].id = idTarjeta;
  tarjetasHabilitadas[numTarjetas].nombre = nombre;
  tarjetasHabilitadas[numTarjetas].cargo = cargo;
  numTarjetas++;

  Serial.print("TARJETA REGISTRADA A ");
  Serial.print(nombre);
  Serial.print(", ");
  Serial.println(cargo);
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
  Serial.println("Tarjeta de " + idTarjeta + " ELIMINADA");
}

void listarTarjetas() {
  Serial.println("TARJETAS REGISTRADAS:");
  if (numTarjetas == 0) {
    Serial.println("NO HAY TARJETAS REGISTRADAS");
  } else {
    Serial.println("-------------");
    for (int i = 0; i < numTarjetas; i++) {
      Serial.print("ID: ");
      Serial.println(tarjetasHabilitadas[i].id);
      Serial.print("NOMBRE: ");
      Serial.println(tarjetasHabilitadas[i].nombre);
      Serial.print("CARGO: ");
      Serial.println(tarjetasHabilitadas[i].cargo);
      Serial.println("-------------");
    }
  }
}

void abrirPuerta() {
  digitalWrite(ledRojo, LOW);
  digitalWrite(ledVerde, HIGH);
  servo.write(75);
  delay(3000);
  servo.write(0);
  digitalWrite(ledRojo, LOW);
  digitalWrite(ledVerde, LOW);
}