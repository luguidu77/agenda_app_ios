import 'dart:convert';

import 'package:agendacitas/providers/Firebase/notificaciones.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/notificacion_model.dart';
import '../providers/providers.dart';
import '../widgets/botones/boton_ledido.dart';

class PaginaNotificacionesScreen extends StatefulWidget {
  const PaginaNotificacionesScreen({super.key});

  @override
  State<PaginaNotificacionesScreen> createState() =>
      _PaginaNotificacionesScreenState();
}

class _PaginaNotificacionesScreenState
    extends State<PaginaNotificacionesScreen> {
  late String _emailSesionUsuario;

  inicializacion() async {
    final estadoPagoProvider = context.read<EstadoPagoAppProvider>();
    _emailSesionUsuario = estadoPagoProvider.emailUsuarioApp;
  }

  @override
  void initState() {
    inicializacion();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Container(),
          title: const Text('BUZÓN DE NOTIFICACIONES'),
          centerTitle: true,
          titleTextStyle: const TextStyle(fontSize: 13, color: Colors.black),
        ),
        body: FutureBuilder(
          future: getTodasLasNotificacionesCitas(_emailSesionUsuario),
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else if (snapshot.hasData) {
              // Aquí puedes construir la lista de ListTiles con los datos obtenidos

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                            icon: const Icon(
                              Icons.delete_forever_outlined,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _eliminaLedidas(_emailSesionUsuario),
                            label: const Text('Borrar leídas')),
                      ],
                    ),
                  ),
                  const Divider(),
                  (snapshot.data.length < 1)
                      ? Padding(
                          padding: const EdgeInsets.only(top: 58.0),
                          child: SizedBox(
                              height: 200,
                              width: 200,
                              child:
                                  Image.asset('assets/images/caja-vacia.png')),
                        )
                      : Expanded(
                          child: ListView.separated(
                            itemCount: snapshot.data!.length,
                            separatorBuilder: (context, index) =>
                                const Divider(), // Separador entre grupos de notificaciones
                            itemBuilder: (context, index) {
                              final notificacion = snapshot.data![index];

                              final notificacionModelo = NotificacionModel(
                                  id: notificacion['id'],
                                  fechaNotificacion:
                                      notificacion['fechaNotificacion'],
                                  iconoCategoria: notificacion['categoria'],
                                  visto: notificacion['visto'],
                                  data: notificacion['data']);

                              String fechaNotificacion = _formateaFecha(
                                  notificacionModelo.fechaNotificacion);

                              String fechacita = '';
                              String horacita = '';
                              String nombreCliente = '';
                              String telefonoCliente = '';
                              String emailCliente = '';

                              if (notificacion['categoria'] == 'citaweb') {
                                Map<String, dynamic> data =
                                    jsonDecode(notificacionModelo.data);
                                final (:nombre, :telefono, :email) =
                                    _obtieneCliente(data);
                                final (:fecha, :hora) = _obtieneCita(data);

                                fechacita = fecha;
                                horacita = hora;
                                nombreCliente = nombre;
                                telefonoCliente = telefono;
                                emailCliente = email;
                              }

                              // Tarjeta de notificación
                              return dialogoDescripcionNotificacion(
                                  context,
                                  fechaNotificacion,
                                  notificacion,
                                  fechacita,
                                  horacita,
                                  nombreCliente,
                                  telefonoCliente,
                                  _emailSesionUsuario,
                                  emailCliente,
                                  notificacionModelo.data);
                            },
                          ),
                        ),
                ],
              );
            } else {
              // Si no hay datos, puedes mostrar un mensaje indicando que no hay notificaciones
              return const Center(
                child: Text('No hay notificaciones disponibles'),
              );
            }
          },
        ));
  }

  GestureDetector dialogoDescripcionNotificacion(
      BuildContext context,
      String fechaNotificacion,
      notificacion,
      String fechacita,
      String horacita,
      String nombreCliente,
      String telefonoCliente,
      String emailSesionUsuario,
      String emailCliente,
      data) {
    return GestureDetector(
      onTap: () async {
        // setState(() {});
        // Cambiar estado en Firebase

        print(emailSesionUsuario);
        print(notificacion['id']);
        // final categoria = _obtieneTextoCategoria(notificacion['categoria'], 12);
        await showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (BuildContext context) {
            return Container(
              height: 300,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    height: 35,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(fechaNotificacion),
                      const SizedBox(
                        width: 50,
                      ),
                      _obtieneIcono(notificacion['categoria']),
                      const SizedBox(
                        width: 5,
                      ),
                      _obtieneTextoCategoria(notificacion['categoria'], 12),
                    ],
                  ),
                  const SizedBox(
                    height: 35,
                  ),
                  notificacion['categoria'] == 'cita' ||
                          notificacion['categoria'] == 'citaweb'
                      //* NOTIFICACIONES CITAS ****************************
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                // mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('FECHA: '),
                                  Text(fechacita),
                                ],
                              ),
                              Row(
                                //  mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('HORA: '),
                                  Text(horacita),
                                ],
                              ),
                              Text(nombreCliente),
                              Text(telefonoCliente),
                              Text(emailCliente),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('SERVICIO: '),
                                  Text(''),
                                ],
                              ),
                            ],
                          ),
                        )
                      //** NOTIFICACIONES FIREBASE MESSAGING ******************/
                      : Container(
                          child: Text(data),
                        ),

                  Container(),
                  /*  MenuConfigCliente(
                                            cliente: listaClientes[index]), */

                  //_opciones(context, cliente)
                ],
              ),
            );
          },
        ).then((value) async {
          await FirebaseProvider().cambiarEstadoVisto(
              emailSesionUsuario, notificacion['id'], false);

          setState(() {
           });
        });
      },
      child: _tarjetasNotificaciones(_emailSesionUsuario, fechaNotificacion,
          notificacion, fechacita, horacita, nombreCliente, telefonoCliente),
    );
  }

  String categoriaNotificacion = '';
  // *** tarjetas de las notificaciones ***************************************
  Widget _tarjetasNotificaciones(
      emailSesionUsuario,
      String fechaNotificacion,
      Map<String, dynamic> notificacion,
      String fecha,
      String hora,
      String nombre,
      String telefono) {
    //** diferenciar segun CATEGORIA de la notificacion********************************** */
    // citaweb, administrador

    switch (notificacion['categoria']) {
      case 'citaweb':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(
              onPressed: () async {}, // Aquí puedes agregar la acción deseada
              child: Text(fechaNotificacion),
            ),
            ListTile(
              // Contenido de la tarjeta de notificación
              leading: Column(
                children: [
                  _obtieneIcono(notificacion['categoria']),
                  _obtieneTextoCategoria(notificacion['categoria'], 8)
                ],
              ),
              title: Text(nombre),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$fecha-$hora"),
                  Text('Teléfono: $telefono'),
                ],
              ),
              trailing: BotonLedido(
                  notificacion: notificacion,
                  emailSesionUsuario: emailSesionUsuario),
            ),
          ],
        );

      case 'administrador':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(
              onPressed: () {}, // Aquí puedes agregar la acción deseada
              child: Text(fechaNotificacion),
            ),
            ListTile(
              // Contenido de la tarjeta de notificación
              leading: Column(
                children: [
                  _obtieneIcono(notificacion['categoria']),
                  _obtieneTextoCategoria(notificacion['categoria'], 8)
                ],
              ),
              title: const Text('AGENDA DE CITAS'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${notificacion['data']}"),
                  //  Text('Teléfono: $telefono'),
                ],
              ),
              trailing: BotonLedido(
                  notificacion: notificacion,
                  emailSesionUsuario: emailSesionUsuario),
            ),
          ],
        );
    }

    return Container();
  }

  // ***************************************************************************

  String _formateaFecha(Timestamp fechaNotificacion) {
    Timestamp timestamp = fechaNotificacion;

    // Convertir el Timestamp a DateTime
    DateTime dateTime = timestamp.toDate();

    // Formatear el DateTime según el formato deseado
    String fechaFormateada = DateFormat('dd/MM/yy HH:mm').format(dateTime);
    print("Fecha formateada: $fechaFormateada");
    return fechaFormateada;
  }

  _eliminaLedidas(emailSesionUsuario) async {
    await eliminaLeidas(emailSesionUsuario);
    setState(() {});
  }
}

