import 'package:flutter/material.dart';

import '../providers/personaliza_provider.dart';

Future tarjetaModificarValores(context, personaliza, String valor) {
  TextEditingController ctrl_1 = TextEditingController();
  final formKey = GlobalKey<FormState>();

  late String textoInput, hintText, simbolo;
  late TextInputType textInputType;
  late Function modificaDato;
  // dejo abierto a la posibilidad de cambiar mas opciones de la aplicacion
  switch (valor) {
    case 'codPais':
      textoInput = 'Código país: ';
      hintText = '34';
      simbolo = '+';
      textInputType = TextInputType.number;
      modificaDato = () => personaliza.codpais = int.parse(ctrl_1.text);
      break;
    case 'monedaPais':
      textoInput = 'Moneda país: ';
      hintText = '€';
      simbolo = '';
      textInputType = TextInputType.text;

      modificaDato = () => personaliza.moneda = ctrl_1.text;
      break;
    default:
  }

  return showModalBottomSheet(
    isDismissible: false,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), topRight: Radius.circular(10))),
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                Text(textoInput),
                const SizedBox(width: 10),
                Text(simbolo),
                Expanded(
                  child: Form(
                    key: formKey,
                    child: TextFormField(
                      // The validator receives the text that the user has entered.
                      controller: ctrl_1,
                      decoration: InputDecoration(hintText: hintText),
                      keyboardType: textInputType,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'No puede estar vacío';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
                onPressed: () async => {
                      if (formKey.currentState!.validate())
                        {
                          modificaDato(),
                          await PersonalizaProvider()
                              .actualizarPersonaliza(personaliza),
                          Navigator.pop(context)
                        },
                    },
                icon: const Icon(Icons.check),
                label: const Text('Validar'))
          ],
        ),
      );
    },
  );
}
