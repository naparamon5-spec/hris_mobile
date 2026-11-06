import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'ui.dart';

/// Captured content can be saved/shared either as a PNG image or a PDF.
enum DownloadFormat { image, pdf }

const _downloads = MethodChannel('com.ardentnetworks.hris/downloads');

/// Saves [pdfBytes] and tells the user whether it worked. Android writes
/// straight to the Downloads folder; iOS opens the share sheet, which has
/// "Save to Files". Returns true only if the file was saved or shared.
Future<bool> savePdfBytes(
  BuildContext context,
  Uint8List pdfBytes,
  String fileName, {
  String? shareText,
}) async {
  final origin = _shareOrigin(context);
  final safeName = _safeName(fileName);
  try {
    if (Platform.isAndroid) {
      // Only Android 9 and below actually prompts; newer versions need no
      // permission to add to Downloads.
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
        if (context.mounted) await _showPermissionNeeded(context, 'PDF');
        return false;
      }
      final saved = await _downloads.invokeMethod<String>('savePdf', {
        'bytes': pdfBytes,
        'name': '$safeName.pdf',
      });
      if (context.mounted) {
        await showToast(context, 'Saved to your Downloads folder as $saved.',
            isSuccess: true, title: 'Download Complete');
      }
      return true;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$safeName.pdf');
    await file.writeAsBytes(pdfBytes, flush: true);
    if (!context.mounted) return false;
    return await _shareAndReport(
      context,
      XFile(file.path, mimeType: 'application/pdf', name: '$safeName.pdf'),
      origin,
      shareText,
    );
  } catch (e) {
    if (context.mounted) {
      await showToast(context, "We couldn't save the PDF.\n($e)",
          isSuccess: false, title: 'Download Failed');
    }
    return false;
  }
}

String _safeName(String fileName) =>
    fileName.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

/// iPad share-popover anchor.
Rect _shareOrigin(BuildContext context) {
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  return const Rect.fromLTWH(0, 0, 1, 1);
}

Future<void> _showPermissionNeeded(BuildContext context, String what) =>
    showToast(
      context,
      'Allow storage access in Settings to save the $what.',
      isSuccess: false,
      title: 'Permission Needed',
    );

/// Opens the share sheet for [file], then reports what the user did with it.
Future<bool> _shareAndReport(
  BuildContext context,
  XFile file,
  Rect origin,
  String? shareText,
) async {
  final result = await Share.shareXFiles(
    [file],
    text: shareText,
    sharePositionOrigin: origin,
  );
  if (!context.mounted) return result.status != ShareResultStatus.dismissed;
  switch (result.status) {
    case ShareResultStatus.success:
      await showToast(context, 'Your file was saved or shared.',
          isSuccess: true, title: 'Download Complete');
      return true;
    case ShareResultStatus.dismissed:
      await showToast(context, 'Nothing was saved.',
          warning: true, title: 'Download Cancelled');
      return false;
    case ShareResultStatus.unavailable:
      // The platform can't say what happened, so don't claim either outcome.
      await showToast(context, 'Check that your file was saved.',
          warning: true, title: 'Download Finished');
      return true;
  }
}

/// Renders the widget behind [boundaryKey] to high-resolution PNG bytes.
/// Throws on failure. Returns the encoded PNG bytes.
Future<Uint8List> _capturePng(GlobalKey boundaryKey, double pixelRatio) async {
  var obj = boundaryKey.currentContext?.findRenderObject();
  if (obj is RenderRepaintBoundary && obj.debugNeedsPaint) {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await SchedulerBinding.instance.endOfFrame;
    obj = boundaryKey.currentContext?.findRenderObject();
  }
  if (obj is! RenderRepaintBoundary) {
    throw StateError('The content is not ready yet.');
  }
  final image = await obj.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (byteData == null) throw StateError('Could not encode the image.');
  return byteData.buffer.asUint8List();
}

/// Renders the widget behind [boundaryKey] to a high-resolution PNG and opens
/// the native share/save sheet so the user can save it to Photos/Files or send
/// it on. Returns false if capture failed. Wrap the content you want captured in
/// a `RepaintBoundary(key: boundaryKey)`.
Future<bool> captureAndShare(
  BuildContext context,
  GlobalKey boundaryKey,
  String fileName, {
  String? shareText,
  DownloadFormat format = DownloadFormat.image,
}) async {
  // Read everything that needs `context` up front, before any await.
  final dpr = MediaQuery.of(context).devicePixelRatio;
  final pixelRatio = (dpr > 0 ? dpr.clamp(1.0, 3.0) : 2.0).toDouble();
  final origin = _shareOrigin(context);

  try {
    final pngBytes = await _capturePng(boundaryKey, pixelRatio);
    final dir = await getTemporaryDirectory();
    final safeName = _safeName(fileName);

    if (format == DownloadFormat.pdf) {
      // Embed the captured payslip image onto a single portrait page.
      final doc = pw.Document();
      final img = pw.MemoryImage(pngBytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => pw.Center(
            child: pw.Image(img, fit: pw.BoxFit.contain),
          ),
        ),
      );
      final pdfBytes = await doc.save();
      if (!context.mounted) return false;
      return await savePdfBytes(context, pdfBytes, fileName,
          shareText: shareText);
    }

    // On Android the native share sheet doesn't reliably save an image to the
    // gallery, so write it straight to Photos via the MediaStore. iOS keeps the
    // share sheet, which already offers "Save Image" / "Save to Files".
    if (Platform.isAndroid) {
      final file = File('${dir.path}/$safeName.png');
      await file.writeAsBytes(pngBytes, flush: true);
      // toAlbum: saving into our own album needs the permission on Android 10.
      final hasAccess = await Gal.hasAccess(toAlbum: true) ||
          await Gal.requestAccess(toAlbum: true);
      if (!hasAccess) {
        if (context.mounted) await _showPermissionNeeded(context, 'image');
        return false;
      }
      await Gal.putImage(file.path, album: 'ANI HRIS');
      if (context.mounted) {
        await showToast(context, 'Saved to your Photos in the ANI HRIS album.',
            isSuccess: true, title: 'Download Complete');
      }
      return true;
    }

    final file = File('${dir.path}/$safeName.png');
    await file.writeAsBytes(pngBytes, flush: true);
    if (!context.mounted) return false;
    return await _shareAndReport(
      context,
      XFile(file.path, mimeType: 'image/png', name: '$safeName.png'),
      origin,
      shareText,
    );
  } on GalException catch (e) {
    if (context.mounted) {
      await showToast(context, "We couldn't save the image. ${e.type.message}",
          isSuccess: false, title: 'Download Failed');
    }
    return false;
  } catch (e) {
    if (context.mounted) {
      await showToast(
          context,
          "We couldn't prepare the file. If this keeps happening, fully "
          "reopen the app and try again.\n($e)",
          isSuccess: false,
          title: 'Download Failed');
    }
    return false;
  }
}
