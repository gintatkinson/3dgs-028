import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/physical_address.dart';

void main() {
  group('PhysicalAddress model', () {
    test('fromMap parses all fields from snake_case map', () {
      final map = {
        'address': '123 Tech Lane',
        'postal_code': '100-0001',
        'state': 'Tokyo',
        'city': 'Chiyoda',
        'country_code': 'JP',
      };
      final addr = PhysicalAddress.fromMap(map);

      expect(addr.address, equals('123 Tech Lane'));
      expect(addr.postalCode, equals('100-0001'));
      expect(addr.state, equals('Tokyo'));
      expect(addr.city, equals('Chiyoda'));
      expect(addr.countryCode, equals('JP'));
    });

    test('fromMap with empty map sets all fields to null', () {
      final map = <String, dynamic>{};
      final addr = PhysicalAddress.fromMap(map);

      expect(addr.address, isNull);
      expect(addr.postalCode, isNull);
      expect(addr.state, isNull);
      expect(addr.city, isNull);
      expect(addr.countryCode, isNull);
    });

    test('fromMap ignores unknown keys', () {
      final map = {
        'address': '456 Oak St',
        'extra_field': 'should be ignored',
      };
      final addr = PhysicalAddress.fromMap(map);

      expect(addr.address, equals('456 Oak St'));
      expect(addr.postalCode, isNull);
    });

    test('toMap includes only non-null fields', () {
      final addr = PhysicalAddress(
        city: 'Tokyo',
        countryCode: 'JP',
      );

      final map = addr.toMap();

      expect(map.containsKey('address'), isFalse);
      expect(map.containsKey('postal_code'), isFalse);
      expect(map.containsKey('state'), isFalse);
      expect(map['city'], equals('Tokyo'));
      expect(map['country_code'], equals('JP'));
    });

    test('toMap includes all fields when all are set', () {
      final addr = PhysicalAddress(
        address: '789 Pine Ave',
        postalCode: '90210',
        state: 'California',
        city: 'Beverly Hills',
        countryCode: 'US',
      );

      final map = addr.toMap();

      expect(map['address'], equals('789 Pine Ave'));
      expect(map['postal_code'], equals('90210'));
      expect(map['state'], equals('California'));
      expect(map['city'], equals('Beverly Hills'));
      expect(map['country_code'], equals('US'));
      expect(map.length, equals(5));
    });

    test('toMap round-trips through fromMap', () {
      final original = PhysicalAddress(
        address: '10 Downing Street',
        postalCode: 'SW1A 2AA',
        state: 'England',
        city: 'London',
        countryCode: 'GB',
      );

      final map = original.toMap();
      final restored = PhysicalAddress.fromMap(map);

      expect(restored.address, equals('10 Downing Street'));
      expect(restored.postalCode, equals('SW1A 2AA'));
      expect(restored.state, equals('England'));
      expect(restored.city, equals('London'));
      expect(restored.countryCode, equals('GB'));
    });

    test('toMap handles null countryCode without error', () {
      final addr = PhysicalAddress(
        address: 'Some Address',
        postalCode: null,
        state: null,
        city: 'Some City',
        countryCode: null,
      );

      final map = addr.toMap();
      expect(map['address'], equals('Some Address'));
      expect(map['city'], equals('Some City'));
      expect(map.containsKey('country_code'), isFalse);
    });

    test('isComplete returns true when all fields are set', () {
      final addr = PhysicalAddress(
        address: '1 Main St',
        postalCode: '12345',
        state: 'NY',
        city: 'New York',
        countryCode: 'US',
      );

      expect(addr.isComplete, isTrue);
    });

    test('isComplete returns false when any field is null', () {
      expect(
        PhysicalAddress(address: '1 Main St').isComplete,
        isFalse,
      );
      expect(
        PhysicalAddress(
          address: '1 Main St',
          postalCode: '12345',
          state: 'NY',
          city: 'New York',
          countryCode: null,
        ).isComplete,
        isFalse,
      );
    });

    test('isComplete returns false when all fields are null', () {
      final addr = PhysicalAddress();
      expect(addr.isComplete, isFalse);
    });

    test('const constructor allows compile-time instances', () {
      const addr = PhysicalAddress(city: 'Berlin', countryCode: 'DE');
      expect(addr.city, equals('Berlin'));
      expect(addr.countryCode, equals('DE'));
      expect(addr.address, isNull);
      expect(addr.postalCode, isNull);
      expect(addr.state, isNull);
    });
  });
}
