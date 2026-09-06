import 'package:window_manager/window_manager.dart';

import 'base_viewport_service.dart';

class LinuxViewportService extends BaseViewportService {
  LinuxViewportService({required super.logger})
      : super(
          platformLabel: 'Linux',
          alwaysOnTop: false,
          skipTaskbar: false,
          hideOnStartup: false,
          hideOnBlur: false,
          preventClose: false,
          focusOnShow: true,
          hideWindowAfterItemActivation: false,
          minimizeAfterItemActivation: true,
          titleBarStyle: TitleBarStyle.hidden,
          windowButtonVisibility: false,
        );
}
