import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optima_ml/router.dart';
import 'package:optima_ml/nucleo/tema.dart';
import 'package:optima_ml/nucleo/proveedor_estado.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProveedorEstado()..inicializarApp(),
        ),
      ],
      child: MaterialApp.router(
        title: 'I HEAR(TH)',
        theme: TemaApp.obtenerTema(),
        routerConfig: rutasApp,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
