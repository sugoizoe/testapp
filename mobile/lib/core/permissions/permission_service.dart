import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> ensureCameraAndMic() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    return statuses.values.every((s) => s.isGranted);
  }

  Future<bool> ensureLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<bool> ensurePhotos() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }
}

