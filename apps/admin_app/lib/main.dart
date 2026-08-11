import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'providers/store_provider.dart';
import 'screens/admin_auth_gate.dart';

/// KSVL Admin — Store Manager mobile app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  CloudinaryConfig.configure(
    const CloudinaryConfig(
      cloudName: 'ol8scfgk',
      uploadPreset: 'Imageksvl',
    ),
  );
  SystemChrome.setSystemUIOverlayStyle(
    KsvlTheme.overlayStyle(Brightness.light),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const KsvlAdminApp());
}

class KsvlAdminApp extends StatelessWidget {
  const KsvlAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'KSVL Admin',
        debugShowCheckedModeBanner: false,
        theme: KsvlTheme.light,
        darkTheme: KsvlTheme.dark,
        themeMode: ThemeMode.system,
        home: const AdminAuthGate(),
        // Store staff often run large system font sizes; clamp the top end so
        // the layout bends instead of breaking.
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: media.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.3,
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
