import 'package:agendacitas/utils/alertasSnackBar.dart';
import 'package:collection/collection.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lista_draggable_servicios_model.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'creacion_citas/provider/creacion_cita_provider.dart';

/* List<DraggableList> allLists = [
  const DraggableList(header: 'categoria 1', items: [
    DraggableListItem(
        title: 'title 1',
        leading: 'leading 1',
        subtitle: 'subtitle 1',
        trailing: 'trailing 1'),
    DraggableListItem(
        title: 'title 2',
        leading: 'leading 2',
        subtitle: 'subtitle 2',
        trailing: 'trailing 2'),
    DraggableListItem(
        title: 'title 3',
        leading: 'leading 3',
        subtitle: 'subtitle 3',
        trailing: 'trailing 3'),
    DraggableListItem(
        title: 'title 4',
        leading: 'leading 4',
        subtitle: 'subtitle 4',
        trailing: 'trailing 4'),
  ]),

]; */
List<DraggableList> allLists = [];

class ServiciosScreenDraggable extends StatefulWidget {
  ServiciosScreenDraggable(
      {super.key,
      required this.servicios,
      required this.usuarioAPP,
      required this.procede});

  List<Map<String, dynamic>> servicios;
  String usuarioAPP;
  String procede;

  @override
  State<ServiciosScreenDraggable> createState() =>
      _ServiciosScreenDraggableState();
}

class _ServiciosScreenDraggableState extends State<ServiciosScreenDraggable> {
  late PersonalizaProvider contextoPersonaliza;
  late CreacionCitaProvider contextoCreacionCita;
  late List<DragAndDropList> listCategorias;
  late List<DraggableList> convertedListCategorias = [];
  List<DraggableListItem> convertedListServiciosCategorizados = [];
  late List<Map<String, dynamic>> servicios;
  bool canDrag = false;

