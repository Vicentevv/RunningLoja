import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training/logic/kalman_filter.dart';

void main() {
  group('KalmanLatLong', () {
    test('Should initialize correctly', () {
      final filter = KalmanLatLong(10.0);
      final result = filter.process(0, 0, 5, 1000, 0);

      expect(result, [0.0, 0.0]);
    });

    test('Should reject inaccurate points', () {
      final filter = KalmanLatLong(10.0); // Max accuracy 10m

      // Good point
      var result = filter.process(0, 0, 5, 1000, 0);
      expect(result, isNotNull);

      // Bad point (Acc 20 > 10)
      result = filter.process(1, 1, 20, 2000, 0);
      expect(result, isNull);
    });

    test('Should smooth jittery points', () {
      final filter = KalmanLatLong(50.0);

      // Start at 0,0
      filter.process(0.0000, 0.0000, 5, 0, 0);

      // Sudden jump to 0.0002 (jitter) with bad accuracy
      // This is ~22 meters away. With accuracy 10m, filter should trust it somewhat but not fully jump
      final result = filter.process(0.0002, 0.0002, 10, 1000, 0);

      // Should be somewhere between 0.0 and 0.0002
      expect(result![0], greaterThan(0.0));
      expect(result[0], lessThan(0.0002));

      // Subsequent point back at 0.0000 (jitter back)
      final result2 = filter.process(0.0000, 0.0000, 5, 2000, 0);

      // Should be closer to 0 but smoothed
      expect(result2![0], lessThan(result[0]));
      expect(result2[0], greaterThan(0.0));
    });
  });
}
