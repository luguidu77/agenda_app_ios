import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cita_model.dart';
import '../mylogic_formularios/mylogic.dart';
import '../providers/providers.dart';
import '../screens/screens.dart';
import '../utils/utils.dart';

class ConfigCategoriaServiciosScreen extends StatefulWidget {
  const ConfigCategoriaServiciosScreen({Key? key}) : super(key: key);

  @override
  State<ConfigCategoriaServiciosScreen> createState() =>
      _ConfigCategoriaServiciosScreenState();
}

class _ConfigCategoriaServiciosScreenState
    extends State<ConfigCategoriaServiciosScreen> {
  String? _emailSesionUsuario;
  bool _iniciadaSesionUsuario = false;
  String textoErrorValidacionAsunto = '';
  final _formKey = GlobalKey<FormState>();
  CategoriaServicioModel categoria =
      CategoriaServicioModel(nombreCategoria: '', detalle: '');

  late MyLogicCategoriaServicio myLogic;

  List<CategoriaServicioModel> listaAux = [];
  List<CategoriaServicioModel> listaCategoriaServicios = [];
  List<String> listNombreCategoriaServicios = [];
  List<String> listIdCategoriaServicios = [];
  String dropdownValue = '';
  emailUsuario() async {
    //traigo email del usuario, para si es de pago, pasarlo como parametro al sincronizar
    final estadoPagoProvider = context.read<EstadoPagoAppProvider>();
    _emailSesionUsuario = estadoPagoProvider.emailUsuarioApp;
    _iniciadaSesionUsuario = estadoPagoProvider.iniciadaSesionUsuario;

    await cargarDatosCategorias();

    //DATA TRAIDA POR NAVIGATOR PUSHNAMED (ARGUMENTS)

    dataFB =
        ModalRoute.of(context)!.settings.arguments as CategoriaServicioModel;
    agregaModificaFB = (dataFB.nombreCategoria == null) ? true : false;
    if (!agregaModificaFB) {
      myLogic = MyLogicCategoriaServicio(dataFB);
      myLogic.init();
    }
  }

  @override
  void initState() {
    super.initState();
    emailUsuario();
    myLogic = MyLogicCategoriaServicio(categoria);
    myLogic.init();
  }

  bool agregaModificaFB = false;

  var dataFB;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                (agregaModificaFB)
                    ? agregaCategoria(_emailSesionUsuario!)
                    : modificarCategoria(_emailSesionUsuario!,
                        dataFB); // METODO MODIFICAR SERVICIO

                setState(() {});
              }
            },
            child: const Icon(Icons.save),
          ),
          body: _formularioFB(context, agregaModificaFB)),
    );
  }

  _formularioFB(context, agregaModificaFB) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          _botonCerrar(),
          const SizedBox(height: 10),
          _formulario(agregaModificaFB),
          const SizedBox(height: 20),
          const Text('Categorias disponibles'),
          const SizedBox(height: 10),
          _listaCategorias()
        ],
      ),
    );
  }

  Form _formulario(agregaModificaFB) {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              (agregaModificaFB) ? "Agregar categoría " : 'Editar categoría',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(
              height: 50,
            ),
            TextFormField(
              validator: (value) => _validacion(value),
              controller: myLogic.textControllerNombreCategoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            TextFormField(
              validator: (value) => _validacion(value),
              controller: myLogic.textControllerDetalle,
              decoration: const InputDecoration(labelText: 'Detalle'),
            ),
          ],
        ));
  }

  agregaCategoria(String usuarioAPP) async {
    final categoria = myLogic.textControllerNombreCategoria.text;
    final detalle = myLogic.textControllerDetalle.text;

    await FirebaseProvider()
        .nuevaCategoriaServicio(usuarioAPP, categoria, detalle);
    mensaje('Categoria agregada');

    myLogic.textControllerNombreCategoria.clear();
    myLogic.textControllerDetalle.clear();

    // Navigator.pushReplacementNamed(context, 'Servicios');
  }

  modificarCategoria(String usuarioAPP, CategoriaServicioModel categoria) {
    CategoriaServicioModel auxCategoria = CategoriaServicioModel();
    auxCategoria.id = categoria.id;
    auxCategoria.nombreCategoria = myLogic.textControllerNombreCategoria.text;
    auxCategoria.detalle = myLogic.textControllerDetalle.text;

    FirebaseProvider().actualizarCategoriaServicioFB(usuarioAPP, auxCategoria);
    mensaje('Categoria modificada');
    //Navigator.pushReplacementNamed(context, 'Servicios');
  }

  _botonCerrar() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(
            width: 50,
          ),
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServiciosCreacionCita(),
                    ));
              },
              icon: const Icon(
                Icons.close,
                size: 50,
                color: Color.fromARGB(167, 114, 136, 150),
              )),
        ],
      ),
    );
  }

  _validacion(value) {
    debugPrint(value.isEmpty.toString());
    if (value.isEmpty) {
      textoErrorValidacionAsunto = 'Este campo no puede quedar vacío';
      setState(() {});
      return 'Este campo no puede quedar vacío';
    } else {
      return null;
    }
  }

  cargarDatosCategorias() async {
    if (_iniciadaSesionUsuario) {
      debugPrint('TRAE CATEGORIAS DE FIREBASE');
      listaAux = await FirebaseProvider()
          .cargarCategoriaServicios(_emailSesionUsuario);
    }

    listaCategoriaServicios = listaAux;

    if (listaCategoriaServicios.isNotEmpty) {
      for (var item in listaCategoriaServicios) {
        listNombreCategoriaServicios.add(item.nombreCategoria.toString());
      }
      debugPrint(listNombreCategoriaServicios.toString());

      dropdownValue = listNombreCategoriaServicios[0];
      setState(() {});
    }
  }

  void mensaje(texto) {
    mensajeSuccess(context, texto);
  }

  _listaCategorias() {
    return Flexible(
      child: FutureBuilder(
        future: FirebaseProvider().cargarCategorias(_emailSesionUsuario),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Error al cargar los datos');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }

          return ListView(
            children: snapshot.data!.map((document) {
              return Text(
                document['nombreCategoria'],
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueGrey),
              )
                  //subtitle: Text(data['campo2']),
                  ;
            }).toList(),
          );
        },
      ),
    );
  }
}
