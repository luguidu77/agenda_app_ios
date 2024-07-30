import 'dart:io';

import 'package:agendacitas/models/cita_model.dart';
import 'package:agendacitas/screens/nuevo_actualizacion_cliente.dart';
import 'package:agendacitas/screens/style/estilo_pantalla.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeletons/skeletons.dart';

import '../models/personaliza_model.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';

class FichaClienteScreen extends StatefulWidget {
  final ClienteModel clienteParametro;
  const FichaClienteScreen({Key? key, required this.clienteParametro})
      : super(key: key);

  @override
  State<FichaClienteScreen> createState() => _FichaClienteScreenState();
}

class _FichaClienteScreenState extends State<FichaClienteScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> _citas = [];
  PagoProvider? data;
  bool pagado = false;
  String _emailSesionUsuario = '';
  bool _iniciadaSesionUsuario = false;
  XFile? _image;
  PersonalizaModel personaliza = PersonalizaModel();

  List<bool> isSelected = [true, false];
  TabController? tabController;

  bool floatExtended = false;

  getPersonaliza() async {
    List<PersonalizaModel> data =
        await PersonalizaProvider().cargarPersonaliza();

    if (data.isNotEmpty) {
      personaliza.codpais = data[0].codpais;
      personaliza.moneda = data[0].moneda;

      setState(() {});
    }
  }

  compruebaPago() async {
    final estadoPagoProvider = context.read<EstadoPagoAppProvider>();
    _emailSesionUsuario = estadoPagoProvider.emailUsuarioApp;
    _iniciadaSesionUsuario = estadoPagoProvider.iniciadaSesionUsuario;
    debugPrint(
        'datos gardados en tabla Pago (fichaClienteScreen.dart) PAGO: $pagado // EMAIL:$_emailSesionUsuario ');
  }

  @override
  void initState() {
    getPersonaliza();
    compruebaPago();
    tabController = TabController(length: 2, vsync: this);

    super.initState();

    // ANIMACION FLOATINGBUTTON
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        floatExtended = true;

        // Here you can write your code for open new view
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    tabController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //FOTO CLIENTE
    String foto = widget.clienteParametro.foto!;
    print("foto de la cliente $foto");

    Color colorTema = Theme.of(context).primaryColor;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        label: const Text(
          'EDITAR',
        ),
        isExtended: floatExtended,
        icon: const Icon(Icons.edit),
        onPressed: () async {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NuevoActualizacionCliente(
                cliente: widget.clienteParametro,
                pagado: pagado,
                usuarioAPP: _emailSesionUsuario,
              ),
            ),
          );
        },
      ),
      body: DefaultTabController(
        length: 2,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  //  Navigator.pushNamed(context, 'clientesScreen'),
                  icon: const Icon(Icons.arrow_back)),
              //  actions: [iconoModificar()],
              elevation: 0.0,
              pinned: true,
              // backgroundColor: Colors.deepPurple,
              expandedHeight: 250,
              //imagenes guardada en Storage Firebase
              //https://medium.flutterdevs.com/firebase-storage-in-flutter-1f06742472b1
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                expandedTitleScale: 1.5,
                background: _iniciadaSesionUsuario &&
                        widget.clienteParametro.foto! != ''
                    ? SizedBox(
                        child: Image.network(
                        widget.clienteParametro.foto!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ))
                    : Image.asset(
                        "./assets/images/nofoto.jpg",
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            SliverAppBar(
                toolbarHeight: 80,
                forceMaterialTransparency: true,
                automaticallyImplyLeading: false,
                pinned: true,
                primary: false,
                elevation: 0.0,
                title: Align(
                  alignment: AlignmentDirectional.center,
                  child: ToggleButtons(
                    color: Colors.black.withOpacity(0.60),
                    selectedColor: colorTema,
                    selectedBorderColor: colorTema,
                    fillColor: colorTema.withOpacity(0.08),
                    splashColor: colorTema.withOpacity(0.12),
                    hoverColor: colorTema.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(4.0),
                    isSelected: isSelected,
                    onPressed: (i) {
                      // Respond to button selection
                      setState(() {
                        switch (i) {
                          case 0:
                            isSelected = [true, false];
                            tabController!.index = 0;

                          case 1:
                            isSelected = [false, true];
                            tabController!.index = 1;
                          default:
                        }

                        // isSelected[index] = !isSelected[index];
                      });
                    },
                    children: const [
                      Icon(Icons.person),
                      Icon(Icons.calendar_month),
                      // Icon(Icons.notifications),
                    ],
                  ),
                )),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 800,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TabBarView(
                      controller: tabController,
                      // physics: ScrollPhysics(),
                      children: [
                        _datos(
                          colorTema,
                          widget.clienteParametro,
                          pagado,
                        ),
                        _historial(
                          context,
                          _citas,
                          widget.clienteParametro.id,
                        ),
                      ]),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future getImage(myLogic) async {
    try {
      var image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 50,
          maxHeight: 600,
          maxWidth: 900);

      setState(() {
        _image = image;

        print('Image Path ${_image!.path}');
      });

      _subirImagenStorage(_image!.path, myLogic);
    } catch (e) {
      print('Error de imagen $e');
    }
  }

