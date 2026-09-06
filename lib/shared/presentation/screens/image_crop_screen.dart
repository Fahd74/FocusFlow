import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../app/theme/focus_flow_colors.dart';

class ImageCropScreen extends StatefulWidget {
  final File imageFile;

  const ImageCropScreen({super.key, required this.imageFile});

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final _controller = CropController(
    aspectRatio: 1.0,
    defaultCrop: const Rect.fromLTRB(0.0, 0.0, 1.0, 1.0),
  );

  bool _isSaving = false;

  Future<void> _onCrop() async {
    setState(() => _isSaving = true);
    try {
      final ui.Image croppedImage = await _controller.croppedBitmap();
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List bytes = byteData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final fileName = 'cropped_${DateTime.now().millisecondsSinceEpoch}.png';
        final croppedFile = File(p.join(tempDir.path, fileName));
        await croppedFile.writeAsBytes(bytes);

        if (mounted) {
          Navigator.pop(context, croppedFile.path);
        }
        return;
      }
      if (mounted) {
        Navigator.pop(context, null);
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cropping image: $e'),
            backgroundColor: FocusFlowColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Crop Photo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right_rounded),
            onPressed: () => _controller.rotateRight(),
            tooltip: 'Rotate Right',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CropImage(
                    controller: _controller,
                    image: Image.file(widget.imageFile),
                    paddingSize: 20.0,
                    gridColor: Colors.white.withValues(alpha: 0.5),
                    gridCornerColor: FocusFlowColors.brand,
                    gridCornerSize: 20.0,
                    gridThinWidth: 1.0,
                    gridThickWidth: 2.5,
                  ),
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: FocusFlowColors.brand.withValues(alpha: 0.8),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _onCrop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FocusFlowColors.brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_isSaving ? 'Processing...' : 'Apply Crop'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
