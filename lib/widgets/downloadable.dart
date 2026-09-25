import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'ui.dart';

/// Captured content can be saved/shared either as a PNG image or a PDF.
enum DownloadFormat { image, pdf }

/// Writes [pdfBytes] to a temp file and opens the share/save sheet.
Future<bool> sharePdfBytes(
  BuildContext context,
  Uint8List pdfBytes,
  String fileName, {
  String? shareText,
}) async {
  Rect origin = const Rect.fromLTWH(0, 0, 1, 1);
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    origin = box.localToGlobal(Offset.zero) & box.size;
  }
  try {
    final dir = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${dir.path}/$safeName.pdf');
    await file.writeAsBytes(pdfBytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: '$safeName.pdf')],
      text: shareText,
      sharePositionOrigin: origin,
    );
    return true;
  } catch (e) {
    if (context.mounted) {
      await showToast(context, "We couldn't prepare the PDF.\n($e)",
          isSuccess: false, title: 'Download Failed');
    }
    return false;
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
  Rect origin = const Rect.fromLTWH(0, 0, 1, 1); // iPad share-popover anchor
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    origin = box.localToGlobal(Offset.zero) & box.size;
  }

  try {
    final pngBytes = await _capturePng(boundaryKey, pixelRatio);
    final dir = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

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
      final file = File('${dir.path}/$safeName.pdf');
      await file.writeAsBytes(await doc.save(), flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: '$safeName.pdf')],
        text: shareText,
        sharePositionOrigin: origin,
      );
      return true;
    }

    // On Android the native share sheet doesn't reliably save an image to the
    // gallery, so write it straight to Photos via the MediaStore. iOS keeps the
    // share sheet, which already offers "Save Image" / "Save to Files".
    if (Platform.isAndroid) {
      final file = File('${dir.path}/$safeName.png');
      await file.writeAsBytes(pngBytes, flush: true);
      final hasAccess = await Gal.hasAccess() || await Gal.requestAccess();
      if (!hasAccess) {
        if (context.mounted) {
          await showToast(
              context,
              'Allow photo access in Settings to save the image, '
              'or use the share button to send it instead.',
              isSuccess: false,
              title: 'Permission Needed');
        }
        return false;
      }
      await Gal.putImage(file.path, album: 'ANI HRIS');
      if (context.mounted) {
        await showToast(context, 'Saved to your Photos.',
            isSuccess: true, title: 'Image Saved');
      }
      return true;
    }

    final file = File('${dir.path}/$safeName.png');
    await file.writeAsBytes(pngBytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png', name: '$safeName.png')],
      text: shareText,
      sharePositionOrigin: origin,
    );
    return true;
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