//https://medium.com/unitechie/how-to-upload-files-to-firebase-storage-in-flutter-873fd764a39b
  void _subirImagenStorage(image, myLogic) async {
    try {
      //1º INICIALIZAR
      await Firebase.initializeApp();
      var storage = FirebaseStorage.instance;
      //2º FILE LLEVA LA RUTA DE LA FOTO EN EL DISPOSITIVO
      final file = File(image);

      //3º SUBIR FOTO AL STORAGE
      //TASKSHAPSHOT ES PARA USAR EN POSTERIOR CONSULTA AL STORAGE
      //TaskSnapshot taskSnapshot =
      await storage
          // GUARDO LAS FOTO DE FICHA CLIENTE EN LA SIGUIENTE DIRECCION DEL STORAGE FIREBASE
          .ref('agendadecitas/clientes/$_emailSesionUsuario/foto')
          .putFile(file);
      // CONSULTA DE LA URL EN STORAGE
      // final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      print(e);
    }
  }

  _datos(colorTema, ClienteModel cliente, bool pagado) {
    return Column(
      children: [
        SizedBox(
          height: 350,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 00.0),
                child: Text(
                  '${cliente.nombre}',
                  style: subTituloEstilo,
                ),
              ),
              const SizedBox(width: 16), // Espacio entre las columnas

              Padding(
                padding: const EdgeInsets.only(top: 50.0, left: 10),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => Comunicaciones.hacerLlamadaTelefonica(
                          cliente.telefono.toString()),
                      child: Row(
                        children: [
                          Icon(Icons.phone,
                              color: colorTema), // Icono de teléfono
                          const SizedBox(
                              width: 8), // Espacio entre el icono y el texto
                          Text(
                            '${cliente.telefono}',
                            style: subTituloEstilo,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    GestureDetector(
                      onTap: () =>
                          Comunicaciones.enviarEmail(cliente.email.toString()),
                      child: Row(
                        children: [
                          Icon(Icons.email,
                              color: colorTema), // Icono de correo electrónico
                          const SizedBox(
                              width: 8), // Espacio entre el icono y el texto
                          Text(
                            cliente.email == '' ? 'Email' : cliente.email!,
                            style: subTituloEstilo,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Wrap(
                      children: [
                        Icon(Icons.notes, color: colorTema), // Icono de notas
                        const SizedBox(
                            width: 8), // Espacio entre el icono y el texto
                        Text(
                          cliente.nota == '' || cliente.nota == 'null'
                              ? 'Notas'
                              : cliente.nota!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: textoEstilo,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 100,
        )
      ],
    );
  }

  _historial(context, List<Map<String, dynamic>> citas, String idCliente) {
    return FutureBuilder<dynamic>(
        future: _iniciadaSesionUsuario
            ? FirebaseProvider()
                .cargarCitasPorCliente(_emailSesionUsuario, idCliente)
            : CitaListProvider().cargarCitasPorCliente(int.parse(idCliente)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SkeletonParagraph(
              style: SkeletonParagraphStyle(
                  lines: 5,
                  spacing: 6,
                  lineStyle: SkeletonLineStyle(
                    // randomLength: true,
                    height: 80,
                    borderRadius: BorderRadius.circular(5),
                    // minLength: MediaQuery.of(context).size.width,
                    // maxLength: MediaQuery.of(context).size.width,
                  )),
            );
          } else if (snapshot.connectionState == ConnectionState.active ||
              snapshot.connectionState == ConnectionState.done) {
            //#### SNAPSHOT TRAE LAS CITAS, LAS CUALES LAS PASO POR ORDEN DE FECHAS A LA VARIABLE  citas
            List citas = listaCitasOrdenadasPorFecha(snapshot.data);

            if (snapshot.hasError) {
              return const Text('Error');

              //###################    SI HAY DATOS Y LA CITAS NO ESTA VACIA ###########################
            } else if (snapshot.hasData && citas.isNotEmpty) {
              return Flexible(
                child: Column(
                  children: [
                    SizedBox(
                      // tarjeta con numero de citas concertadas

                      child: Text('${citas.length} citas concertadas ',
                          style: subTituloEstilo),
                    ),
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 350,
                            child: ListView.builder(
                              itemCount: citas.length,
                              itemBuilder: (context, index) {
                                print(
                                    '55555555555555555555555555555555555555555555555555555555555555555555');
                                print(citas[index]);
                                return Card(
                                  color: (DateTime.now().isBefore(
                                          DateTime.parse(citas[index]['dia'])))
                                      ? const Color.fromARGB(255, 245, 197, 194)
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Row(
                                          children: [
                                            //? FECHA LARGA EN ESPAÑOL

                                            Text(DateFormat.MMMMEEEEd('es_ES')
                                                .format(DateTime.parse(
                                                    citas[index]['dia']
                                                        .toString()))),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(citas[index]['servicio']
                                                /*  .toString()
                                                .toUpperCase() */
                                                ),
                                            Text(
                                                '${citas[index]['precio'].toString()} ${personaliza.moneda}'),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(
                            height: 50,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Column(
                children: [
                  const SizedBox(
                    height: 50,
                  ),
                  const Text('No tienes citas para este cliente'),
                  const SizedBox(
                    height: 50,
                  ),
                  Image.asset(
                    'assets/images/caja-vacia.png',
                    width: MediaQuery.of(context).size.width - 250,
                  ),
                ],
              );
            }
          } else {
            return Text('State: ${snapshot.connectionState}');
          }
        });
  }

  List listaCitasOrdenadasPorFecha(List<dynamic> citas) {
    citas.sort((b, a) {
      //sorting in ascending order
      return DateTime.parse(a['dia']).compareTo(DateTime.parse(b['dia']));
    });

    return citas;
  }
}

Widget nivelCliente(iniciadaSesionUsuario, usuarioAPP, cliente) {
  return FutureBuilder<dynamic>(
      future: iniciadaSesionUsuario
          ? FirebaseProvider().cargarCitasPorCliente(usuarioAPP!, cliente.id)
          : CitaListProvider().cargarCitasPorCliente(cliente.id),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SkeletonParagraph(
            style: SkeletonParagraphStyle(
                lines: 1,
                spacing: 6,
                lineStyle: SkeletonLineStyle(
                  height: 40,
                  borderRadius: BorderRadius.circular(5),
                )),
          );
        } else if (snapshot.connectionState == ConnectionState.active ||
            snapshot.connectionState == ConnectionState.done) {
          List citas = snapshot.data;

          if (snapshot.hasError) {
            return const Text('Error');
          } else if (snapshot.hasData && citas.isNotEmpty) {
            return ClipRect(
              child: // si la clienta tiene mas de una cita ya no es nueva clienta
                  Banner(
                color: const Color.fromARGB(255, 217, 235, 153),
                message: 'NIVEL', // todo: SERA NUEVO,  VIP...
                //color: , // todo: CAMBIA SEGUN MESSAGE...
                location: BannerLocation.topEnd,
                child: SizedBox(
                  //decoration: decorationTarjetaNombre,
                  width: double.infinity,
                  height: 60,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [Image.asset('assets/icon/favorito.png')],
                    ),
                  ),
                ),
              ),
            );
          } else {
            return const Text('Empty data');
          }
        } else {
          return Text('State: ${snapshot.connectionState}');
        }
      });
}