  adaptacionListas() {
    print(widget.servicios);
    Map<String, List<Map<String, dynamic>>> categorizedMap = groupBy(
      widget.servicios,
      (item) => item['nombreCategoria'],
    );

    convertedListCategorias = categorizedMap.entries.map((entry) {
      List<DraggableListItem> items = entry.value.map((item) {
        return DraggableListItem(
            index: item['index'],
            title: item['servicio'],
            leading: 'img',
            subtitle: item['precio'].toString(),
            trailing: 'trailing',
            id: item['id'],
            detalle: item['detalle'],
            tiempo: item['tiempo'],
            idCategoria: item['idcategoria']);
      }).toList();

      items.sort((a, b) => a.index.compareTo(b.index));

      return DraggableList(header: entry.key, items: items);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // TRAE CONTEXTO PERSONALIZA ( MONEDA ). ES NECESARIO INIZIALIZARLA ANTES DE LLAMAR A  buildList DONDE SE UTILIZA EL CONTEXTO PARA LA MONEDA
    contextoPersonaliza = context.read<PersonalizaProvider>();

    adaptacionListas();
    allLists = convertedListCategorias;

    //···  allList = a la lista adaptada traida de servicios firebase ·····
    listCategorias = allLists.map(buildList).toList();
  }

  @override
  Widget build(BuildContext context) {
    // contexto Creacion de la cita
    contextoCreacionCita = context.read<CreacionCitaProvider>();

    final backgroundColor = Theme.of(context).canvasColor;

    return DragAndDropLists(
      // lastItemTargetHeight: 50,
      listPadding: const EdgeInsets.all(16),
      listInnerDecoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10)),

      onItemReorder: onReorderListItem,
      onListReorder: onReorderList,
      listDragHandle: buildDragHandle(isList: true),
      itemDragHandle: buildDragHandle(),
      itemDecorationWhileDragging: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.red, blurRadius: 4)]),
      itemDivider: Divider(
        thickness: 2,
        height: 2,
        color: backgroundColor,
      ),
      children: listCategorias,
    );
  }

  bool switchValue = true;
  DragAndDropList buildList(DraggableList list) {
    return DragAndDropList(
      canDrag: canDrag,
      header: Container(
        padding: const EdgeInsets.all(8),
        child: Text(
          list.header,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: Colors.blueGrey),
        ),
      ),
      children: list.items.map((item) {
        // PRIMERO ADAPTO EL item AL MODELO ServicioModelFB , PARA ENVIAR COMO ARGUMENTO A configServicios (editar servicio)
        ServicioModelFB servicioFB = ServicioModelFB(
            id: item.id,
            //activo: item.act,
            detalle: item.detalle,
            precio: double.parse(item.subtitle),
            servicio: item.title,
            tiempo: item.tiempo,
            idCategoria: item.idCategoria,
            //idCategoria: item.categoria,
            index: item.index);

        // #####################   TARJETAS DE SERVICIOS ###############################
        return DragAndDropItem(
            canDrag: canDrag,
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Color.fromARGB(179, 232, 5, 5),
                        width: 2,
                      ),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      contextoCreacionCita.setAgregaAListaServiciosElegidos = [
                        {
                          'ID': item.id.toString(),
                          'SERVICIO': item.title,
                          'TIEMPO': item.tiempo,
                          'PRECIO': item.subtitle,
                          'DETALLE': item.detalle,
                        }
                      ];
                      // DEPENDIENDO DE DE LA PAGINA QUE PROVENGA, NAVEGARA A LA PAGINACORRESPONDIENTE( PUEDE PRECEDER DE CONFIGURACION DE SERVICIOS O DE CREACION DE LA CITA)
                      widget.procede == 'CREACION_DE_CITA'
                          ? Navigator.pushNamed(
                              context, 'creacionCitaComfirmar',
                              arguments: servicioFB)
                          : Navigator.pushNamed(context, 'configServicios',
                              arguments: servicioFB);
                    },
                    child: ListTile(
                      title: Text(
                        item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.blueGrey),
                      ),
                      //leading: Text(item.leading),
                      subtitle: Text(
                        '${item.subtitle.toString()} ${contextoPersonaliza.getPersonaliza['MONEDA']} ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: Colors.blueGrey),
                      ),
                      trailing: Text(
                        item.tiempo.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.blueGrey),
                      ), //const Icon(Icons.move_down_rounded),
                    ),
                  ),
                ),
              ],
            ));
      }).toList(),
    );
  }

  void onReorderList(
    int oldListIndex,
    int newListIndex,
  ) {
    setState(() {
      final movedList = listCategorias.removeAt(oldListIndex);
      listCategorias.insert(newListIndex, movedList);
    });
  }

  void onReorderListItem(
    int oldItemIndex,
    int oldListIndex,
    int newItemIndex,
    int newListIndex,
  ) async {
/*     final int newIndexAdaptado =
        newListIndex != 0 ? newItemIndex + newListIndex * 100 : newItemIndex;
    final int oldIndexAdaptado =
        oldListIndex != 0 ? oldItemIndex + oldListIndex * 100 : oldItemIndex; */
    const oldIndexAdaptado = 100;
    const newIndexAdaptado = 101;
    var oldIdServicio = await buscaDocumento(oldIndexAdaptado);
    var newIdServicio = await buscaDocumento(newIndexAdaptado);

    setState(() {
      final oldListItems = listCategorias[oldListIndex].children;
      final newListItems = listCategorias[newListIndex].children;

      //modifica el index añadiendole el digito del index de la lista
//  0 => lista 0 => 00

      debugPrint(widget.servicios.toString());
      debugPrint(
          'oldListIndex: INDICE LISTA OLD------------------------${oldListIndex.toString()}');
      debugPrint(
          'newListIndex: INDICE LISTA NEW------------------------${newListIndex.toString()}');

      debugPrint(
          'oldItemIndes: INDECE ITEM OLD POSICION :  ${oldItemIndex.toString()}');
      debugPrint(
          'newItemIndes: INDECE ITEM NEW POSICION :  ${newItemIndex.toString()}');

      debugPrint(
          'oldItemIndes: INDECE ITEM OLD POSICION  adaptado:  ${oldIndexAdaptado.toString()}');
      debugPrint(
          'newItemIndes: INDECE ITEM NEW POSICION adaptado:  ${newIndexAdaptado.toString()}');

      debugPrint(' oldIdServicio: ID DEL SERVICIO INICIO $oldIdServicio');
      debugPrint(' oldIdServicio: ID DEL SERVICIO FIANL $newIdServicio');
      //---------------------- ACTUALIZA LISTA EN FIREBASE ----------------------------

      if (oldListIndex == newListIndex) {
        // PERMITE MODIFICAR SI SON ITEM DE LA MISMA LISTA
        /*   FirebaseProvider().modificaIndexServicio(
            widget.usuarioAPP,
            oldIdServicio,
            newIdServicio,
            oldItemIndex,
            newItemIndex,
            oldListIndex,
            newListIndex);
 */
        final movedItem = oldListItems.removeAt(oldItemIndex);
        newListItems.insert(newItemIndex, movedItem);
      } else {
        mensajeError(context,
            'NO SE PERMITE ENTRE CATEGORIAS DIFERENTES, EDITA EL SERVICIO ');
      }

      //---------------------- ACTUALIZA LISTA EN EL WIDGET ----------------------------
    });
  }

  DragHandle buildDragHandle({bool isList = false}) {
    final verticalAlignment = isList
        ? DragHandleVerticalAlignment.top
        : DragHandleVerticalAlignment.center;

    final color = isList ? Colors.blueGrey : Colors.black26;

    return DragHandle(
        verticalAlignment: verticalAlignment,
        child: Container(
          padding: const EdgeInsets.all(5),
          child: Icon(
            Icons.menu,
            color: color,
          ),
        ));
  }

  Future<dynamic> buscaDocumento(index) async {
    String documentId =
        await FirebaseProvider().buscarDocumento(widget.usuarioAPP, index);

    print(documentId);
    return documentId;
  }

  Future<dynamic> _mensajeAlerta(context, String index) {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
              title: const Icon(
                Icons.warning,
                color: Colors.red,
              ),
              content: const Text('¿ Quieres este servicio ?'),
              actions: [
                ElevatedButton.icon(
                    onPressed: () {
                      FirebaseProvider()
                          .elimarServicio(widget.usuarioAPP, index)
                          .then((value) {
                        mensajeSuccess(context, 'Eliminado correctamente');
                        volver(context);
                      });
                    },
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Eliminar')),
                const SizedBox(
                  width: 20,
                ),
                TextButton(
                    onPressed: () {
                      volver(context);
                    },
                    child: const Text(
                      ' No ',
                      style: TextStyle(fontSize: 18),
                    )),
              ],
            )).then((value) => setState(
          () {},
        ));
  }

  void volver(context) {
    Navigator.pop(context);
    setState(() {});
    /*  Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ServiciosScreen(),
        )); */
  }
}
