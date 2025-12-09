import processing.serial.*;
import controlP5.*;
import java.util.ArrayList;

Serial myPort;
String inputString = "";

boolean ledVerde = false;
boolean ledRojo = false;  
//variables para ultimo ingreso 
String ultimoID = "";
String ultimoNombre = "";
String ultimoCargo = "";
String ultimoEstado = "";

ControlP5 cp5;
String faseRegistro = "";
Textfield nombreField, cargoField;

PImage fondo;
int tiempoOverlay = 0;

ListaEnlazada listaTarjetas=new ListaEnlazada();

class Tarjeta {
  String id;
  String nombre;
  String cargo;
  // Constructor
  Tarjeta(String id, String nombre, String cargo) {
    this.id = id;
    this.nombre = nombre;
    this.cargo = cargo;
  }
  // Método para convertir a String en formato de archivo
  String toFileString() {
    return "ID:" + id + ";NOMBRE:" + nombre + ";CARGO:" + cargo;
  }
}

class Nodo {
  Tarjeta tarjeta;
  Nodo siguiente;
  Nodo(Tarjeta tarjeta) {
    this.tarjeta = tarjeta;
    this.siguiente = null;
  }
}  

class ListaEnlazada {
  Nodo cabeza;
  int tamaño;
  ListaEnlazada() {
    cabeza = null;
    tamaño = 0;
  }
  // Agregar una tarjeta al final de la lista
  void agregar(Tarjeta tarjeta) {
    Nodo nuevoNodo = new Nodo(tarjeta);
    if (cabeza == null) {
      cabeza = nuevoNodo;
    } else {
      Nodo actual = cabeza;
      while (actual.siguiente != null) {
        actual = actual.siguiente;
      }
      actual.siguiente = nuevoNodo;
    }
    tamaño++;
  }
  // Eliminar una tarjeta por ID
  boolean eliminar(String id) {
    if (cabeza == null) return false;
    String objetivo = id.trim().toUpperCase();
    if (cabeza.tarjeta.id.equals(id)) {
      cabeza = cabeza.siguiente;
      tamaño--;
      return true;
    }
    Nodo actual = cabeza;
    while (actual.siguiente != null) {  
      if (actual.siguiente.tarjeta.id.trim().toUpperCase().equals(objetivo)) {
        actual.siguiente = actual.siguiente.siguiente;
        tamaño--;
        return true;
      }
      actual = actual.siguiente;
    }
    return false;
  }
  // Buscar una tarjeta por ID
  Tarjeta buscar(String id) {
    String objetivo = id.trim().toUpperCase();
    Nodo actual = cabeza;
    while (actual != null) {
      if (actual.tarjeta.id.trim().toUpperCase().equals(objetivo)) {
        return actual.tarjeta;
      }
      actual = actual.siguiente;
    }
    return null;
  }
  // Obtener el tamaño de la lista
  int getTamaño() {
    return tamaño;
  }
  // Obtener todas las tarjetas como una lista de Strings para guardar en archivo
  ArrayList<String> getTarjetasComoStrings() {
    ArrayList<String> tarjetas = new ArrayList<String>();
    Nodo actual = cabeza;
    while (actual != null) {
      tarjetas.add(actual.tarjeta.toFileString());
      actual = actual.siguiente;
    }
    return tarjetas;
  }
}

// Admin: llave maestra y control de sesión
String llaveMaestraID = "432A4B1A"; 
String adminPassword  = "1234";            
boolean adminHabilitado = false;    
// Campo de contraseña
Textfield passField;
// Botón de cerrar sesión
Button btnCerrarSesion;

