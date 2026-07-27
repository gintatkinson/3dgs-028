/// Physical address container for a network inventory location as defined
/// in the IETF NI-Location YANG grouping
/// (`nil:locations/location/physical-address`).
///
/// Captures the civic-address fields — street address, postal code, state/
/// region, city, and country code — enabling geocoding-free location
/// identification for network inventory entries.
///
/// All fields are optional per the YANG schema; absent fields are simply
/// not serialized. The [countryCode] field uses a two-letter uppercase
/// ISO 3166-1 alpha-2 pattern (`[A-Z]{2}`).
///
/// @realizes UML::PhysicalAddress
/// @realizes UML::NetworkInventoryLocation::physical-address (container)
class PhysicalAddress {
  /// Street address or building name line.
  final String? address;

  /// Postal or ZIP code for the location.
  final String? postalCode;

  /// State, province, or region name. May describe a non-administrative
  /// region per the YANG description text.
  final String? state;

  /// City, town, or locality name.
  final String? city;

  /// ISO 3166-1 alpha-2 country code (exactly two uppercase letters).
  ///
  /// Pattern constraint: `[A-Z]{2}` — lowercase, digits, and longer or
  /// shorter strings are rejected.
  final String? countryCode;

  /// Creates a new [PhysicalAddress] instance.
  ///
  /// All fields are optional, conforming to the YANG schema where no
  /// leaf in the `physical-address` container is mandatory.
  const PhysicalAddress({
    this.address,
    this.postalCode,
    this.state,
    this.city,
    this.countryCode,
  });

  /// Constructs a [PhysicalAddress] from a raw key-value database map.
  ///
  /// Field names use snake_case matching the YANG leaf names as stored
  /// in the database's `data_json` column. Fields not present in [map]
  /// are silently set to `null`.
  ///
  /// @param map The decoded `data_json` map from the `properties` table.
  /// @returns A typed [PhysicalAddress] with all parsed fields.
  factory PhysicalAddress.fromMap(Map<String, dynamic> map) {
    return PhysicalAddress(
      address: map['address'] as String?,
      postalCode: map['postal_code'] as String?,
      state: map['state'] as String?,
      city: map['city'] as String?,
      countryCode: map['country_code'] as String?,
    );
  }

  /// Serializes this [PhysicalAddress] to a map for JSON encoding.
  ///
  /// Only non-null fields are included in the output, matching YANG
  /// schema conventions where absent leaves are not present rather
  /// than null-valued.
  ///
  /// @returns A map with snake_case keys matching the database column names.
  Map<String, dynamic> toMap() {
    return {
      if (address != null) 'address': address,
      if (postalCode != null) 'postal_code': postalCode,
      if (state != null) 'state': state,
      if (city != null) 'city': city,
      if (countryCode != null) 'country_code': countryCode,
    };
  }

  /// Whether all five fields are present (non-null).
  ///
  /// A complete physical address has every field populated. Partial
  /// addresses are valid per schema but may be rejected by downstream
  /// geocoding services that expect a full civic address.
  ///
  /// @realizes UML::PhysicalAddress::isComplete
  bool get isComplete =>
      address != null &&
      postalCode != null &&
      state != null &&
      city != null &&
      countryCode != null;
}
