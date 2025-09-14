import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcam/main.dart';
// import 'package:smartcam/main.dart'; // Ensure this matches your project name
// If MyApp is not exported from main.dart, export or define it there.

void main() {
  // A mock camera description to use in our tests
  const mockCamera = CameraDescription(
    name: '0',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 90,
  );

  group('App Startup Tests', () {
    testWidgets('Shows CameraScreen when cameras are available', (WidgetTester tester) async {
      // Build our app and provide it with the mock camera.
      await tester.pumpWidget(MyApp(cameras: [mockCamera]));

      // Wait for any loading indicators to disappear.
      await tester.pumpAndSettle();

      // Verify that the main camera UI is visible by looking for the mode buttons.
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Translate'), findsOneWidget);
      expect(find.text('QR Scan'), findsOneWidget);
    });

    testWidgets('Shows NoCameraAvailableScreen when no cameras are found', (WidgetTester tester) async {
      // Build our app and provide it with an EMPTY list of cameras.
      await tester.pumpWidget(const MyApp(cameras: []));

      // Verify that our "no camera" error screen is shown.
      expect(find.text('No cameras available on this device.'), findsOneWidget);

      // Verify that the camera UI (like the 'Photo' button) is NOT visible.
      expect(find.text('Photo'), findsNothing);
    });
  });
}