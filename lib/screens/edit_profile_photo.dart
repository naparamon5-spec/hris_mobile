import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import '../data/profile_state.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

/// Entry point: let the user pick a source, choose an image, then adjust and
/// upload it as their profile photo — mirroring Sprout HR's "Edit Profile
/// Photo" cropper.
Future<void> editProfilePhoto(BuildContext context) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: AppColors.brandRed),
            title: const Text('Choose from Library',
                style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading:
                const Icon(Icons.photo_camera_outlined, color: AppColors.brandRed),
            title: const Text('Take Photo',
                style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          if (ProfileState.instance.hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.inkSoft),
              title: const Text('Remove current photo',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (!context.mounted || action == null) return;

  if (action == 'remove') {
    ProfileState.instance.clearPhoto();
    showToast(context, 'Profile photo removed');
    return;
  }

  final picker = ImagePicker();
  final XFile? file = await picker.pickImage(
    source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 1400,
    maxHeight: 1400,
    imageQuality: 92,
  );
  if (file == null || !context.mounted) return;

  final bytes = await file.readAsBytes();
  if (!context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _EditProfilePhotoScreen(imageBytes: bytes),
    ),
  );
}

class _EditProfilePhotoScreen extends StatefulWidget {
  const _EditProfilePhotoScreen({required this.imageBytes});
  final Uint8List imageBytes;

  @override
  State<_EditProfilePhotoScreen> createState() =>
      _EditProfilePhotoScreenState();
}

class _EditProfilePhotoScreenState extends State<_EditProfilePhotoScreen> {
  final _cropKey = GlobalKey();
  final _controller = TransformationController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    setState(() => _saving = true);
    try {
      final boundary = _cropKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      ProfileState.instance.setPhoto(byteData.buffer.asUint8List());
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast(context, 'Profile photo updated');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Edit Profile Photo')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Drag to reposition and pinch to zoom. The circle shows how your '
                'photo will be cropped.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
              ),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side = constraints.biggest.shortestSide.clamp(0, 340) *
                        0.9;
                    return SizedBox(
                      width: side.toDouble(),
                      height: side.toDouble(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // The square that actually gets captured.
                          RepaintBoundary(
                            key: _cropKey,
                            child: ClipRect(
                              child: InteractiveViewer(
                                transformationController: _controller,
                                minScale: 1,
                                maxScale: 5,
                                clipBehavior: Clip.hardEdge,
                                child: Image.memory(
                                  widget.imageBytes,
                                  width: side.toDouble(),
                                  height: side.toDouble(),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          // Circular mask overlay (non-interactive).
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size(side.toDouble(), side.toDouble()),
                              painter: _CircleMaskPainter(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _upload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(_saving ? 'Saving…' : 'Upload'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dims the area outside a centred circle so the user sees the crop region,
/// like the Sprout HR cropper.
class _CircleMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.shortestSide / 2;
    final center = size.center(Offset.zero);

    final overlay = Path()..addRect(rect);
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final dim = Path.combine(PathOperation.difference, overlay, hole);

    canvas.drawPath(
      dim,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