void setup() {
  size(1104, 630);
  fondo = loadImage("fondo.jpg");
  printArray(Serial.list()); // Muestra los puertos seriales disponibles
  myPort = new Serial(this, "COM5", 9600); // Cambia "COM5" por el puerto que uses
  textSize(20);
  
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
  //Personalización de colores
  cp5.getController("Registrar").setColorBackground(color(0, 150, 0));   // verde
  cp5.getController("Eliminar").setColorBackground(color(150, 0, 0));    // rojo
  
  // Ocultamos botones de administración al inicio
  cp5.getController("Registrar").setVisible(false);
  cp5.getController("Eliminar").setVisible(false);
  cp5.getController("Listar").setVisible(false);
  
  // Botón de cerrar sesión (admin)
  btnCerrarSesion = cp5.addButton("CerrarSesion")
                       .setPosition(850, 360)
                       .setSize(220, 60)
                       .setCaptionLabel("CERRAR SESIÓN");
  btnCerrarSesion.setVisible(false);
  btnCerrarSesion.setColorBackground(color(50, 50, 50));

    
  nombreField=cp5.addTextfield("Nombre")
                 .setPosition(width/2-100, height/2)
                 .setSize(200, 40)
                 .setVisible(false);

  cargoField=cp5.addTextfield("Cargo")
                .setPosition(width/2-100, height/2)
                .setSize(200, 40)
                .setVisible(false);  
    
  // Campo de contraseña para admin (inicialmente oculto)
  passField = cp5.addTextfield("Password")
                 .setPosition(width/2 - 100, height/2 + 20)
                 .setSize(200, 40)
                 .setVisible(false);
  try { passField.setPasswordMode(true); } catch(Exception e) { /* opcional */ }

  cargarTarjetasArchivo();
}

void draw() {
  image(fondo, 0 ,0, width, height); //dibujamos el fondo en toda la ventana
  
  fill(0, 150);
  rect(40, 60, 500, 160, 10);
  fill(255);
  textSize(32);
  textAlign(CENTER);
  text("SISTEMA DE CONTROL DE ACCESO 2.0", width/2, 50);
  textSize(25);
  textAlign(LEFT);
  text("Ultimo Movimiento", 80, 80);
  text("Estado: " + ultimoEstado, 50, 110);
  text("ID: " + ultimoID, 50, 140);
  if (ultimoNombre != "") {
    text("Nombre: " + ultimoNombre, 50, 170);
    text("Cargo: " + ultimoCargo, 50, 200);
  }
  
  // Dibujar LED Verde
  if (ledVerde) {
    fill(0, 255, 0); // Verde
  } else {
    fill(0, 50, 0); // Verde apagado
  }
  ellipse(200, 300, 120, 120);

  // Dibujar LED Rojo
  if (ledRojo) {
    fill(255, 0, 0); // Rojo
  } else {
    fill(50, 0, 0); // Rojo apagado
  }
  ellipse(400, 300, 120, 120);
  
  // Overlays según fase
  if (faseRegistro.equals("tarjeta")) {
    fill(0, 150);
    rect(0, 0, width, height);
    fill(255);
    rect(width/2 - 200, height/2 - 150, 400, 300, 20);
    fill(0);
    textAlign(CENTER);
    text("MODO REGISTRO\nACERQUE LA TARJETA...", width/2, height/2);
  }

  if (faseRegistro.equals("nombre")) {
    fill(0, 150);
    rect(0, 0, width, height);
    fill(255);
    rect(width/2 - 200, height/2 - 150, 420, 300, 20);
    fill(0);
    textAlign(CENTER);
    text("INGRESE NOMBRE Y PRESIONE ENTER", width/2, height/2 - 40);
    nombreField.setVisible(true);
    nombreField.setFocus(true);
  } else {
    nombreField.setVisible(false);
  }

  if (faseRegistro.equals("cargo")) {
    fill(0, 150);
    rect(0, 0, width, height);
    fill(255);
    rect(width/2 - 200, height/2 - 150, 420, 300, 20);
    fill(0);
    textAlign(CENTER);
    text("INGRESE CARGO Y PRESIONE ENTER", width/2, height/2 - 40);
    cargoField.setVisible(true);
    cargoField.setFocus(true);
  } else {
    cargoField.setVisible(false);
  }
  
  if (faseRegistro.equals("completado")) {
    // Fondo semi-transparente
    fill(0, 120);
    rect(0, 0, width, height);
  
    // Ventana central verde brillante
    fill(0, 200, 0, 180);
    rect(width/2 - 200, height/2 - 100, 400, 200, 20);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(28);
    text("REGISTRO COMPLETADO", width/2, height/2);
  
    // Opcional: cerrar overlay después de unos segundos
    if (millis() % 3000 < 50) { // cada 3 segundos
      faseRegistro = ""; // vuelve al estado normal
    }
  }
  
  // overlay para "eliminar"
  if (faseRegistro.equals("eliminar")) {
    fill(0, 150);
    rect(0, 0, width, height);
    fill(255);
    rect(width/2 - 150, height/2 - 100, 300, 200, 10);
    fill(0);
    textAlign(CENTER);
    text("MODO ELIMINAR\nACERQUE LA TARJETA...", width/2, height/2);
  }
  if (faseRegistro.equals("eliminada")) {
    // Fondo semi-transparente
    fill(0, 120);
    rect(0, 0, width, height);
    // Ventana central roja brillante
    fill(200, 0, 0, 180);
    rect(width/2 - 200, height/2 - 100, 400, 200, 20);
    // Texto centrado
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(28);
    text("TARJETA ELIMINADA", width/2, height/2);
    if (millis() % 3000 < 50) {
      faseRegistro = ""; // vuelve al estado normal
    }
  }
  
  if (faseRegistro.equals("listar")) {
    cp5.getController("Registrar").setVisible(false);
    cp5.getController("Eliminar").setVisible(false);
    cp5.getController("Listar").setVisible(false);

    fill(0, 120);
    rect(0, 0, width, height);
    fill(0, 0, 200, 180);
    rect(width/2 - 350, height/2 - 250, 700, 500, 20);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(26);
    text("LISTA DE TARJETAS REGISTRADAS", width/2, height/2 - 200);

    textSize(18);
    textAlign(LEFT, CENTER);
    int startX = width/2 - 320;
    int startY = height/2 - 150;
    fill(255);
    text("ID", startX, startY);
    text("NOMBRE", startX + 150, startY);
    text("CARGO", startX + 400, startY);

    stroke(255);
    line(startX, startY + 10, startX + 600, startY + 10);

    int y = startY + 40;
    Nodo actual = listaTarjetas.cabeza;
    while(actual != null){
      Tarjeta tarjeta=actual.tarjeta;    
      fill(255, 255, 255, 80);
      rect(startX - 10, y - 12, 620, 24, 5);
      fill(0);
      text(tarjeta.id, startX, y);
      text(tarjeta.nombre, startX + 150, y);
      text(tarjeta.cargo, startX + 400, y);
      y += 30;
    }

    if (millis() - tiempoOverlay > 4000) {
      faseRegistro = "";
      cp5.getController("Registrar").setVisible(true);
      cp5.getController("Eliminar").setVisible(true);
      cp5.getController("Listar").setVisible(true);
    }
  }
  
  // Overlay admin: ingresar contraseña tras pasar llave maestra
  if (faseRegistro.equals("admin_login")) {
    fill(0, 150);
    rect(0, 0, width, height);

    fill(255);
    rect(width/2 - 230, height/2 - 150, 460, 250, 20);
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(24);
    text("MODO ADMINISTRADOR", width/2, height/2 - 100);
    textSize(18);
    text("Ingrese contraseña y presione ENTER", width/2, height/2 - 60);

    passField.setVisible(true);
    passField.setFocus(true);
  }else{
    // Si no está el overlay, ocultamos el campo de contraseña
    passField.setVisible(false);
  }
}

