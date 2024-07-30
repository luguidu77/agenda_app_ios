import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../mylogic_formularios/mylogic.dart';
import '../providers/providers.dart';
import '../screens/style/estilo_pantalla.dart';
import '../utils/optiene_numero_mayor_index_firebase.dart';

class ConfigServiciosScreen extends StatefulWidget {
  const ConfigServiciosScreen({Key? key}) : super(key: key);

  @override
  State<ConfigServiciosScreen> createState() => _ConfigServiciosScreenState();
}

class _ConfigServiciosScreenState extends State<ConfigServiciosScreen> {
  String? _emailSesionUsuario;
  bool _iniciadaSesionUsuario = false;
  String textoErrorValidacionAsunto = '';
  final _formKey = GlobalKey<FormState>();
  ServicioModel servicio =
      ServicioModel(servicio: '', precio: 0, tiempo: '', detalle: '');
  late MyLogicServicio myLogic;

  ServicioModelFB servicioFB = ServicioModelFB(
      servicio: '', precio: 0, tiempo: '', detalle: '', idCategoria: '');
  late MyLogicServicioFB myLogicFB;

  List<CategoriaServicioModel> listaAux = [];
  List<CategoriaServicioModel> listaCategoriaServicios = [];
  List<String> listNombreCategoriaServicios = [];
  List<String> listIdCategoriaServicios = [];
  List<String> idCategoria = [];
  String idCategoriaElegida = '';
  String dropdownValue = '';

  int indexMayor = 0;