Icon _obtieneIcono(String categoria) {
  return switch (categoria) {
    'cita' => const Icon(Icons.offline_share_outlined),
    'citaweb' => const Icon(Icons.cloud_done),
    'administrador' => const Icon(Icons.admin_panel_settings_sharp),
    _ => const Icon(Icons.data_array_rounded),
  };
}

Text _obtieneTextoCategoria(String categoria, double size) {
  return switch (categoria) {
    'cita' => Text('CITA', style: TextStyle(fontSize: size)),
    'citaweb' => Text('CITA', style: TextStyle(fontSize: size)),
    'administrador' => Text('ADMIN', style: TextStyle(fontSize: size)),
    _ => Text('N/A', style: TextStyle(fontSize: size)),
  };
}

({String fecha, String hora}) _obtieneCita(data) {
  String fechaCita = data['fechaCita']['fechaFormateada'];
  String horaCita = data['fechaCita']['horaFormateada'];

  return (fecha: fechaCita, hora: horaCita);
}

({String nombre, String telefono, String email}) _obtieneCliente(data) {
  String nombreCliente = data['cliente']['nombre'];
  String telefonoCliente = data['cliente']['telefono'];
  String emailCliente = data['cliente']['email'];

  return (
    nombre: nombreCliente,
    telefono: telefonoCliente,
    email: emailCliente
  );
}