public void CerrarSesion(){
  deshabilitarAdmin();
  guardarHistorial("Sesion de administrador cerrada");
  }

public void Registrar() {
  if (!adminHabilitado) { 
    println("Acción no disponible: admin no habilitado"); 
    return;
  }
  println("Registrar Tarjeta"); 
  myPort.write("1\n"); //mandamos 1 a arduino 
  faseRegistro="tarjeta"; 
}

public void Eliminar() {
  if (!adminHabilitado) { 
    println("Acción no disponible: admin no habilitado"); 
    return; 
  }
  println("Eliminar tarjeta"); 
  myPort.write("2\n"); //mandamos 2 
  faseRegistro="eliminar"; //mostramos overlay 
}

public void Listar() {
  if (!adminHabilitado) { 
    println("Acción no disponible: admin no habilitado"); 
    return; 
  }
  println("Listar tarjetas (desde Archivo)"); 
  faseRegistro = "listar";
  tiempoOverlay = millis();
  cp5.getController("Registrar").setVisible(false);
  cp5.getController("Eliminar").setVisible(false);
  cp5.getController("Listar").setVisible(false);
}

void serialEvent(Serial myPort) {
  String mensaje = myPort.readStringUntil('\n'); // lee lo que manda arduino hasta salto de linea
  if (mensaje != null) { 
    inputString = trim(mensaje); // guarda en la variable global 
    println("Arduino dice: "+ inputString); 
  
    String[] parts=split(inputString, ':'); //Divide el mensaje en Partes usando : como separador
    
    if(parts[0].equals("UID")){
      String id = mensaje.substring(4).trim();
      ultimoID = id;
      
      //llave maestra;
      if(id.equalsIgnoreCase(llaveMaestraID)){
        ledVerde=false;
        ledRojo=false;
        ultimoEstado="Llave maestra detectada";
        ultimoNombre="ADMIN";
        ultimoCargo="Supervisor";
        // Mostramos overlay de login admin
        faseRegistro = "admin_login";
        // No enviamos 99 ni DENY aquí es un flujo de gestión
        return; // salimos para no seguir al flujo de acceso normal
      }
      
      //flujo normal de acceso
      Tarjeta tarjetaEncontrada = listaTarjetas.buscar(id);
      //verificamos acceso 
      if(tarjetaEncontrada != null){
        ledVerde = true;
        ledRojo = false;
        ultimoEstado = "Acceso Permitido";
        ultimoNombre = tarjetaEncontrada.nombre;
        ultimoCargo = tarjetaEncontrada.cargo;
        myPort.write("99\n"); 
        guardarHistorial("Acceso permitido a ID:" + ultimoID.trim() + " Nombre:" + ultimoNombre.trim());
      }else {
        ledRojo = true;
        ledVerde = false;
        ultimoEstado = "Acceso Denegado";
        ultimoNombre = "";
        ultimoCargo  = "";
        myPort.write("DENY\n");
      }
    }
    
    else if(parts[0].equals("DEL")){
      String idEliminar = mensaje.substring(4);
      println("Solicitud de eliminación recibida para ID: " + idEliminar);
      // Borrar del archivo
      listaTarjetas.eliminar(idEliminar);
      guardarTarjetasArchivo();
      cargarTarjetasArchivo();

      // Feedback visual
      ultimoID = idEliminar;
      ultimoNombre = "";
      ultimoCargo = "";
      ultimoEstado = "Tarjeta eliminada";
      ledVerde = false;
      ledRojo = false;
      guardarHistorial("Eliminación de tarjeta ID:" + ultimoID.trim());
        
      faseRegistro= "eliminada";
    }
    
    else if(parts[0].equals("OK")) {
      String[] partes=split(mensaje.substring(3), ':');
      ultimoID = partes[0].trim(); 
      if (partes.length >= 3) { 
        ultimoNombre = partes[1]; 
        ultimoCargo = partes[2]; 
      }
      println("OK recibido, ID:" + ultimoID);
      // Guardar en archivo (evita duplicados)
      listaTarjetas.eliminar(ultimoID);
      Tarjeta nuevaTarjeta = new Tarjeta(ultimoID, ultimoNombre, ultimoCargo);
      listaTarjetas.agregar(nuevaTarjeta);
      guardarTarjetasArchivo();
      cargarTarjetasArchivo();
      guardarHistorial("Registro de tarjeta ID:" + ultimoID.trim() + " Nombre:" + ultimoNombre.trim());
      
      //overlay de confirmacion
      faseRegistro="completado";
      
      //limpiamos campos de texto
      nombreField.clear();
      cargoField.clear();
      nombreField.setVisible(false);
      cargoField.setVisible(false);
      println("Registro Completado");
    }

    else if (parts[0].equals("NO")) { 
      ledRojo = true; 
      ledVerde = false;
      ultimoEstado = "Acceso Denegado"; 
      ultimoID = mensaje.substring(3);  
      ultimoNombre = "";   
      ultimoCargo = ""; 
    }
    
    else if(mensaje.startsWith("MODO REGISTRO")){ 
      faseRegistro="tarjeta"; //mostramos overlay 
    }else if(mensaje.startsWith("INGRESE EL NOMBRE")){ 
      faseRegistro="nombre"; 
    }else if(mensaje.startsWith("INGRESE EL CARGO")){ 
      faseRegistro="cargo"; 
    }
    
    else if(mensaje.startsWith("TIEMPO DE ESPERA AGOTADO") || mensaje.startsWith("ESTA TARJETA YA ESTA REGISTRADA") || mensaje.startsWith("NO SE PUEDEN AGREGAR MAS TARJETAS")){ 
      faseRegistro=""; //cerramos overlay 
      nombreField.clear(); 
      cargoField.clear();  
      nombreField.setVisible(false); 
      cargoField.setVisible(false); 
      println("Registro Cancelado/ERROR: "+ mensaje);
      ultimoEstado=mensaje;
    }
    
    else if(mensaje.startsWith("Acerque la tarjeta para eliminarla")){ 
      faseRegistro="eliminar";
    }
  }
}

