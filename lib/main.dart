import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/akademia_app.dart';
import 'app/app_providers.dart';
import 'firebase_options.dart';

/*
 * لا تهيئة عامة لـ Cloudinary هنا.
 *
 * الرفع في هذه المرحلة طلب multipart غير موقَّع إلى preset معلن، ولا يمر
 * بحزم Cloudinary إطلاقًا؛ واسم السحابة يعيش في CloudinaryConfig. الحاوية
 * العامة CloudinaryContext مهملة في الحزمة ولم يكن يقرأها أي شيء، فوجودها
 * كان إعدادًا ميتًا. عند الحاجة إلى عرض وسائط عبر CldImageWidget يُنشأ
 * CloudinaryObject عند نقطة الاستخدام.
 */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(MultiProvider(providers: appProviders, child: const AkademiaApp()));
}
