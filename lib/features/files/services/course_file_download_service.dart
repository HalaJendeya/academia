// lib/features/files/services/course_file_download_service.dart

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CourseFileDownloadException implements Exception {
  final String message;
  const CourseFileDownloadException(this.message);

  @override
  String toString() => message;
}

/// تقدّم تنزيل لحظي حقيقي، مبني على البايتات المستلَمة فعليًا من الشبكة.
///
/// [totalBytes] قد يكون null إن لم يُرسل الخادم رأس Content-Length — عندها
/// لا نسبة مئوية موثوقة، فتُعرض حالة "جارٍ التنزيل" بلا شريط تقدّم دقيق بدل
/// نسبة مُختلقة.
class CourseFileDownloadProgress {
  const CourseFileDownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
  });

  final int receivedBytes;
  final int? totalBytes;

  double? get fraction {
    if (totalBytes == null || totalBytes == 0) return null;
    return receivedBytes / totalBytes!;
  }
}

/// تنزيل ملف مساق من رابط Cloudinary إلى مجلد وثائق التطبيق على الجهاز.
///
/// لا توجد ميزة "متاح دون إنترنت" حقيقية بعد (لا فهرسة، لا مزامنة) — هذه
/// الخدمة تنزّل نسخة محلية واحدة فقط عند الطلب الصريح من الطالب، ولا تتبع
/// حالة "تم التنزيل" عبر إعادة فتح التطبيق.
class CourseFileDownloadService {
  final http.Client _client;

  CourseFileDownloadService({http.Client? client})
      : _client = client ?? http.Client();

  /// ينزّل الملف ويعيد المسار المحلي عند النجاح. [onProgress] يُستدعى مع كل
  /// دفعة بايتات مستلَمة فعليًا من الشبكة، لا بقيم مصطنعة.
  ///
  /// [isCancelled] يُفحص بين كل دفعة وأخرى؛ إن أصبحت true يُوقَف التنزيل
  /// ويُحذف الملف الجزئي، بدل ترك ملف تالف على الجهاز.
  Future<String> download({
    required String url,
    required String fileName,
    required void Function(CourseFileDownloadProgress progress) onProgress,
    bool Function()? isCancelled,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || url.trim().isEmpty) {
      throw const CourseFileDownloadException('رابط الملف غير صالح.');
    }

    http.StreamedResponse response;
    try {
      response = await _client.send(http.Request('GET', uri));
    } catch (e) {
      throw const CourseFileDownloadException(
        'تعذر الاتصال بخدمة التخزين. تحققي من الاتصال وحاولي مرة أخرى.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const CourseFileDownloadException('تعذر تنزيل الملف.');
    }

    final totalBytes = response.contentLength;
    final dir = await getApplicationDocumentsDirectory();
    final safeName = _sanitize(fileName);
    final file = File('${dir.path}/$safeName');
    final sink = file.openWrite();

    var received = 0;
    try {
      await for (final chunk in response.stream) {
        if (isCancelled?.call() ?? false) {
          await sink.close();
          if (await file.exists()) await file.delete();
          throw const CourseFileDownloadException('أُلغي التنزيل.');
        }
        sink.add(chunk);
        received += chunk.length;
        onProgress(
          CourseFileDownloadProgress(
            receivedBytes: received,
            totalBytes: totalBytes,
          ),
        );
      }
      await sink.close();
      return file.path;
    } on CourseFileDownloadException {
      rethrow;
    } catch (e) {
      await sink.close();
      if (await file.exists()) await file.delete();
      throw const CourseFileDownloadException('تعذر حفظ الملف على الجهاز.');
    }
  }

  /// يزيل محارف غير صالحة في أسماء الملفات على بعض الأنظمة.
  String _sanitize(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'ملف_بدون_اسم' : cleaned;
  }

  void dispose() => _client.close();
}