void keyPressed() {
  if (faseRegistro.equals("nombre") && key == ENTER) {
    String nombre = nombreField.getText();
    if (nombre.length() > 0) {
      myPort.write(nombre + "\n");
      println("Nombre enviado: " + nombre);
      nombreField.clear();
    }
  }
  if (faseRegistro.equals("cargo") && key == ENTER) {
    String cargo = cargoField.getText();
    if (cargo.length() > 0) {
      myPort.write(cargo + "\n");
      println("Cargo enviado: " + cargo);
      cargoField.clear();
    }
  }
  // Confirmación de contraseña admin
  if (faseRegistro.equals("admin_login") && key == ENTER) {
    String pass = passField.getText().trim();
    if (pass.equals(adminPassword)) {
      habilitarAdmin();
      guardarHistorial("Administrador habilitado por llave maestra ID:" + ultimoID.trim());
    }else{
      ultimoEstado = "Contraseña incorrecta";
      println("Admin: contraseña incorrecta");
      // Podés dejar el overlay para reintentar o cerrar si querés
      faseRegistro = ""; // si querés cerrar en fallo
    }
  }
}

void cargarTarjetasArchivo() {
  String[] lineas = null;
  try {
    lineas = loadStrings("tarjetas.txt");
  } catch(Exception e) {
    println("No existe archivo de tarjetas, se inicia vacío.");
  }
  listaTarjetas = new ListaEnlazada();
  if (lineas != null) {
    for(String l : lineas) {
      String limpio = trim(l);
      if(limpio.length() > 0) {
        String[] partes = split(limpio, ';');
        if (partes.length == 3) {
          String id = partes[0].replace("ID:", "").trim();
          String nombre = partes[1].replace("NOMBRE:", "").trim();
          String cargo = partes[2].replace("CARGO:", "").trim();
          listaTarjetas.agregar(new Tarjeta(id, nombre, cargo));
        }
      }
    }
  }
  println("Cargadas " + listaTarjetas.getTamaño() + " tarjetas desde archivo.");
}

