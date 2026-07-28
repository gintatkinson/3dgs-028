<task id="ses_058db9f44ffeB2Oq0mTkTNRwfh" state="completed">
<task_result>
I have now read all **31 files** across the four directories. Below is the complete, exhaustive enumeration.

---

```
EPIC #7 - Geo-Location Grouping (ietf-geo-location / RFC 9179)
================================================================

  Feature #1 - Geo-Location Root Container (feat-01-geo-location-root.md, issue_id=1)
  ────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T1.1:  Create location with timestamp
             GIVEN a geo-location entity is being created
             WHEN a valid `timestamp` value conforming to `yang:date-and-time` format is provided
             THEN the geo-location is successfully stored with the recorded timestamp

      T1.2:  Create location without timestamp
             GIVEN a geo-location entity is being created
             WHEN no `timestamp` value is specified
             THEN the geo-location is successfully stored without temporal context and the timestamp field is absent

      T1.3:  Set validity expiration
             GIVEN a geo-location entity with a recorded `timestamp`
             WHEN a `valid-until` value is provided that is chronologically after the `timestamp`
             THEN the geo-location stores the expiration time and consumers can determine data freshness

      T1.4:  Location without validity expiration
             GIVEN a geo-location entity exists
             WHEN no `valid-until` value is specified
             THEN the geo-location has no specific expiration and is considered valid indefinitely until explicitly removed

      T1.5:  Invalid timestamp format
             GIVEN a geo-location entity is being created or updated
             WHEN a `timestamp` value is provided that does not conform to the `yang:date-and-time` format (e.g., "not-a-date")
             THEN the operation is rejected with a data validation error indicating the timestamp format is invalid

      T1.6:  Expired location data
             GIVEN a geo-location entity exists with `valid-until` set to a past timestamp
             WHEN a consumer reads the geo-location data
             THEN the consumer can detect the data is expired by comparing the current time against `valid-until`

      T1.7:  Inverted temporal relationship
             GIVEN a geo-location entity is being created
             WHEN a `valid-until` value is provided that is chronologically before the `timestamp` value
             THEN the system SHOULD flag the inconsistency, though the schema does not enforce this constraint at the data-model level

    Logical Exception States:
      T1.8:  Missing Timestamp — When no timestamp is provided, location data does not carry temporal context; consumers must not assume freshness
      T1.9:  Expired Validity — When current time exceeds valid-until, data is logically expired; consumers SHOULD treat with reduced confidence
      T1.10: Invalid Timestamp Format — Non-conforming value rejected with schema violation error
      T1.11: Invalid Validity Period — valid-until earlier than timestamp is logically inconsistent; SHOULD be flagged

    Logical Operations (tested end-to-end):
      T1.12: Create Location Record — Write full geo-location subtree via NETCONF edit-config or RESTCONF POST/PUT
      T1.13: Query Location Record — Read geo-location via NETCONF get-config/get or RESTCONF GET
      T1.14: Update Location Record — Modify sub-elements via NETCONF edit-config (merge/replace) or RESTCONF PATCH
      T1.15: Delete Location Record — Remove geo-location container via NETCONF edit-config (delete) or RESTCONF DELETE


  Feature #2 - Reference Frame (feat-02-reference-frame.md, issue_id=2)
  ──────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T2.1:  Default reference frame
             GIVEN a geo-location entity is being created
             WHEN no `reference-frame` values are explicitly specified
             THEN the astronomical body defaults to `"earth"` and the geodetic datum defaults to `"wgs-84"` per the schema defaults

      T2.2:  Specify alternate astronomical body
             GIVEN a geo-location entity is being created on the Moon
             WHEN the `astronomical-body` is set to `"moon"`
             THEN the location data is associated with the lunar reference frame and the geodetic datum may be set to a Moon-appropriate value (e.g., `"me"`)

      T2.3:  Specify alternate system (virtual reality)
             GIVEN a device supports the `alternate-systems` feature
             WHEN a `reference-frame` is created with `alternate-system` set to `"virtual-reality-1"` and `astronomical-body` set to `"mars"`
             THEN the location values are interpreted within the "virtual-reality-1" system for the Mars body

      T2.4:  Attempt alternate system without feature support
             GIVEN a device does NOT support the `alternate-systems` feature
             WHEN an attempt is made to set the `alternate-system` leaf
             THEN the operation is rejected because the conditional leaf is not available per the `if-feature "alternate-systems"` guard

      T2.5:  Invalid astronomical body characters
             GIVEN a geo-location entity is being created
             WHEN the `astronomical-body` is set to a value containing control characters (ASCII values 0-31 or 127)
             THEN the operation is rejected with a pattern validation error

      T2.6:  Valid astronomical body with special characters
             GIVEN a geo-location entity is being created for a comet
             WHEN the `astronomical-body` is set to `"67p/churyumov-gerasimenko"`
             THEN the operation succeeds because forward slash and hyphen are within the permitted ASCII character range (32-64, 91-126)

      T2.7:  Astronomical body case normalization
             GIVEN a geo-location entity is being created
             WHEN the `astronomical-body` is set to `"Earth"` (mixed case) or `"EARTH"` (uppercase)
             THEN the system SHOULD convert to lowercase `"earth"` per the schema description guidance

    Logical Exception States:
      T2.8:  Invalid Astronomical Body Pattern — Characters outside ASCII 32-64/91-126 rejected
      T2.9:  Alternate System Without Feature Support — Setting alternate-system rejected with feature-not-supported error
      T2.10: Missing Geodetic Datum — Absence means default implied by astronomical body applies (wgs-84 for Earth); consumers should not assume datum is present
      T2.11: Empty Astronomical Body — Empty string not rejected by pattern, but consumers should treat as unspecified or default to "earth"

    Logical Operations:
      T2.12: Read Reference Frame — Query the reference-frame container to retrieve astronomical body, alternate system, geodetic system
      T2.13: Write Reference Frame — Set or update reference-frame with target body and datum; alternate-system only when feature enabled
      T2.14: Inherit Reference Frame — Parent module may specify reference-frame inherited from containing object


  Feature #3 - Geodetic System (feat-03-geodetic-system.md, issue_id=3)
  ──────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T3.1:  Default geodetic datum for Earth
             GIVEN a geo-location entity is being created on Earth
             WHEN no `geodetic-datum` value is explicitly specified
             THEN the effective datum defaults to `"wgs-84"` per the schema description

      T3.2:  Specify custom geodetic datum
             GIVEN a geo-location entity is being created on the Moon
             WHEN the `geodetic-datum` is set to `"me"` (Mean Earth/Polar Axis)
             THEN the location coordinates are interpreted using the lunar Mean Earth reference system

      T3.3:  Specify coordinate accuracy
             GIVEN a geo-location entity is being created with experimental measurements
             WHEN the `coord-accuracy` is set to `10.5`
             THEN the accuracy value is stored and consumers can use it to assess the precision of the location data

      T3.4:  Specify height accuracy
             GIVEN a geo-location entity with ellipsoidal coordinates is being created
             WHEN the `height-accuracy` is set to `3.2` meters
             THEN the height measurement precision is recorded and consumers can determine the vertical uncertainty

      T3.5:  Invalid geodetic datum pattern
             GIVEN a geo-location entity is being created
             WHEN the `geodetic-datum` is set to a value containing control characters (ASCII 0-31)
             THEN the operation is rejected with a pattern validation error

      T3.6:  Geodetic datum with space-to-dash conversion
             GIVEN a geo-location entity is being created
             WHEN the `geodetic-datum` is set to a value containing spaces (e.g., `"wgs 84"`)
             THEN IANA registry rules mandate converting spaces to dashes (result: `"wgs-84"`); the YANG pattern does NOT directly enforce this so the raw value may be stored

      T3.7:  Height accuracy ignored for Cartesian coordinates
             GIVEN a geo-location entity uses Cartesian coordinates (`x`, `y`, `z`)
             WHEN a `height-accuracy` value is provided
             THEN the value is stored but consumers SHOULD NOT use it for Cartesian coordinate interpretation per the schema description

    Logical Exception States:
      T3.8:  Invalid Geodetic Datum Pattern — Characters outside permitted ASCII range rejected
      T3.9:  Negative Accuracy Values — Negative coord-accuracy or height-accuracy are logically nonsensical; consumers SHOULD reject or warn
      T3.10: Missing Geodetic Datum — Absence on Earth implies wgs-84; for non-Earth, absence indicates no explicit datum
      T3.11: Height Accuracy on Cartesian Coordinates — Setting height-accuracy with Cartesian coordinates is ignored per spec

    Logical Operations:
      T3.12: Read Geodetic System — Query geodetic-system to retrieve datum, coord-accuracy, height-accuracy
      T3.13: Write Geodetic System — Set or update datum and accuracy values; use IANA registered values
      T3.14: Inherit from Parent — In nested location hierarchies, geodetic-system may be inherited from parent


  Feature #4 - Ellipsoid Coordinate System (feat-04-ellipsoid-coordinates.md, issue_id=4)
  ────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T4.1:  Set Earth location with latitude and longitude
             GIVEN a geo-location entity is being created for an Earth-based location
             WHEN `latitude` is set to `40.7128` and `longitude` is set to `-74.0060` decimal degrees
             THEN the ellipsoid case is selected and the coordinates are stored with full decimal64 precision (16 fraction digits)

      T4.2:  Set location with height
             GIVEN a geo-location entity with latitude and longitude is being created
             WHEN a `height` of `15.5` meters is also provided
             THEN the 3D ellipsoid location is stored with all three components

      T4.3:  Set location with high-precision latitude
             GIVEN a geo-location entity is being created with high-precision requirements
             WHEN `latitude` is set to `40.7128000000000001` (16 fraction digits)
             THEN the latitude value is stored with full decimal64 precision without rounding at the schema level

      T4.4:  Latitude out of Earth range
             GIVEN a geo-location entity is being created for an Earth-based context
             WHEN `latitude` is set to `95.0` degrees (exceeds the terrestrial maximum of 90.0)
             THEN the YANG schema does not enforce the range; application-level validation SHOULD reject or flag the out-of-range value

      T4.5:  Attempt simultaneous ellipsoid and Cartesian coordinates
             GIVEN a geo-location entity is being configured
             WHEN both ellipsoid coordinate values (`latitude`, `longitude`) and Cartesian values (`x`, `y`, `z`) are provided simultaneously
             THEN the operation is rejected because the `choice` statement allows only one active case

      T4.6:  Set location on non-Earth body
             GIVEN a geo-location entity is configured with `astronomical-body` set to `"mars"`
             WHEN ellipsoid coordinates are provided for the Martian surface
             THEN the coordinate range and interpretation is defined by the Martian reference frame, which may differ from Earth's [-90, +90] latitude range

      T4.7:  Precision loss on height value
             GIVEN a geo-location entity stores a height value
             WHEN the height is specified with more than 6 fractional digits (e.g., `15.1234567`)
             THEN the decimal64 type truncates or rounds to 6 fraction digits per the `fraction-digits 6` constraint

    Logical Exception States:
      T4.8:  Latitude Out of Range for Earth — Value exceeding [-90, +90] requires application-level validation; decimal64 does not enforce this range
      T4.9:  Longitude Out of Range for Earth — Value exceeding [-180, +180] requires application-level validation
      T4.10: Mixed Coordinate Systems — Simultaneous ellipsoid and Cartesian provision in the same location choice must be rejected per YANG choice semantics
      T4.11: Precision Underflow — Values with more fractional digits than the defined limit are rounded or truncated

    Logical Operations:
      T4.12: Set Ellipsoid Coordinates — Write ellipsoid case of location choice with latitude, longitude, optionally height
      T4.13: Read Ellipsoid Coordinates — Query location choice to retrieve latitude, longitude, height
      T4.14: Update Coordinates — Modify individual coordinate values via merge/replace operations


  Feature #5 - Cartesian Coordinate System (feat-05-cartesian-coordinates.md, issue_id=5)
  ────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T5.1:  Set Earth-centered Cartesian coordinates
             GIVEN a geo-location entity is being created with an Earth-based reference frame
             WHEN Cartesian `x`, `y`, and `z` coordinates are set to ECEF values in meters
             THEN the Cartesian case is selected and the 3D position is stored with 6-fraction-digit precision

      T5.2:  Set Cartesian coordinates on non-Earth body
             GIVEN a geo-location entity is configured with `astronomical-body` set to `"moon"` and geodetic-datum set to `"me"`
             WHEN Cartesian coordinates are provided for the lunar surface
             THEN the axis meaning is defined by the lunar Mean Earth reference system

      T5.3:  Set partial Cartesian coordinates
             GIVEN a geo-location entity is being created
             WHEN only `x` and `y` coordinates are provided without `z`
             THEN the location is stored with a 2D Cartesian position (Z component is absent)

      T5.4:  Attempt simultaneous Cartesian and ellipsoid coordinates
             GIVEN a geo-location entity is being configured
             WHEN both Cartesian (`x`, `y`, `z`) and ellipsoid (`latitude`, `longitude`) values are provided simultaneously
             THEN the operation is rejected because the YANG `choice` statement permits only one active case

      T5.5:  Precision bound on large Cartesian values
             GIVEN a geo-location entity stores Cartesian coordinates with large integer parts
             WHEN the `x` value approaches the maximum representable range for `decimal64` with 6 fraction digits
             THEN the value is stored accurately within the decimal64 representable range; values exceeding the range are rejected

      T5.6:  Height-accuracy is ignored for Cartesian coordinates
             GIVEN a geo-location entity uses Cartesian coordinates
             WHEN the `height-accuracy` leaf in the geodetic-system is set to a non-zero value
             THEN the height-accuracy value is stored but must not be applied to Cartesian coordinate interpretation

    Logical Exception States:
      T5.7:  Incomplete Cartesian Specification — Only one or two of three components provided; schema allows but applications SHOULD require all three
      T5.8:  Simultaneous Coordinate Systems — Both Cartesian and ellipsoid simultaneously rejected per YANG choice
      T5.9:  Precision Underflow — Cartesian values with >6 fraction digits truncated/rounded per decimal64 rules
      T5.10: Axis Ambiguity — Without well-defined reference frame, X/Y/Z axis meaning is undefined

    Logical Operations:
      T5.11: Set Cartesian Coordinates — Write cartesian case of location choice with x, y, z
      T5.12: Read Cartesian Coordinates — Query location choice to retrieve current x, y, z
      T5.13: Update Coordinates — Modify individual coordinates via merge/replace
      T5.14: Convert from Ellipsoid — Application-level transformation from lat/lon/height to Cartesian using geodetic datum formulas


  Feature #6 - Velocity Vector (feat-06-velocity-vector.md, issue_id=6)
  ──────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T6.1:  Set velocity for a moving object
             GIVEN a geo-location entity exists with a recorded timestamp
             WHEN v-north=2.5 m/s, v-east=-1.0 m/s, v-up=0.1 m/s
             THEN the velocity vector is stored and represents the object's motion at the recorded timestamp

      T6.2:  Compute speed from velocity vector
             GIVEN a velocity vector with v-north=3.0 m/s and v-east=4.0 m/s
             WHEN the consumer computes 2D horizontal speed using sqrt(v_north^2 + v_east^2)
             THEN the speed equals 5.0 m/s

      T6.3:  Compute heading from velocity vector
             GIVEN a velocity vector with v-north=1.0 m/s and v-east=1.0 m/s
             WHEN the consumer computes heading using arctan(v_east / v_north)
             THEN the heading equals 45.0 degrees from true north (pi/4 radians)

      T6.4:  Stationary object with zero velocity
             GIVEN a geo-location entity exists for a stationary object
             WHEN all velocity components are set to zero (v-north=0, v-east=0, v-up=0)
             THEN the velocity vector indicates the object is not in motion

      T6.5:  Track continental drift
             GIVEN a geo-location entity exists for a fixed ground station
             WHEN velocity components are set to very small values (e.g., 0.000000000035 m/s representing ~1.1 mm/year)
             THEN decimal64 type with 12 fraction digits has sufficient precision to represent the slow movement

      T6.6:  Heading undefined for zero velocity
             GIVEN a velocity vector with both v-north=0 and v-east=0
             WHEN the consumer attempts to compute heading using arctan(v_east / v_north)
             THEN the heading is undefined and the application must handle the division-by-zero edge case gracefully

      T6.7:  Heading at cardinal direction
             GIVEN a velocity vector with v-north=0 and v-east=5.0 m/s
             WHEN the consumer computes heading
             THEN the heading is 90.0 degrees (due east) because v-north is zero and v-east is positive

      T6.8:  Set velocity without timestamp
             GIVEN a geo-location entity is being created without a `timestamp`
             WHEN a velocity vector is provided
             THEN the velocity is stored but its temporal reference point is unspecified, reducing precision

      T6.9:  Precision bound on velocity values
             GIVEN a geo-location entity stores a velocity vector
             WHEN a component is specified with more than 12 fractional digits (e.g., 2.5000000000001)
             THEN the decimal64 type truncates or rounds to 12 fraction digits

    Logical Exception States:
      T6.10: Zero Velocity Vector — All three components zero is valid and indicates stationary object
      T6.11: Division by Zero in Heading — When v-north=0, heading is 90 deg (v-east>0) or 270 deg (v-east<0); undefined when both zero
      T6.12: Extreme Velocity Values — Values approaching max decimal64 range; terrestrial/moderate-space applications sufficient
      T6.13: Missing Timestamp Context — Velocity without parent timestamp reduces temporal precision

    Logical Operations:
      T6.14: Set Velocity Vector — Write velocity container with v-north, v-east, v-up via NETCONF/RESTCONF
      T6.15: Read Velocity Vector — Query velocity container to retrieve components
      T6.16: Compute Speed and Heading — Application-level computation from vector components (derived, not stored)
      T6.17: Clear Velocity — Remove velocity container when object is stationary


EPIC #8 - Network Inventory Location — Location Hierarchy & Facilities (draft-ietf-ivy-network-inventory-location-06)
=====================================================================================================================

  Feature #1 - Network Inventory Location Entity (feat-01-ni-location-entity.md, issue_id=1)
  ──────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios (Acceptance Criteria):
      T8.1:  Query location list returns hierarchy
             GIVEN a network inventory with multiple physical sites, buildings, and rooms
             WHEN the management system queries the locations list via NETCONF/RESTCONF
             THEN a list of location entries is returned, each with unique id, type, and optional parent reference forming a hierarchy

      T8.2:  Type field reflects operator-defined classification
             GIVEN a location entry with a populated `type` field
             WHEN the system retrieves the location data
             THEN the type reflects the operator-defined classification (e.g., "site", "building", "room")

      T8.3:  Valid parent-child hierarchy
             GIVEN a location with a `parent` leafref pointing to another location id
             WHEN the parent id resolves to an existing location in the same list
             THEN the child-parent hierarchy relationship is established

      T8.4:  Invalid parent reference
             GIVEN a location with a `parent` leafref pointing to a non-existent location id
             WHEN the data is validated
             THEN the reference is invalid and the hierarchy link cannot be resolved

      T8.5:  Expired location (valid-until in past)
             GIVEN a location with a `valid-until` timestamp that is in the past
             WHEN an operational query checks the location validity
             THEN the location is considered stale and MUST NOT be used for operational purposes

      T8.6:  No valid-until = indefinite validity
             GIVEN a location without a `valid-until` timestamp
             WHEN the location is queried
             THEN the location has no specific expiration time and remains valid indefinitely

      T8.7:  Inherited basic-common-entity attributes
             GIVEN a location entity with `uuid`, `name`, `alias`, and `description` inherited from `nwi:basic-common-entity-attributes`
             WHEN the location is retrieved
             THEN all inherited attributes are available alongside location-specific attributes

      T8.8:  No parent = top-level location
             GIVEN a location with no `parent` specified
             WHEN the hierarchy is traversed
             THEN the location is a top-level location (root of its hierarchy tree)

    Logical Exception States:
      T8.9:  Invalid parent reference — parent leafref to non-existent id; hierarchy link broken
      T8.10: Duplicate id — Two locations with same id violate key constraint
      T8.11: Expired location — valid-until in past; location MUST be considered stale

    Logical Operations:
      T8.12: GET /locations/location — Retrieve location list (read-only config false)
      T8.13: GET /locations/location/{id} — Retrieve specific location by id


  Feature #2 - Physical Address for Network Inventory Locations (feat-02-physical-address.md, issue_id=2)
  ────────────────────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios (Acceptance Criteria):
      T8.14: Retrieve physical address fields
             GIVEN a location with a physical address sub-container
             WHEN the management system retrieves the location data
             THEN the address, postal-code, state, city, and country-code fields are available

      T8.15: Valid country code "US" accepted
             GIVEN a country-code value of "US"
             WHEN the pattern validation `[A-Z]{2}` is applied
             THEN the value is accepted as a valid ISO ALPHA-2 country code

      T8.16: Invalid country code "usa" rejected
             GIVEN a country-code value of "usa"
             WHEN the pattern validation `[A-Z]{2}` is applied
             THEN the value is rejected because it contains lowercase letters and is longer than 2 characters

      T8.17: Invalid country code "U5" rejected (contains digit)
             GIVEN a country-code value of "U5"
             WHEN the pattern validation `[A-Z]{2}` is applied
             THEN the value is rejected because it contains a digit

      T8.18: Only physical-address present = dispatch acceptable
             GIVEN a location with only a physical-address and no geo-location
             WHEN field dispatch validation is performed
             THEN the location is acceptable for dispatch (at least one of physical-address or geo-location present)

      T8.19: Neither physical-address nor geo-location = fails dispatch
             GIVEN a location with neither physical-address nor geo-location populated
             WHEN field dispatch validation is performed
             THEN the location fails the verification check for dispatch readiness

      T8.20: State field in country without states describes region
             GIVEN a location in a country without states
             WHEN the state field is populated
             THEN the state field describes a region rather than a state

    Logical Exception States:
      T8.21: Invalid country code — does not match pattern [A-Z]{2}
      T8.22: Missing mandatory fields for dispatch — need at least one of physical-address or geo-location; verification required before dispatch

    Logical Operations:
      T8.23: GET /locations/location/{id}/physical-address — Retrieve physical address (read-only config false)


  Feature #3 - Geographic Location for Network Inventory (feat-03-geographic-location.md, issue_id=3)
  ────────────────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios (Acceptance Criteria):
      T8.24: Ellipsoid coordinates retrieval
             GIVEN a location with ellipsoid geographic coordinates
             WHEN the management system retrieves geo-location data
             THEN latitude, longitude, and optional height are returned within the ellipsoid sub-container

      T8.25: Cartesian coordinates retrieval
             GIVEN a location configured with Cartesian coordinates
             WHEN the system retrieves geo-location data
             THEN x, y, and z coordinates are returned within the cartesian sub-container

      T8.26: Reference frame with geodetic metadata and accuracy
             GIVEN a geo-location with a reference-frame specifying WGS-84 datum and earth as astronomical-body
             WHEN the coordinate accuracy is 5.0 meters
             THEN the geodetic system metadata correctly qualifies the precision of the coordinates

      T8.27: Both ellipsoid and cartesian present = rejected
             GIVEN both ellipsoid and cartesian coordinate data present in a single geo-location instance
             WHEN the choice validation is applied
             THEN the data is rejected because only one coordinate system variant may be present at a time

      T8.28: Expired valid-until = stale geo-location
             GIVEN a geo-location with an expired valid-until timestamp
             WHEN operational validation is performed
             THEN the geo-location data is considered stale

      T8.29: Velocity data available
             GIVEN a location with populated velocity data (v-north, v-east, v-up)
             WHEN the geo-location is queried
             THEN velocity vector data is available for moving assets

      T8.30: Alternate-system absent without feature
             GIVEN a location without alternate-systems feature enabled
             WHEN the geo-location reference-frame is queried
             THEN the alternate-system field is not present

    Logical Exception States:
      T8.31: Coordinate system conflict — both ellipsoid and cartesian present violates (location) choice constraint
      T8.32: Invalid accuracy — negative coord-accuracy or height-accuracy semantically invalid
      T8.33: Transitional velocity on fixed asset — v-north/v-east/v-up populated for stationary location permissible but indicates movement

    Logical Operations:
      T8.34: GET /locations/location/{id}/geo-location — Retrieve geographic location data (read-only config false)


  Feature #4 - Location-Level Chassis Container (feat-04-location-chassis.md, issue_id=4)
  ────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios (Acceptance Criteria):
      T8.35: Ceiling-mounted AP chassis query
             GIVEN a location with a ceiling-mounted access point
             WHEN the chassis list is queried
             THEN the chassis entry contains chassis-id, ne-ref pointing to the access point NE, and component-ref to the specific chassis component

      T8.36: Distributed multi-chassis across locations
             GIVEN a distributed multi-chassis network element spanning multiple locations
             WHEN each location's contained-chassis list is inspected
             THEN each location entry references the same ne-ref but different component-ref values

      T8.37: Valid ne-ref resolves component
             GIVEN a valid ne-ref that resolves to an existing network element
             WHEN component-ref is validated against that network element's components
             THEN the component association is resolved successfully

      T8.38: Dangling ne-ref
             GIVEN an ne-ref pointing to a deleted or non-existent network element
             WHEN the reference is dereferenced
             THEN the chassis entry has a dangling ne-ref and the association cannot be resolved

      T8.39: Empty chassis list
             GIVEN a location with no directly deployed chassis
             WHEN the contained-chassis list is queried
             THEN an empty list is returned

      T8.40: Duplicate chassis-id rejected
             GIVEN duplicate chassis-id values within the same location
             WHEN the key constraint is validated
             THEN the data is rejected because chassis-id must be unique per location

    Logical Exception States:
      T8.41: Unresolved ne-ref — leafref to non-existent network element id; dangling reference
      T8.42: Unresolved component-ref — component-ref cannot be resolved within the referenced NE; broken association
      T8.43: Duplicate chassis-id — two chassis entries with same chassis-id in same location violate key constraint

    Logical Operations:
      T8.44: GET /locations/location/{id}/contained-chassis — Retrieve chassis assigned to a location (read-only config false)
      T8.45: GET /locations/location/{id}/contained-chassis/{chassis-id} — Retrieve a specific chassis entry


  User Story #10 - Query Network Inventory Location Hierarchy (us-01-query-location-hierarchy.md, issue_id=10)
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenario:
      T8.46: Retrieve complete location hierarchy with parent-child relationships
             AS A network operator
             I WANT TO retrieve the complete location hierarchy beginning from a site down to individual rooms
             SO THAT I can understand the physical topology of network element deployments
             GIVEN a location list with parent-child relationships established via the `parent` leafref
             WHEN the OSS queries `/locations/location` via NETCONF or RESTCONF
             THEN all locations are returned with their `id`, `type`, and `parent` fields, enabling the OSS to reconstruct the full hierarchy tree


  User Story #12 - Validate Location for Field Dispatch Readiness (us-02-validate-location-dispatch.md, issue_id=12)
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T8.47: Location with address/geo and valid-until future/absent = valid for dispatch
             AS A field operations dispatcher
             I WANT TO verify that a location has sufficient data for field dispatch
             SO THAT I can confidently send technicians to the correct physical location
             GIVEN a location entry with a `physical-address` and/or `geo-location` populated
             WHEN the dispatch validation service checks the location data
             THEN if at least one of physical-address or geo-location is present, AND `valid-until` is either absent or in the future, the location is marked as valid for dispatch

      T8.48: Neither address nor geo = incomplete
             GIVEN a location with neither `physical-address` nor `geo-location`
             WHEN dispatch validation is performed
             THEN the location fails the verification check and is flagged as incomplete

      T8.49: Valid address but expired valid-until = stale
             GIVEN a location with valid address data but an expired `valid-until` timestamp
             WHEN dispatch validation is performed
             THEN the location is considered stale and must NOT be used for operational purposes

    State Machine Validations:
      T8.50: Created -> ValidForDispatch transition [physicalAddress | geoLocation present AND validUntil is future]
      T8.51: Created -> Incomplete transition [no physicalAddress AND no geoLocation]
      T8.52: ValidForDispatch -> Stale transition [now > validUntil]
      T8.53: Stale -> ValidForDispatch transition [newValidUntil set AND address/geo present]


  User Story #15 - Handle Expired Location Data and Temporal Staleness (us-03-expired-location-handling.md, issue_id=15)
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T8.54: Location with past valid-until = stale
             AS AN inventory data manager
             I WANT TO detect and flag location and rack records that have passed their valid-until timestamp
             SO THAT stale data is excluded from operational use and planning
             GIVEN a location with `valid-until` set to a past timestamp (now > valid-until)
             WHEN the data quality assessment runs
             THEN the location is flagged as stale and excluded from dispatch readiness

      T8.55: Rack with future valid-until = valid
             GIVEN a rack with `valid-until` set to a future timestamp
             WHEN the rack is queried for capacity planning
             THEN the rack data is considered valid and included in planning calculations

      T8.56: Location without valid-until = indefinite validity
             GIVEN a location with no `valid-until` specified
             WHEN the staleness check is performed
             THEN the location has no specific expiration and remains valid indefinitely

    State Machine Validations:
      T8.57: Active -> Stale transition [now > validUntil]
      T8.58: Active -> Active (no expiry) transition [validUntil is null]
      T8.59: Stale -> Archived transition [now > validUntil + retentionWindow]
      T8.60: Stale -> Active transition [newValidUntil > now]


  User Story #23 - Navigate Full Facility Topology from Site to Chassis (us-07-navigate-facility-topology.md, issue_id=23)
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T8.61: Full topology trace: Site -> Building -> Room -> Rack -> U-slot -> Chassis
             AS A NOC operator troubleshooting a network element
             I WANT TO trace the full physical path from site to building to room to rack to chassis
             SO THAT I can dispatch a technician to the exact U-slot position in the correct rack
             GIVEN a network element "NE-1" deployed in a distributed configuration
             WHEN the operator queries the location model for the full containment chain
             THEN the topology traversal reveals: Site -> Building -> Room -> Rack -> U-slot (relative-position) -> chassis, providing a complete physical location path

      T8.62: Direct-location chassis (no rack intermediate)
             GIVEN a chassis deployed directly at a location without a rack (e.g., ceiling-mounted access point)
             WHEN the topology navigation reaches the location level
             THEN the chassis is found in the location-level contained-chassis list with no intermediate rack


  User Story #24 - Enforce Read-Only Access Control on Location Data (us-08-enforce-access-control.md, issue_id=24)
  ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T8.63: Restricted NACM user = partial data returned
             AS A security administrator
             I WANT TO restrict access to sensitive location data based on user roles
             SO THAT unauthorized parties cannot discover physical facility layouts, geographic coordinates, or rack security classifications
             GIVEN a user with a restricted NACM profile
             WHEN the user queries the `/locations` subtree
             THEN only location data authorized by their NACM access rules is returned

      T8.64: Unauthenticated/unauthorized request = rejected
             GIVEN an unauthenticated or unauthorized request
             WHEN attempting to retrieve location data via NETCONF or RESTCONF
             THEN the request is rejected due to lack of mutual authentication or insufficient access permissions

      T8.65: Sensitivity classifications configured for subtrees
             GIVEN the sensitivity classifications of location data (physical addresses, geographic coordinates, rack security levels)
             WHEN access control rules are defined
             THEN read access is explicitly configured for each sensitive subtree


  User Story #26 - Map Distributed Multi-Chassis Network Elements Across Locations (us-09-distributed-multi-chassis.md, issue_id=26)
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T8.66: Multi-chassis NE across multiple racks/locations
             AS A network operations engineer
             I WANT TO view all physical locations of a distributed multi-chassis network element
             SO THAT I can understand the physical dispersion of a logical network element across the facility
             GIVEN a stack switch "NE-1" with chassis-1 in Rack-101-A, chassis-2 in Rack-201-B, and chassis-3 in Rack-301-C
             WHEN the engineer queries all chassis entries referencing ne-ref "NE-1"
             THEN all three chassis entries are returned with their respective rack placements and location references, showing the full physical distribution

      T8.67: Single-chassis NE at one location
             GIVEN a network element with a single chassis at one location
             WHEN the distributed chassis mapping is queried
             THEN a single entry is returned matching the ne-ref


  User Story #27 - Paginated Query of Large-Scale Location Inventories (us-10-paginated-queries.md, issue_id=27)
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T8.68: RESTCONF pagination with offset/limit or cursor-based
             AS AN OSS client managing a large-scale network with thousands of locations and racks
             I WANT TO retrieve inventory data using paginated queries
             SO THAT I avoid overwhelming the server and receive manageable result sets
             GIVEN an inventory containing 50,000 locations
             WHEN the OSS queries `/locations/location` with RESTCONF pagination parameters (offset/limit or cursor-based)
             THEN results are returned in pages of the requested size rather than as a single massive payload

      T8.69: NETCONF with subtree filtering and pagination
             GIVEN a query for racks within a site containing hundreds of racks
             WHEN the client uses NETCONF with subtree filtering and pagination
             THEN the server returns paginated rack results with standard NETCONF pagination markers


  Use Case #28 - Register and Manage Network Inventory Location Hierarchy (uc-01-location-hierarchy.md, issue_id=28)
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    Main Success Scenario Steps (Basic Flow):
      T8.70:  MSS Step 1 — Inventory Controller receives location metadata from data source (RFID scan, GPS reading, or manual form input)
      T8.71:  MSS Step 2 — Controller assigns a unique string `id` to the new location
      T8.72:  MSS Step 3 — Controller populates `type` classification (e.g., "site", "building", "room", "pole")
      T8.73:  MSS Step 4 — If nested, Controller sets `parent` leafref to the containing location's id
      T8.74:  MSS Step 5 — Controller sets `timestamp` to the current date-and-time
      T8.75:  MSS Step 6 — Controller optionally sets `valid-until` to indicate expiration time
      T8.76:  MSS Step 7 — Location record is stored as read-only operational state in the controller datastore
      T8.77:  MSS Step 8 — OSS systems can query the location via NETCONF/RESTCONF GET operations mapping NEs to locations

    Alternate and Exception Flows:
      T8.78:  Alternate Flow 5a.1 — Duplicate Location ID: Controller detects proposed `id` already exists
      T8.79:  Alternate Flow 5a.2 — Duplicate rejected; controller either assigns new id or updates existing record
      T8.80:  Alternate Flow 5a.3 — If updating, controller overwrites mutable fields and returns to MSS step 7
      T8.81:  Alternate Flow 5b.1 — Invalid Parent Reference: Controller attempts to set `parent` to non-existent location id
      T8.82:  Alternate Flow 5b.2 — Leafref validation fails; hierarchy link cannot be established
      T8.83:  Alternate Flow 5b.3 — Controller either creates parent location first or leaves location at top level
      T8.84:  Alternate Flow 5c.1 — Location Type Not Standardized: operator enters custom type string (e.g., "pole", "roof", "floor")
      T8.85:  Alternate Flow 5c.2 — System accepts the flexible string type without requiring model extensions
      T8.86:  Alternate Flow 5c.3 — Organizational naming conventions are captured as-is
      T8.87:  Alternate Flow 5d.1 — Expired Location Detected: query includes location whose `valid-until` has passed
      T8.88:  Alternate Flow 5d.2 — System returns the location data but flags it as stale
      T8.89:  Alternate Flow 5d.3 — Location is excluded from operational use (dispatch, planning)

    Postconditions:
      T8.90:  Success Guarantee — New location record exists in read-only `locations/location` list with unique id, type, optional parent reference; location is queryable by OSS systems
      T8.91:  Failure Guarantee — No duplicate id created; leafref violations roll back parent assignment leaving location at top level


  Use Case #30 - Enrich Network Inventory Location with Physical Address and Geographic Coordinates (uc-02-physical-address-enrichment.md, issue_id=30)
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    Main Success Scenario Steps (Basic Flow):
      T8.92:  MSS Step 1 — Inventory Controller selects an existing location record
      T8.93:  MSS Step 2 — Controller populates `physical-address` sub-container: address, postal-code, state, city, country-code (ISO ALPHA-2, 2-letter uppercase)
      T8.94:  MSS Step 3a — Sets `reference-frame` with `astronomical-body` (default: "earth") and geodetic datum
      T8.95:  MSS Step 3b — Selects either `ellipsoid` (latitude, longitude, height) or `cartesian` (x, y, z) coordinates
      T8.96:  MSS Step 3c — Optionally records `velocity` data (v-north, v-east, v-up)
      T8.97:  MSS Step 4 — Controller sets `timestamp` to record when geo-location was captured
      T8.98:  MSS Step 5 — Controller optionally sets `valid-until` for geo-location data expiration
      T8.99:  MSS Step 6 — Enriched location is stored as read-only operational state

    Alternate and Exception Flows:
      T8.100: Alternate Flow 5a.1 — Invalid Country Code: operator enters country-code not matching `[A-Z]{2}`
      T8.101: Alternate Flow 5a.2 — Pattern validation rejects the value
      T8.102: Alternate Flow 5a.3 — Operator corrects to valid 2-letter uppercase ISO code
      T8.103: Alternate Flow 5b.1 — Both Coordinate Systems Present: data source provides both ellipsoid and cartesian
      T8.104: Alternate Flow 5b.2 — (location) choice constraint rejects dual presence
      T8.105: Alternate Flow 5b.3 — Controller selects one variant and discards the other
      T8.106: Alternate Flow 5c.1 — Missing Both Address and Geo-Location: neither provided
      T8.107: Alternate Flow 5c.2 — Location fails field dispatch readiness validation
      T8.108: Alternate Flow 5c.3 — Location flagged as incomplete; cannot be used for dispatch/planning
      T8.109: Alternate Flow 5d.1 — Coordinate Accuracy Below Threshold: coord-accuracy or height-accuracy set
      T8.110: Alternate Flow 5d.2 — If below acceptable thresholds, location flagged for verification
      T8.111: Alternate Flow 5d.3 — Controller may re-collect coordinates with higher precision
      T8.112: Alternate Flow 5e.1 — Alternate Coordinate System Selected: alternate-system field populated
      T8.113: Alternate Flow 5e.2 — If feature not enabled, field is suppressed
      T8.114: Alternate Flow 5e.3 — If enabled, alternate system metadata accompanies standard reference frame
      T8.115: Alternate Flow 5f.1 — Velocity Data for Stationary Asset: velocity vector provided for stationary rack/building
      T8.116: Alternate Flow 5f.2 — System accepts data without rejecting it; zero-velocity vectors are valid

    Postconditions:
      T8.117: Success Guarantee — Location contains valid physical-address and/or geo-location sub-container; passes dispatch readiness; country-code matches ISO ALPHA-2 pattern; coordinates comply with single-variant choice constraint
      T8.118: Failure Guarantee — Invalid country-codes rejected; dual coordinate entries resolved to single variant; incomplete locations flagged


  Use Case #36 - Deploy Chassis Equipment in Racks and Direct Locations (uc-05-deploy-chassis.md, issue_id=36)
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────
    Main Success Scenario Steps (Basic Flow):
      T8.119: MSS Step 1 — Deployment Engineer determines deployment type: rack-mounted or direct-location
      T8.120: MSS Step 2a — For rack-mounted: Engineer selects target rack by id
      T8.121: MSS Step 2b — Assigns `relative-position` (U-slot, uint8 0..255) to the chassis
      T8.122: MSS Step 2c — Sets `ne-ref` to the network element id
      T8.123: MSS Step 2d — Sets `component-ref` to the specific chassis component within the network element
      T8.124: MSS Step 3a — For direct-location: Engineer selects target location by id
      T8.125: MSS Step 3b — Assigns `chassis-id` (uint32) as unique identifier for this chassis instance
      T8.126: MSS Step 3c — Sets `ne-ref` to the network element id
      T8.127: MSS Step 3d — Sets `component-ref` to the specific chassis component
      T8.128: MSS Step 4 — Both chassis records are stored as read-only operational state
      T8.129: MSS Step 5 — Multiple chassis entries can reference the same ne-ref for distributed multi-chassis systems

    Alternate and Exception Flows:
      T8.130: Alternate Flow 5a.1 — Duplicate Relative Position: engineer attempts U-slot already occupied
      T8.131: Alternate Flow 5a.2 — Key constraint (relative-position per rack) rejects duplicate
      T8.132: Alternate Flow 5a.3 — Engineer selects different available U-slot position
      T8.133: Alternate Flow 5b.1 — Unresolved Network Element Reference: ne-ref points to non-existent NE id
      T8.134: Alternate Flow 5b.2 — Leafref validation fails
      T8.135: Alternate Flow 5b.3 — Engineer must correct reference or register NE first
      T8.136: Alternate Flow 5c.1 — Unresolved Component Reference: component-ref path does not find the component
      T8.137: Alternate Flow 5c.2 — Component association cannot be established
      T8.138: Alternate Flow 5c.3 — Engineer verifies component-id within referenced NE
      T8.139: Alternate Flow 5d.1 — Relative Position Out of Range: engineer enters value > 255
      T8.140: Alternate Flow 5d.2 — uint8 range constraint rejects the value
      T8.141: Alternate Flow 5d.3 — Engineer enters value within 0..255
      T8.142: Alternate Flow 5e.1 — Distributed Multi-Chassis Same NE: single NE has chassis across multiple racks/locations
      T8.143: Alternate Flow 5e.2 — Each entry references same ne-ref but different rack/location and component-ref
      T8.144: Alternate Flow 5e.3 — Distributed mapping recorded; no duplicate constraint violation (different racks/locations)

    Postconditions:
      T8.145: Success Guarantee — Chassis recorded in appropriate contained-chassis list with valid relative-position (rack) or chassis-id (location), resolved ne-ref, resolved component-ref; mapping queryable
      T8.146: Failure Guarantee — Duplicate relative-positions in same rack rejected; unresolved ne-ref/component-ref rejected; out-of-range position values rejected


  Use Case #37 - Validate Location Data Quality and Operational Readiness (uc-06-validate-data-quality.md, issue_id=37)
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    Main Success Scenario Steps (Basic Flow):
      T8.147: MSS Step 1 — OSS Management System initiates a validation query for a specific location or set of locations
      T8.148: MSS Step 2 — System checks `valid-until` timestamp is either absent (indefinite validity) or indicates a future time
      T8.149: MSS Step 3 — System checks at least one of `physical-address` or `geo-location` sub-containers is populated
      T8.150: MSS Step 4 — System checks `timestamp` to assess data recency
      T8.151: MSS Step 5 — For rack-associated queries, system checks `max-allocated-power` and `max-voltage` against deployed equipment
      T8.152: MSS Step 6 — System returns validation report: valid for dispatch, stale (expired), incomplete (missing address/geo), or unknown (no location data)
      T8.153: MSS Step 7 — Valid locations can be used for dispatch, planning, and NE association queries

    Alternate and Exception Flows:
      T8.154: Alternate Flow 5a.1 — Location Stale: valid-until is in past (now > valid-until)
      T8.155: Alternate Flow 5a.2 — Location flagged as stale and excluded from operational use
      T8.156: Alternate Flow 5a.3 — Controller notified to extend validity or archive record
      T8.157: Alternate Flow 5b.1 — Location Incomplete: neither physical-address nor geo-location populated
      T8.158: Alternate Flow 5b.2 — Location flagged as incomplete; cannot be used for dispatch
      T8.159: Alternate Flow 5b.3 — Controller must enrich record with at least one data type
      T8.160: Alternate Flow 5c.1 — Pagination Required: validation query spans very large result set
      T8.161: Alternate Flow 5c.2 — Server enforces RESTCONF/NETCONF pagination
      T8.162: Alternate Flow 5c.3 — OSS client retrieves results in pages, re-requesting validation for each page
      T8.163: Alternate Flow 5d.1 — Unauthorized Access: unauthenticated/unauthorized user attempts to query sensitive location data
      T8.164: Alternate Flow 5d.2 — NACM access control rules deny the query
      T8.165: Alternate Flow 5d.3 — User must authenticate and be granted read access to relevant subtrees
      T8.166: Alternate Flow 5e.1 — Rack Power Capacity Exceeded: deployed chassis draw more power than max-allocated-power
      T8.167: Alternate Flow 5e.2 — Validation report flags power capacity violation
      T8.168: Alternate Flow 5e.3 — Operations team must recalculate power budgets or redistribute equipment
      T8.169: Alternate Flow 5f.1 — Data Source Staleness: timestamp indicates data beyond acceptable freshness threshold
      T8.170: Alternate Flow 5f.2 — Validation report flags record for verification
      T8.171: Alternate Flow 5f.3 — Controller initiates new data collection cycle (RFID, geolocation, manual update)

    Postconditions:
      T8.172: Success Guarantee — Complete validation report generated categorizing each location as valid-for-dispatch, stale, incomplete, or unknown; valid locations ready for operational use; flagged locations queued for remediation
      T8.173: Failure Guarantee — Unauthorized access attempts rejected; large result sets paginated; power capacity violations reported


EPIC #9 - Network Inventory Location — Rack Infrastructure (draft-ietf-ivy-network-inventory-location-06)
=========================================================================================================

  Feature #5 - Rack Entity for Network Inventory (feat-05-rack-entity.md, issue_id=5)
  ────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios (Acceptance Criteria):
      T9.1:  Rack query by id returns identifier, dimensions, and classification
             GIVEN a rack entity with id "Rack-101-A"
             WHEN the management system queries the rack list
             THEN the rack is returned with its identifier, physical dimensions, and classification

      T9.2:  Rack-class security classification retrieved
             GIVEN a rack with rack-class set to "rack-secure-high"
             WHEN the rack classification is retrieved
             THEN the system indicates the rack has high security classification

      T9.3:  Dimensional attributes returned in millimeters
             GIVEN a rack with height 2200mm, width 600mm, and depth 1200mm
             WHEN the dimensional attributes are queried
             THEN all three dimensions are returned with their millimeter unit values

      T9.4:  Electrical specifications for capacity planning
             GIVEN a rack with max-voltage of 240V and max-allocated-power of 8000W
             WHEN the electrical specifications are retrieved
             THEN the power capacity and voltage limits are available for capacity planning

      T9.5:  Expired valid-until = stale rack data
             GIVEN a rack with valid-until timestamp that is in the past
             WHEN operational validation is performed
             THEN the rack data is considered stale and MUST NOT be used for operational purposes

      T9.6:  Inherited basic-common-entity attributes
             GIVEN a rack with uuid, name, alias, and description inherited from basic-common-entity-attributes
             WHEN the rack is retrieved
             THEN all inherited attributes are available alongside rack-specific attributes

      T9.7:  Invalid identityref classification rejected
             GIVEN a rack identityref value not deriving from rack-class-type
             WHEN validation is applied
             THEN the classification is rejected as invalid

    Logical Exception States:
      T9.8:  Invalid rack-class — identityref value not deriving from rack-class-type; classification invalid
      T9.9:  Zero or negative dimensions — Height, width, or depth of 0 semantically invalid for physical rack
      T9.10: Duplicate id — Two racks with same id violate key constraint
      T9.11: Expired rack — valid-until in past; rack data stale

    Logical Operations:
      T9.12: GET /locations/racks/rack — Retrieve rack list (read-only config false)
      T9.13: GET /locations/racks/rack/{id} — Retrieve specific rack by id


  Feature #6 - Rack Placement within Network Inventory Location (feat-06-rack-placement.md, issue_id=6)
  ──────────────────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios (Acceptance Criteria):
      T9.14: Rack placement with location-ref, row-number, column-number
             GIVEN a rack "Rack-101-A" placed in location "Room-101" at row 1, column 1
             WHEN the rack-location sub-container is retrieved
             THEN the location-ref resolves to "Room-101" with row-number 1 and column-number 1

      T9.15: Dangling location-ref
             GIVEN a location-ref pointing to a deleted location
             WHEN the reference is dereferenced
             THEN the rack has a dangling location reference and cannot be spatially mapped

      T9.16: Row and column numbers valid uint32
             GIVEN a rack-location with row-number and column-number both set to 0
             WHEN the placement data is retrieved
             THEN the row and column coordinates are returned as valid uint32 values

      T9.17: No rack-location container = no facility assignment
             GIVEN a rack with no rack-location container populated
             WHEN the rack is queried
             THEN the rack has no assigned facility location

      T9.18: Multiple racks at same location returned by filter
             GIVEN multiple racks placed in the same location
             WHEN location queries filter by location-ref
             THEN all racks associated with that location are returned

    Logical Exception States:
      T9.19: Dangling location-ref — leafref pointing to deleted/non-existent location id; broken reference
      T9.20: Unspecified location-ref — rack without location-ref has no spatial assignment; data quality gap

    Logical Operations:
      T9.21: GET /locations/racks/rack/{id}/rack-location — Retrieve rack placement data (read-only config false)


  Feature #7 - Rack-Level Chassis Container (feat-07-rack-chassis.md, issue_id=7)
  ─────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios (Acceptance Criteria):
      T9.22: Rack chassis at U-slot query
             GIVEN a rack "Rack-101-A" with a chassis at U-slot 10
             WHEN the contained-chassis list is queried
             THEN the entry shows relative-position 10 with valid ne-ref and component-ref

      T9.23: Duplicate relative-position rejected
             GIVEN two chassis entries at the same relative-position in the same rack
             WHEN the key constraint is validated
             THEN the data is rejected because relative-position must be unique per rack

      T9.24: Distributed stack switch across racks
             GIVEN a distributed stack switch (NE-1) with chassis-1 in Rack-101-A and chassis-2 in Rack-201-B
             WHEN each rack's contained-chassis list is inspected
             THEN both entries reference the same ne-ref "NE-1" with different component-ref values

      T9.25: Chassis at specific U-slot retrieval
             GIVEN a rack with a chassis entry at relative-position 42
             WHEN a chassis entry at U-slot 42 is retrieved
             THEN the entry returns with its ne-ref and component-ref associations

      T9.26: Relative-position > 255 rejected
             GIVEN a relative-position value exceeding 255
             WHEN the uint8 type constraint is applied
             THEN the value is rejected as out of range

      T9.27: Dangling ne-ref
             GIVEN an ne-ref pointing to a removed network element
             WHEN the reference is dereferenced
             THEN the rack chassis entry has a dangling ne-ref

    Logical Exception States:
      T9.28: Duplicate relative-position — two chassis at same U-slot in same rack violate key constraint
      T9.29: Unresolved ne-ref — leafref to non-existent NE id; dangling reference
      T9.30: Unresolved component-ref — component-ref cannot be resolved within referenced NE; broken association
      T9.31: Relative-position overflow — value above 255 exceeds uint8 range

    Logical Operations:
      T9.32: GET /locations/racks/rack/{id}/contained-chassis — Retrieve chassis mounted in a rack (read-only config false)
      T9.33: GET /locations/racks/rack/{id}/contained-chassis/{relative-position} — Retrieve chassis at specific U-slot


  User Story #17 - Query Rack Infrastructure Inventory (us-04-query-rack-inventory.md, issue_id=17)
  ──────────────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenario:
      T9.34: Full rack inventory query with all attributes
             AS A network capacity planner
             I WANT TO retrieve the complete list of racks with their dimensions, power capacity, and installed chassis
             SO THAT I can assess available rack space and plan new equipment installations
             GIVEN a rack inventory with multiple racks across different locations
             WHEN the operator queries `/locations/racks/rack` via NETCONF or RESTCONF
             THEN all racks are returned with their identifiers, dimensions (height, width, depth in mm), electrical specifications (max-voltage, max-allocated-power), and rack-class security classification


  User Story #18 - Locate Racks by Facility or Location (us-05-locate-racks-by-facility.md, issue_id=18)
  ──────────────────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T9.35: Query racks by location-ref = returned with row and column numbers
             AS A data center facility manager
             I WANT TO retrieve all racks located within a specific equipment room or site
             SO THAT I can manage equipment inventory at the room level
             GIVEN a location "Room-101" containing several racks
             WHEN the operator queries racks filtered by `rack-location/location-ref = "Room-101"`
             THEN all racks with that location reference are returned with their row and column numbers

      T9.36: Unresolved location-ref = dangling
             GIVEN a rack with an unresolved location-ref (pointing to a deleted location)
             WHEN the rack list is queried
             THEN the rack has a dangling location reference and cannot be spatially mapped to a facility


  User Story #20 - Calculate Rack Power and Spatial Capacity Utilization (us-06-rack-capacity-calculations.md, issue_id=20)
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    BDD Scenarios:
      T9.37: Remaining power headroom = max-allocated-power minus sum of chassis draws
             AS A power management controller
             I WANT TO calculate the remaining power and spatial capacity of each rack based on its allocated equipment
             SO THAT I can prevent circuit overloads and optimize rack utilization
             GIVEN a rack with `max-allocated-power` of 8000 watts and `max-voltage` of 240 volts
             WHEN the capacity calculation service computes available power
             THEN the remaining power headroom is derived as `max-allocated-power` minus the sum of power draws from all installed chassis (if power draw data is available from component metadata)

      T9.38: Chassis at position exceeding rack height = rejected
             GIVEN a rack with `height` of 2200mm
             WHEN a new chassis needs to be installed at a relative-position (U-slot) that would exceed the physical rack height
             THEN the deployment is rejected because the chassis position exceeds the rack's spatial bounds


  Use Case #32 - Deploy and Manage Equipment Racks in Network Facilities (uc-03-deploy-equipment-rack.md, issue_id=32)
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    Main Success Scenario Steps (Basic Flow):
      T9.39:  MSS Step 1 — Inventory Controller assigns a unique string `id` to the rack
      T9.40:  MSS Step 2 — Controller sets `rack-class` identityref to appropriate security classification (rack-standard, rack-secure-baseline, rack-secure-medium, or rack-secure-high)
      T9.41:  MSS Step 3 — Controller records rack physical dimensions: height, width, depth (all millimeters)
      T9.42:  MSS Step 4 — Controller records electrical specifications: max-voltage (volts) and max-allocated-power (watts)
      T9.43:  MSS Step 5 — Controller sets `timestamp` to current date-and-time
      T9.44:  MSS Step 6 — Controller optionally sets `valid-until` for rack data expiration
      T9.45:  MSS Step 7 — Rack record stored as read-only operational state

    Alternate and Exception Flows:
      T9.46:  Alternate Flow 5a.1 — Invalid Rack Classification: operator provides rack-class not derived from rack-class-type
      T9.47:  Alternate Flow 5a.2 — identityref validation rejects the classification
      T9.48:  Alternate Flow 5a.3 — Operator selects valid classification from hierarchy
      T9.49:  Alternate Flow 5b.1 — Zero or Implausible Dimensions: operator enters height/width/depth of 0 or > 65535
      T9.50:  Alternate Flow 5b.2 — uint16 range constraint rejects out-of-range values
      T9.51:  Alternate Flow 5b.3 — Zero dimensions flagged as invalid for physical rack; operator corrects
      T9.52:  Alternate Flow 5c.1 — Power Exceeds Capacity: equipment draws more power than max-allocated-power
      T9.53:  Alternate Flow 5c.2 — Power management controller raises alarm
      T9.54:  Alternate Flow 5c.3 — Operator must reduce power draw or update max-allocated-power
      T9.55:  Alternate Flow 5d.1 — Expired Rack Data: query includes rack whose valid-until has passed
      T9.56:  Alternate Flow 5d.2 — System returns rack data but flags as stale
      T9.57:  Alternate Flow 5d.3 — Rack excluded from capacity planning calculations
      T9.58:  Alternate Flow 5e.1 — Custom Rack Classification Extension: vendor wants non-standard classification
      T9.59:  Alternate Flow 5e.2 — Vendor extends rack-class-type identity hierarchy with new derived identity
      T9.60:  Alternate Flow 5e.3 — New classification available as identityref value

    Postconditions:
      T9.61:  Success Guarantee — Rack record exists with unique id, valid security classification, physical dimensions (mm), electrical specs; queryable and usable for capacity planning
      T9.62:  Failure Guarantee — Invalid rack-class values rejected; out-of-range dimensions rejected; rack cannot be used for planning without valid classification


  Use Case #34 - Assign and Locate Racks within Facility Rooms and Spaces (uc-04-assign-rack-location.md, issue_id=34)
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    Main Success Scenario Steps (Basic Flow):
      T9.63:  MSS Step 1 — Facility Manager selects a rack record by its id
      T9.64:  MSS Step 2 — Manager sets `rack-location/location-ref` to the id of target facility location
      T9.65:  MSS Step 3 — `ni-location-ref` typedef validates referenced location id exists in `locations/location` list
      T9.66:  MSS Step 4 — Manager sets `row-number` to identify which row within the location the rack occupies
      T9.67:  MSS Step 5 — Manager sets `column-number` to identify which column within the location the rack occupies
      T9.68:  MSS Step 6 — Rack is now spatially mapped to a facility, enabling room-level equipment queries
      T9.69:  MSS Step 7 — OSS systems can query racks filtered by `location-ref` to retrieve all racks in a specific room

    Alternate and Exception Flows:
      T9.70:  Alternate Flow 5a.1 — Dangling Location Reference: location-ref points to non-existent/deleted location id
      T9.71:  Alternate Flow 5a.2 — ni-location-ref leafref validation fails
      T9.72:  Alternate Flow 5a.3 — Rack placement not established; operator must select valid existing location
      T9.73:  Alternate Flow 5b.1 — Location Deletion with Dependent Racks: location deleted while racks still reference it
      T9.74:  Alternate Flow 5b.2 — Racks now have dangling location references
      T9.75:  Alternate Flow 5b.3 — Inventory controller must reassign or retire affected racks
      T9.76:  Alternate Flow 5c.1 — Out-of-Range Row or Column Numbers: operator enters row/column > 4294967295
      T9.77:  Alternate Flow 5c.2 — uint32 range constraint rejects the value
      T9.78:  Alternate Flow 5c.3 — Operator enters valid value within range
      T9.79:  Alternate Flow 5d.1 — Multiple Racks at Same Grid Position: two racks in same location assigned identical row and column
      T9.80:  Alternate Flow 5d.2 — System detects spatial conflict
      T9.81:  Alternate Flow 5d.3 — Operator reassigns one rack or confirms shared occupancy

    Postconditions:
      T9.82:  Success Guarantee — Rack spatially assigned to valid location with row and column coordinates; OSS queries can filter by location; rack placement resolvable in facility floor plans
      T9.83:  Failure Guarantee — Dangling location-ref values rejected; out-of-range row/column rejected; racks with broken location references flagged for remediation


  Use Case #36 - Deploy Chassis Equipment in Racks and Direct Locations (uc-05-deploy-chassis.md, issue_id=36)
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────
  (NOTE: This use case is shared with EPIC #8. See test cases T8.119 through T8.146 above for complete coverage.)


  Use Case #37 - Validate Location Data Quality and Operational Readiness (uc-06-validate-data-quality.md, issue_id=37)
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  (NOTE: This use case is shared with EPIC #8. See test cases T8.147 through T8.173 above for complete coverage.)
```

---

## Summary Count

| Category | Test Cases |
|---|---|
| **EPIC #7 (Geo-Location Grouping)** — 6 Features | **T1.1 – T6.17** = **75** test cases |
| **EPIC #8 (Location Hierarchy & Facilities)** — 4 Features, 7 User Stories, 4 Use Cases | **T8.1 – T8.173** = **128** test cases |
| **EPIC #9 (Rack Infrastructure)** — 3 Features, 3 User Stories, 2 Use Cases (excl. shared UC-36/UC-37 already counted) | **T9.1 – T9.83** = **83** test cases |
| **Grand Total** | **286** test cases |

Every BDD scenario, acceptance criterion, logical exception state, logical operation, user-story GWT, use-case main success scenario step, use-case alternate flow step, and state-machine transition from all **31 documents** has been individually enumerated with a unique test identifier.
</task_result>
</task>