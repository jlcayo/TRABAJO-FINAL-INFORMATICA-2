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
  /* Si no hay una nueva tarjeta o no lee, vuelve al inicio del loop
  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) {
    return;
  }*/

  /*Serial.print("Tarjeta detectada: ");
  String idTarjeta = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    idTarjeta += (mfrc522.uid.uidByte[i] < 0x10 ? "0" : "");
    idTarjeta += String(mfrc522.uid.uidByte[i], HEX);
  }
  idTarjeta.toUpperCase();
  Serial.println(idTarjeta);  // Muestra el ID de la tarjeta

  if (idTarjeta == "432A4B1A") { //Probamos con tajeta maestra
    Serial.println("ACCESO TARJETA MAESTRA");
    digitalWrite(LedRojo, LOW);
    digitalWrite(LedVerde, HIGH);
    servo.write(90);
    delay(3000);
    servo.write(0);
    digitalWrite(LedVerde, LOW);
  } else {
    Serial.println("ACCESO DENEGADO");
    digitalWrite(LedRojo, HIGH);
    digitalWrite(LedVerde, LOW);
    delay(3000);
    digitalWrite(LedRojo, LOW);
  }*/
  if (Serial.available() > 0) {
    int opcion = Serial.readStringUntil('\n').toInt();
    procesarComando(opcion);
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
  return idTarjeta;
}

void verificarAcceso(String id) {
  if (id == tarjetaMaestra) {
    Serial.println("ACCESO TARJETA MAESTRA");
    digitalWrite(ledRojo, LOW);
    digitalWrite(ledVerde, HIGH);
    servo.write(90);
    delay(3000);
    servo.write(0);
  } else {
    int indice = buscarTarjeta(id);
    if (indice != -1) {
      Serial.print("NOMBRE: ");
      Serial.println(tarjetasHabilitadas[indice].nombre);
      Serial.print("CARGO: ");
      Serial.println(tarjetasHabilitadas[indice].cargo);
      Serial.println("ACCESO PERMITIDO");
      digitalWrite(ledRojo, LOW);
      digitalWrite(ledVerde, HIGH);
      servo.write(90);
      delay(3000);
      servo.write(0);
    } else {
      Serial.println("ACCESO DENEGADO.");
      digitalWrite(ledRojo, HIGH);
      digitalWrite(ledVerde, LOW);
      delay(2000);
      digitalWrite(ledRojo, LOW);
      digitalWrite(ledVerde, LOW);
    }
  }
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

  int indice = buscarTarjeta(idTarjeta);
  if (indice == -1) {
    Serial.println("TARJETA NO ENCONTRADA");
    return;
  }

  Serial.print("TARJETA DE ");
  Serial.print(tarjetasHabilitadas[indice].nombre);
  Serial.print(" (");
  Serial.print(tarjetasHabilitadas[indice].cargo);
  Serial.println(") ELIMINADA");

  for (int i = indice; i < numTarjetas - 1; i++) {
    tarjetasHabilitadas[i] = tarjetasHabilitadas[i + 1];
  }
  numTarjetas--;
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