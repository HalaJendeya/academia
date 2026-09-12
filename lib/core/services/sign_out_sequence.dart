// lib/core/services/sign_out_sequence.dart

import 'package:flutter/foundation.dart';

/// ترتيب تسجيل الخروج، معزولًا عن Firebase.
///
/// 🔴 الترتيب هنا هو الميزة، لا التغليف.
///
/// مسح رمز الدفع كتابةٌ على `users/{uid}`، وقاعدة Firestore تشترط أن يكون
/// الكاتب هو صاحب المستند **المصادَق**. فإن جرى المسح بعد
/// `FirebaseAuth.signOut()` كان `request.auth` قد صار null، فتُرفض الكتابة
/// بـ PERMISSION_DENIED ويبقى رمز قديم على الحساب. لذلك المسح أولًا،
/// والخروج بعده — وهذا ما تثبّته `sign_out_sequence_test`.
///
/// والقاعدة الثانية: **الخروج لا يفشل أبدًا بسبب الإشعارات**. تنظيف الرمز
/// خدمة مساعدة؛ لو تعذّر (لا شبكة، رفض قاعدة، عطل بالمكوّن الإضافي) فأسوأ
/// ما يحدث بقاء رمز لن يُسلَّم إليه شيء بعد أن يُبطله الجهاز. أما فشل
/// الخروج نفسه فيعني بقاء المستخدم داخل حساب أراد مغادرته — وهذا أسوأ
/// بكثير. لذلك [clearPushToken] يُبتلع خطؤه، و[signOut] يُنفَّذ دائمًا.
Future<void> runSignOutSequence({
  required Future<void> Function() clearPushToken,
  required Future<void> Function() signOut,
}) async {
  try {
    await clearPushToken();
  } catch (e) {
    // لا يُسجَّل الرمز ولا أي جزء منه — سبب الفشل وحده.
    debugPrint('FCM: push-token cleanup failed during sign-out; signing out anyway.');
  }

  // خارج الـ try عمدًا: خطأ الخروج نفسه يجب أن يصل إلى المستدعي ليعرضه
  // للمستخدم، لا أن يُبتلع مع خطأ التنظيف.
  await signOut();
}
