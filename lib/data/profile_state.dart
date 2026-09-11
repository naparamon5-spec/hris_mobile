import 'package:flutter/foundation.dart';

/// Shared state for the current user's profile photo. Holds the cropped image
/// as PNG bytes so every avatar (dashboard top bar, profile hero) updates at
/// once when a new photo is uploaded.
class ProfileState extends ChangeNotifier {
  ProfileState._();
  static final ProfileState instance = ProfileState._();

  Uint8List? _photo;

  Uint8List? get photo => _photo;
  bool get hasPhoto => _photo != null;

  void setPhoto(Uint8List bytes) {
    _photo = bytes;
    notifyListeners();
  }

  void clearPhoto() {
    _photo = null;
    notifyListeners();
  }
}
