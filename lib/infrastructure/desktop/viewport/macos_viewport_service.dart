import 'base_viewport_service.dart';

class MacOSViewportService extends BaseViewportService {
  MacOSViewportService({required super.logger})
      : super(platformLabel: 'macOS');
}
