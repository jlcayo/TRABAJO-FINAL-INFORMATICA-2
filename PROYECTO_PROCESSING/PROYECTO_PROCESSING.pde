import processing.serial.*;
import controlP5.*;

Serial myPort;
String inputString = "";

boolean ledVerde = false;
boolean ledRojo = false;  

String ultimoID = "";
String ultimoNombre = "";
String ultimoCargo = "";
String ultimoEstado = "";

ControlP5 cp5;

void setup() {
  size(1104, 630);
  printArray(Serial.list()); // Muestra los puertos seriales disponibles
  myPort = new Serial(this, "COM5", 9600); // Cambia "COM5" por el puerto que uses
  myPort.bufferUntil('\n');
  
  cp5 = new ControlP5(this);

  cp5.addButton("Registrar")
    .setPosition(850, 150)
    .setSize(220, 60)
    .setCaptionLabel("REGISTRAR TARJETA");

  cp5.addButton("Eliminar")
    .setPosition(850, 220)
    .setSize(220, 60)
    .setCaptionLabel("ELIMINAR TARJETA");

  cp5.addButton("Listar")
    .setPosition(850, 290)
    .setSize(220, 60)
    .setCaptionLabel("LISTAR TARJETAS");
}

void draw() {
  background(220);
  
  // Dibujar LEDs
  fill(255);
  rect(200, 300, 120, 120); // Fondo LED Verde
  rect(400, 300, 120, 120); // Fondo LED Rojo
  
  // Dibujar LED Verde
  if (ledVerde) {
    fill(0, 255, 0); // Verde
  } else {
    fill(0, 50, 0); // Verde apagado
  }
  ellipse(260, 360, 100, 100);

  // Dibujar LED Rojo
  if (ledRojo) {
    fill(255, 0, 0); // Rojo
  } else {
    fill(50, 0, 0); // Rojo apagado
  }
  ellipse(460, 360, 100, 100);
  
  // Mostrar información de la tarjeta
  fill(0);
  textSize(20);
  text("Ultimo Movimiento:", 50, 50);
  text("Estado: " + ultimoEstado, 50, 80);
  text("ID: " + ultimoID, 50, 110);
  if (ultimoNombre != "") {
    text("Nombre: " + ultimoNombre, 50, 140);
    text("Cargo: " + ultimoCargo, 50, 170);
  }
}

public void Registrar() {
  println("Registrar Tarjeta");
  myPort.write("1\n");
}

public void Eliminar() {
  println("Eliminar tarjeta");
  myPort.write("2\n");
}

public void Listar() {
  println("Listar tarjetas");
  myPort.write("3\n");
}

void serialEvent(Serial myPort) {
  inputString = myPort.readStringUntil('\n');
  if (inputString != null) {
    inputString = trim(inputString);
    println("Mensaje recibido: " + inputString);
    
    String[] parts = split(inputString, ':');
    if (parts[0].equals("MASTER")) {
      ledVerde = true;
      ledRojo = false;
      ultimoEstado = "Tarjeta Maestra";
      ultimoID = parts[1];
      ultimoNombre = "";
      ultimoCargo = "";
    }else if (parts[0].equals("UID")) {
      ultimoID = trim(parts[1]);
      println("UID recibido: " + ultimoID);
    }else if (parts[0].equals("OK")) {
      ultimoID = trim(parts[1]);
      if (parts.length >= 4) {
        ultimoNombre = parts[2];
        ultimoCargo = parts[3];
      }
      println("OK recibido, ID:" + ultimoID);
    } else if (parts[0].equals("NO")) {
      ledRojo = true;
      ledVerde = false;
      ultimoEstado = "Acceso Denegado";
      ultimoID = parts[1];
      ultimoNombre = "";
      ultimoCargo = "";
    }
  }
}
