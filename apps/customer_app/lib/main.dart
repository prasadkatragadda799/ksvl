import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/shell_provider.dart';
import 'providers/user_account_provider.dart';
import 'providers/wishlist_provider.dart';
import 'screens/main_shell.dart';

/// KSVL Naturals — customer web / PWA storefront.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  CloudinaryConfig.configure(
    const CloudinaryConfig(cloudName: 'ol8scfgk', uploadPreset: 'Imageksvl'),
  );
  SystemChrome.setSystemUIOverlayStyle(
    KsvlTheme.overlayStyle(Brightness.light),
  );
  runApp(const KsvlStoreApp());
}

class KsvlStoreApp extends StatelessWidget {
  const KsvlStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => UserAccountProvider()),
        ChangeNotifierProvider(create: (_) => ShellProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProxyProvider<UserAccountProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, account, cart) {
            cart!.syncAccount(account.phone, account.cartLines);
            return cart;
          },
        ),
      ],
      child: MaterialApp(
        title: 'KSVL Naturals',
        debugShowCheckedModeBanner: false,
        theme: KsvlTheme.light,
        darkTheme: KsvlTheme.dark,
        themeMode: ThemeMode.system,
        scrollBehavior: const _StoreScrollBehavior(),
        home: const MainShell(),
      ),
    );
  }
}

/// Lets the storefront be dragged with a mouse or trackpad on desktop web,
/// which is how most people will scroll a horizontal category or banner rail.
class _StoreScrollBehavior extends MaterialScrollBehavior {
  const _StoreScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
