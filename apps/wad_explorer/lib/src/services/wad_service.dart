
import 'package:doom_wad/doom_wad.dart';
import 'package:flutter/foundation.dart';

class WadService extends ChangeNotifier {
  WadManager? _wadManager;
  String? _fileName;

  WadManager? get wadManager => _wadManager;
  String? get fileName => _fileName;
  bool get isLoaded => _wadManager != null;

  void loadWad(Uint8List bytes, String fileName) {
    _wadManager = WadManager()..addWad(bytes);
    _fileName = fileName;
    notifyListeners();
  }

  void closeWad() {
    _wadManager = null;
    _fileName = null;
    notifyListeners();
  }

  Uint8List? readLump(int index) {
    if (_wadManager == null) return null;
    try {
      return _wadManager!.readLump(index);
    } catch (e) {
      return null;
    }
  }

  LumpInfo? getLumpInfo(int index) {
    if (_wadManager == null) return null;
    try {
      return _wadManager!.getLumpInfo(index);
    } catch (e) {
      return null;
    }
  }

  int get numLumps => _wadManager?.numLumps ?? 0;
}
