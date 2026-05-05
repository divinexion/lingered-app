import 'package:ordercentral_owner_app_flutter/app.dart';
import 'package:ordercentral_owner_app_flutter/core/services/api_services/utils/log.dart';
import 'package:ordercentral_owner_app_flutter/core/services/pref/app_preferences.dart';
import 'package:ordercentral_owner_app_flutter/core/services/pref/pref_listenner.dart';

import 'package:flutter/material.dart';

import 'dart:async';
import 'package:flutter/services.dart';

import 'core/services/connectivity/connectivity_helper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  return runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // await Firebase.initializeApp(
      //   options: const FirebaseOptions(
      //     apiKey: "AIzaSyD_gdkooKrfuONu2t0MwsVUiNRhRTqXsxg",
      //     appId: "1:980973396054:android:84bc07775f9e238c8cdbf7",
      //     messagingSenderId: "980973396054",
      //     projectId: "order-central-pos",
      //     storageBucket: "order-central-pos.firebasestorage.app",
      //   ),
      // );

      // System UI setup
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);

      await AppPreferences.init();
      PreferenceListener.initialize();

      // Initialize ConnectivityHelper
      final connectivityHelper = ConnectivityHelper();
      connectivityHelper.initialize();

      runApp(
        DivineOwnerApp(
          connectivityHelper: connectivityHelper,
          navigatorKey: navigatorKey,
        ),
      );
    },
    (error, stackTrace) {
      Log.error(error.toString());
      Log.error(stackTrace.toString());
    },
  );
}