  emailUsuario() async {
    //traigo email del usuario, para si es de pago, pasarlo como parametro al sincronizar
    final estadoPagoProvider = context.read<EstadoPagoAppProvider>();
    _emailSesionUsuario = estadoPagoProvider.emailUsuarioApp;
    _iniciadaSesionUsuario = estadoPagoProvider.iniciadaSesionUsuario;
    setState(() {});
    await cargarDatosCategorias();

    //DATA TRAIDA POR NAVIGATOR PUSHNAMED (ARGUMENTS)
    if (_iniciadaSesionUsuario) {
      dataFB = ModalRoute.of(context)!.settings.arguments as ServicioModelFB;

      agregaModificaFB = (dataFB.servicio == null) ? true : false;
      if (!agregaModificaFB) {
        myLogicFB = MyLogicServicioFB(dataFB);
        myLogicFB.init();

        getcategoria(myLogicFB.servicioFB.idCategoria);
      }
    } else {
      data = ModalRoute.of(context)!.settings.arguments as ServicioModel;

      agregaModifica = (data.servicio == null) ? true : false;
      if (!agregaModifica) {
        myLogic = MyLogicServicio(data);
        myLogic.init();
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    emailUsuario();
    myLogic = MyLogicServicio(servicio);
    myLogic.init();

    myLogicFB = MyLogicServicioFB(servicioFB);
    myLogicFB.init();

    // _askPermissions('/nuevacita');
  }

  bool agregaModificaFB = false;
  bool agregaModifica = false;
  var dataFB;
  var data;

  void retornoDeAgregarCategoria() {
    // SE LLAMA ESTA FUNCION CUANDO RETORNA DE LA PAGINA config_categoria_servicio_screen.dart

    // LIMPIA LAS LISTAS
    listNombreCategoriaServicios.clear();
    listIdCategoriaServicios.clear();
    idCategoria.clear();

    // REINICIA LOS DATOS
    emailUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              if (_iniciadaSesionUsuario) {
                debugPrint('iniciada sesion');
                debugPrint('agregaModificaFB $agregaModificaFB');

                (agregaModificaFB)
                    ? agregaServicioFB(_emailSesionUsuario)
                    : modificarServicioFB(_emailSesionUsuario, dataFB,
                        idCategoriaElegida); // METODO MODIFICAR SERVICIO
              } else {
                (agregaModifica)
                    ? agregaServicio()
                    : modificarServicio(data); // METODO MODIFICAR SERVICIO
              }
            }
          },
          child: const Icon(Icons.save),
        ),
        body: _iniciadaSesionUsuario
            ? _formularioFB(context, agregaModificaFB)
            : _formulario(context, agregaModifica),
      ),
    );
  }

  _formulario(context, agregaModifica) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _botonCerrar(),
            Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      (agregaModifica)
                          ? "Agregar servicio "
                          : 'Editar servicio',
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      validator: (value) => _validacion(value),
                      controller: myLogic.textControllerServicio,
                      decoration: const InputDecoration(labelText: 'Servicio'),
                    ),
                    TextFormField(
                      validator: (value) => _validacionPrecio(value),
                      keyboardType: TextInputType.number,
                      controller: myLogic.textControllerPrecio,
                      decoration: const InputDecoration(labelText: 'Precio'),
                    ),
                    TextField(
                      controller: myLogic.textControllerDetalle,
                      decoration: const InputDecoration(labelText: 'Detalle'),
                    ),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextFormField(
                          validator: (value) => _validacion(value),
                          enabled: false,
                          controller: myLogic.textControllerTiempo,
                          decoration: const InputDecoration(
                              labelText: 'Tiempo de servicio'),
                        ),
                        TextButton.icon(
                            onPressed: () => _selectTime(),
                            icon: const Icon(Icons.timer_sharp),
                            label: const Text(''))
                      ],
                    ),
                  ],
                )),
            const SizedBox(height: 150)
          ],
        ),
      ),
    );
  }

  _formularioFB(context, agregaModificaFB) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _botonCerrar(),
            Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      (agregaModificaFB)
                          ? "Agregar servicio "
                          : 'Editar servicio',
                      style: subTituloEstilo,
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                    categoriaServicios(context),
                    Container(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton.icon(
                          onPressed: () async {
                            // todo hacerlo modal desde abajo de pantalla.
                            /*  bool retorno = showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return ConfigCategoriaServiciosScreen();
                              },
                            ) as bool; */

                            // NAVEGA A FORMULARIO CATEGORIAS Y ESPERA RETORNO(bool) PARA 'REINICIAR LA PAGINA'
                            bool retorno = await Navigator.pushNamed(
                                context, 'ConfigCategoriaServiciosScreen',
                                arguments: CategoriaServicioModel()) as bool;
                            if (retorno) {
                              retornoDeAgregarCategoria();
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('nueva categoría')),
                    ),
                    TextFormField(
                      validator: (value) => _validacion(value),
                      controller: myLogicFB.textControllerServicio,
                      decoration: const InputDecoration(labelText: 'Servicio'),
                    ),
                    TextFormField(
                      validator: (value) => _validacion(value),
                      keyboardType: TextInputType.number,
                      controller: myLogicFB.textControllerPrecio,
                      decoration: const InputDecoration(labelText: 'Precio'),
                    ),
                    TextField(
                      controller: myLogicFB.textControllerDetalle,
                      decoration: const InputDecoration(labelText: 'Detalle'),
                    ),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextFormField(
                          validator: (value) => _validacion(value),
                          enabled: false,
                          controller: myLogicFB.textControllerTiempo,
                          decoration: const InputDecoration(
                              labelText: 'Tiempo de servicio'),
                        ),
                        TextButton.icon(
                            onPressed: () => _selectTime(),
                            icon: const Icon(Icons.timer_sharp),
                            label: const Text(''))
                      ],
                    ),
                  ],
                )),
            const SizedBox(height: 150)
          ],
        ),
      ),
    );
  }

  TimeOfDay _time = const TimeOfDay(hour: 1, minute: 00);

  //devuelva la hora seleccionada en el siguiente formato 00:00
  String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final formatter = DateFormat('HH:mm');
    return formatter.format(dateTime);
  }

  void _selectTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
              //useMaterial3: true,
              materialTapTargetSize: MaterialTapTargetSize.padded),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              /* El comportamiento del widget showTimePicker en Flutter depende del sistema operativo del dispositivo 
              en el que se ejecute la aplicación. En algunos dispositivos y sistemas operativos, se mostrará un selector
              de tiempo que permite elegir entre AM y PM, mientras que en otros dispositivos y sistemas operativos, no 
              se mostrará esta opción. Esto es parte de la adaptabilidad de Flutter a las convenciones de diseño de cada plataforma.
              Hemos utilizado MediaQuery para asegurarnos de que la opción de formato de 24 horas esté deshabilitada 
             */

              alwaysUse24HourFormat: false,
            ),
            child: child!,
          ),
        );
      },
      context: context,
      helpText: 'INTRODUCE TIEMPO DE SERVICIO',
      initialEntryMode: TimePickerEntryMode.input,
      hourLabelText: 'Horas',
      minuteLabelText: 'Minutos',
      initialTime: _time,
    );
    if (newTime != null) {
      setState(() {
        _time = newTime;
        print(newTime);
        myLogic.textControllerTiempo.text = formatTimeOfDay(newTime);
        myLogicFB.textControllerTiempo.text = formatTimeOfDay(newTime);
      });
    }
  }

  agregaServicio() {
    final servicio = myLogic.textControllerServicio.text;
    final tiempo = myLogic.textControllerTiempo.text;
    final precio = double.parse(myLogic.textControllerPrecio.text);
    final detalle = myLogic.textControllerDetalle.text;

    CitaListProvider().nuevoServicio(servicio, tiempo, precio, detalle, 'true');

    Navigator.pushReplacementNamed(context, 'Servicios');
  }

  modificarServicio(ServicioModel servicio) {
    ServicioModel auxservicio = ServicioModel();
    auxservicio.id = servicio.id;
    auxservicio.servicio = myLogic.textControllerServicio.text;
    auxservicio.tiempo = myLogic.textControllerTiempo.text;
    auxservicio.precio = double.parse(myLogic.textControllerPrecio.text);
    auxservicio.detalle = myLogic.textControllerDetalle.text;
    auxservicio.activo = 'true';

    CitaListProvider().acutalizarServicio(auxservicio);

    //  CitaListProvider().nuevoServicio(servicio, tiempo, precio, detalle, 'true');

    Navigator.pushReplacementNamed(context, 'Servicios');
  }

  agregaServicioFB(usuarioApp) {
    final servicio = myLogicFB.textControllerServicio.text;
    final tiempo = myLogicFB.textControllerTiempo.text;
    final precio = double.parse(myLogicFB.textControllerPrecio.text);
    final detalle = myLogicFB.textControllerDetalle.text;
    final categoria = idCategoriaElegida;

    FirebaseProvider().nuevoServicio(usuarioApp, servicio, tiempo, precio,
        detalle, categoria, indexMayor + 1);

    Navigator.pushReplacementNamed(context, 'Servicios');
  }

  modificarServicioFB(usuarioApp, ServicioModelFB servicio, idCatElegida) {
    ServicioModelFB auxservicio = ServicioModelFB();
    auxservicio.id = servicio.id;
    auxservicio.servicio = myLogicFB.textControllerServicio.text;
    auxservicio.tiempo = myLogicFB.textControllerTiempo.text;
    auxservicio.precio = double.parse(myLogicFB.textControllerPrecio.text);
    auxservicio.detalle = myLogicFB.textControllerDetalle.text;
    auxservicio.activo = 'true';
    auxservicio.idCategoria = idCategoriaElegida;
    auxservicio.index = 111;
    print(
        '----------------------------que idcategoria guarda   $idCategoriaElegida');

    FirebaseProvider().actualizarServicioFB(usuarioApp, auxservicio);

    Navigator.pushReplacementNamed(context, 'Servicios');
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
                Navigator.pop(context, true);
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

  _validacionPrecio(value) {
    debugPrint(value.isEmpty.toString());
    if (value.isEmpty) {
      textoErrorValidacionAsunto = 'Este campo no puede quedar vacío';
      setState(() {});
      return 'Este campo no puede quedar vacío';
    } else if (value.contains(',')) {
      textoErrorValidacionAsunto = 'Utiliza el "." para los decimales';
      setState(() {});
      return 'Utiliza el "." para los decimales';
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

        idCategoria.add(item.id);
      }
      print(listNombreCategoriaServicios);

      dropdownValue = listNombreCategoriaServicios[0];
    }
    setState(() {});
  }

  var categoria = '';
  Widget categoriaServicios(BuildContext context) {
    return DropdownButtonFormField(
      decoration: const InputDecoration(
          labelText: 'Categoría',
          border: UnderlineInputBorder(borderSide: BorderSide.none)),
      //opcion color para cambio tema: iconEnabledColor: Colors.amber,
      hint: myLogicFB.servicioFB.servicio == ''
          ? const Text('ELIGE UNA CATEGORÍA')
          : Text(categoria.toString()),

      validator: (value) => value == null ? 'Seleciona una categoría' : null,
      items: listNombreCategoriaServicios
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) async {
        late int indexCategoriaElegida;
        setState(() {
          dropdownValue = newValue!;
          myLogicFB.textControllerCategoria.text = newValue;

          indexCategoriaElegida =
              listNombreCategoriaServicios.indexOf(dropdownValue);
          idCategoriaElegida = idCategoria[indexCategoriaElegida];

          print(idCategoriaElegida);
          print(indexCategoriaElegida);
          print(idCategoria);
        });
        // envio el indexCategoriaElegida para devolver el index mayor dependiendo de la categoria elegida
        indexMayor = await devuelveIndexMayorServicios(
            _iniciadaSesionUsuario, _emailSesionUsuario, indexCategoriaElegida);
        print('index mayor de la lista : ----------------------$indexMayor');
      },
    );
  }

  getcategoria(idCategoria) async {
    Map<String, dynamic> categoria = await FirebaseProvider()
        .cargarCategoriaServiciosID(_emailSesionUsuario, idCategoria!);

    return categoria['nombreCategoria'];
  }
}
