import processing.serial.*;

Serial myPort;
String inputString = "";
boolean ledVerde = false;
boolean ledRojo = false;  

void setup() {
  size(800, 600);
  printArray(Serial.list()); // Muestra los puertos seriales disponibles
  myPort = new Serial(this, "COM5", 9600); // Cambia "COM5" por el puerto que uses
  myPort.bufferUntil('\n');
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
}

void serialEvent(Serial myPort) {
  inputString = myPort.readStringUntil('\n');
  if (inputString != null) {
    inputString = trim(inputString);
    println("Mensaje recibido: " + inputString);
    
    if (inputString.equals("ACCESO TARJETA MAESTRA")) {
      ledVerde = true;
      ledRojo = false;
    } else if (inputString.equals("ACCESO DENEGADO")) {
      ledVerde = false;
      ledRojo = true;
    } else if (inputString.equals("ACCESO PERMITIDO")) {
      ledVerde = true;
      ledRojo = false;
    }
  }
}
