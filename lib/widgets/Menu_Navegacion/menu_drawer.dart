import 'package:agendacitas/models/perfil_model.dart';
import 'package:agendacitas/providers/Firebase/firebase_provider.dart';
import 'package:agendacitas/config/config_personalizar_screen.dart';
import 'package:agendacitas/screens/creacion_citas/servicios_creacion_cita.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/pago_dispositivo_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agendacitas/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({
    Key? key,
  }) : super(key: key);

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  String usuarioAPP = '';
  TextStyle estilo = const TextStyle(color: Colors.blueGrey);
  bool _haySesionIniciada = false;
  String versionApp = '';
  bool versionPlayS = false;
  String? comentarioVersion;
  bool enviosugerencia = false;
  bool necesitaActualizar = false;

  version() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    versionApp = packageInfo.version;

    double verApp = double.parse(versionApp);

//? COMPRUEBA VERSION EN FIREBASE(PLAYSTORE)

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    final db = FirebaseFirestore.instance;

// creo una referencia al documento que contiene la version
    final docRefVersion =
        db.collection("versionPlayStore").doc("Izdf1IB8WIfq3s8GbYuK");

    var data = await docRefVersion.get().then(
          (doc) => doc.data(),
        );

    versionPlayS = data!['version'];
    comentarioVersion = data['comentario'];

    debugPrint(
        'La version de la app en PlaStore es: ${versionPlayS.toString()}');
    debugPrint('comentario de version: ${comentarioVersion.toString()}');

    debugPrint('La version de la app instalada es: ${verApp.toString()}');

//? COMPARO VERSION EN FIREBASE(PLAYSTORE) CON LA INSTALADA EN EL MOVIL
    if (versionPlayS) {
      necesitaActualizar = true;
    }

    setState(() {});
  }

  emailUsuario() async {
    //traigo email del usuario, del PagoProvider

    final providerPagoUsuarioAPP =
        Provider.of<PagoProvider>(context, listen: false);
    usuarioAPP = providerPagoUsuarioAPP.pagado['email'];
  }

  @override
  void initState() {
    // leerBasedatos();
    emailUsuario();
    version();

    super.initState();
  }

  _fotoPerfil() {
    try {
      return StreamBuilder(
          stream: FirebaseProvider().cargarPerfilFB(usuarioAPP).asStream(),
          builder: ((context, AsyncSnapshot<PerfilModel> snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data;
              return CircleAvatar(
                backgroundColor: Colors.transparent,
                child: data!.foto != ''
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(100.0),
                        child: FadeInImage.assetNetwork(
                            placeholder: './assets/icon/galeria-de-fotos.gif',
                            image: data.foto.toString(),
                            fit: BoxFit.cover,
                            width: 100),
                      )
                    : Image.asset('./assets/icon/icon.png'),
              );

              /*  return CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Image.asset('./assets/icon/icon.png'),
          ); */
            }
            return const CircleAvatar();
          }));
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    //comprueba pago de la app
    final estadopago = Provider.of<PagoProvider>(context);
    bool iniSesion = estadopago.pagado['email'] != '' ? true : false;
    _haySesionIniciada = iniSesion; // estadopago.pagado['pago'];
    setState(() {});
    return Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          _haySesionIniciada
              ? UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                      color: Theme.of(context)
                          .primaryColor), // Color.fromARGB(255, 122, 121, 197)),
                  currentAccountPicture: _fotoPerfil(),
                  accountEmail: Row(
                    children: [
                      IconButton(
                          color: Colors.white,
                          icon: const Icon(Icons.settings),
                          onPressed: () => {
                                Navigator.pushNamed(context, 'ConfigUsuarioApp')
                              }),
                      Text(usuarioAPP),
                    ],
                  ),
                  accountName: const Text(''))
              : DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  //  image: DecorationImage(image: AssetImage('assets/icon/icon.png'))),
                  child: Center(
                      child: SingleChildScrollView(
                    child: Column(children: [
                      const Image(
                        image: AssetImage('assets/icon/icon.png'),
                        width: 100,
                      ),
                      Text('Agenda de citas', style: estilo),
                      _haySesionIniciada
                          ? Text('PRO $versionApp', style: estilo)
                          : Text('versión gratuita $versionApp', style: estilo),
                    ]),
                  ))),
          const Divider(),

          !_haySesionIniciada
              ? ListTile(
                  textColor: Colors.red,
                  leading: const Icon(Icons.update),
                  title: Column(
                    children: [
                      // const Text('Actualización disponible en PlayStore'),
                      Text(
                        comentarioVersion.toString(),
                        style: const TextStyle(fontSize: 12),
                      )
                    ],
                  ),
                  // link a play store
                  onTap: () {})
              : Container(),
          /* _haySesionIniciada // ?: INICIO DE SESION PARA ACCEDER A LA CUENTA DE USUARIO EN UN NUEVO DISPOSITIVO
              ? const Text('')
              : ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('INICIA SESION'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RegistroUsuarioScreen(
                                registroLogin: 'Login', usuarioAPP: '',
                              ))),
                ), */

          ListTile(
            leading: const Icon(Icons.home_repair_service_outlined),
            title: Text('Tus servicios', style: estilo),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServiciosCreacionCita(),
                  ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(
              'Configuración',
              style: estilo,
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConfigPersonalizar(),
                  ));
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(
              'Tu opinión nos importa',
              style: estilo,
            ),
            onTap: () {
              _sendMail('Tengo sugerencias para Agenda de Citas: ');
            },
          ),
          /*  _haySesionIniciada
              ? const Text('')
              : ListTile(
                  leading: const Icon(Icons.monetization_on),
                  title: Text(
                    'Quitar anuncios y más',
                    style: estilo,
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, 'TarjetaPago');
                    //  _quitarPublicidad(context, enviosugerencia);
                  },
                ), */
          _haySesionIniciada
              ? const Text('')
              : ListTile(
                  leading: const Icon(Icons.face_retouching_natural),
                  title: Text(
                    ' Plan amigo 🎁',
                    style: estilo,
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, 'PlanAmigo');
                    //  _quitarPublicidad(context, enviosugerencia);
                  },
                ),
          //Navigator.pushNamed(context, 'PlanAmigo'),
        ],
      ),
    );
  }
}

_sendMail(String subject) async {
  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: 'agendadecitaspro@gmail.com',
    query: encodeQueryParameters(<String, String>{
      'subject': subject,
    }),
  );

  await launchUrl(emailLaunchUri);
}
