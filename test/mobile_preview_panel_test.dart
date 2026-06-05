import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movilcontrol/app/data/enums/bluetooth_output_mode.dart';
import 'package:movilcontrol/app/modules/home/widgets/home_presentation_models.dart';
import 'package:movilcontrol/app/modules/home/widgets/home_widget_support.dart';
import 'package:movilcontrol/app/modules/home/widgets/mobile_preview_panel.dart';

void main() {
  testWidgets(
    'camera switch button stays hidden when there is no alternate camera',
    (tester) async {
      await tester.pumpWidget(
        _buildPreviewPanel(
          canSwitchCamera: false,
          isSwitchingCamera: false,
          onToggleCamera: () {},
        ),
      );

      expect(find.byKey(const Key('camera-switch-button')), findsNothing);
    },
  );

  testWidgets(
    'camera switch button appears and triggers callback when available',
    (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        _buildPreviewPanel(
          canSwitchCamera: true,
          isSwitchingCamera: false,
          onToggleCamera: () {
            tapCount++;
          },
        ),
      );

      expect(find.byKey(const Key('camera-switch-button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('camera-switch-button')));
      await tester.pump();

      expect(tapCount, 1);
    },
  );
}

Widget _buildPreviewPanel({
  required bool canSwitchCamera,
  required bool isSwitchingCamera,
  required VoidCallback onToggleCamera,
}) {
  return MaterialApp(
    home: Scaffold(
      body: MobilePreviewPanel(
        cameraController: null,
        cameraWaitingMessage: 'Esperando camara...',
        handStatusViewModel: HandStatusViewModel(
          summary: 'Mano cerrada',
          cameraStatusLabel: 'Camara lista',
          cameraTone: HomeTone.good,
          cameraSummary: 'Camara lista',
          mobileCameraInfoMessage: '',
          fingerCount: 0,
          commandLabel: 'Adelante',
          payloadLabel: 'F',
          packetLabel: '12:00:00',
        ),
        bluetoothStatusViewModel: BluetoothStatusViewModel(
          isConnected: true,
          isMockMode: true,
          outputMode: BluetoothOutputMode.autoVirtual,
          isManualBuzzerControlEnabled: false,
          lastCommandLabel: 'Adelante',
          lastPayload: 'F',
          connectedDeviceName: '',
          connectedDeviceAddress: null,
          selectedDeviceName: '',
          selectedDeviceAddress: null,
          errorMessage: '',
          isLoadingDevices: false,
          deviceOptions: const <BluetoothDeviceOptionViewModel>[],
        ),
        canSwitchCamera: canSwitchCamera,
        isSwitchingCamera: isSwitchingCamera,
        cameraLensLabel: 'Camara trasera',
        onToggleCamera: onToggleCamera,
      ),
    ),
  );
}