void guardarTarjetasArchivo() {
  ArrayList<String> lineas = listaTarjetas.getTarjetasComoStrings();
  String[] lineasArray = new String[lineas.size()];
  for(int i = 0; i < lineas.size(); i++) {
    lineasArray[i] = lineas.get(i);
  }
  saveStrings("tarjetas.txt", lineasArray);
  println("Tarjetas guardadas en archivo. Total: " + lineasArray.length);
}

void eliminarPorIDArchivo(String id) {
  listaTarjetas.eliminar(id);
}

void guardarHistorial(String evento) {
  // Armamos fecha y hora actuales de la PC
  String fechaHora = nf(day(),2) + "/" + nf(month(),2) + "/" + year() + " " +
                     nf(hour(),2) + ":" + nf(minute(),2) + ":" + nf(second(),2);

  String linea = fechaHora + " - " + evento;

  // Leemos el historial existente
  String[] viejo = null;
  try {
    viejo = loadStrings("historial.txt");
  } catch(Exception e) {
    // si no existe, arranca vacío
  }

  // Creamos un nuevo array con lo viejo + la nueva línea
  ArrayList<String> nuevo = new ArrayList<String>();
  if (viejo != null) {
    for (String l : viejo) {
      nuevo.add(l);
    }
  }
  nuevo.add(linea);

  // Guardamos todo junto
  saveStrings("historial.txt", nuevo.toArray(new String[nuevo.size()]));
}

void habilitarAdmin() {
  adminHabilitado = true;
  // Mostrar botones de administración
  cp5.getController("Registrar").setVisible(true);
  cp5.getController("Eliminar").setVisible(true);
  cp5.getController("Listar").setVisible(true);
  // Mostrar botón cerrar sesión
  btnCerrarSesion.setVisible(true);
  // Ocultar overlay y campo de contraseña
  faseRegistro = "";
  passField.clear();
  passField.setVisible(false);
  ultimoEstado = "Administrador habilitado";
}

void deshabilitarAdmin() {
  adminHabilitado = false;
  // Ocultar botones de administración
  cp5.getController("Registrar").setVisible(false);
  cp5.getController("Eliminar").setVisible(false);
  cp5.getController("Listar").setVisible(false);
  // Ocultar botón cerrar sesión y limpiar
  btnCerrarSesion.setVisible(false);
  passField.clear();
  passField.setVisible(false);
  faseRegistro = "";
  ultimoEstado = "Sesión cerrada";
}
