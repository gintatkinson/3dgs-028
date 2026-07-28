# GUI Architecture Plan: 100% Specification Coverage

## Layout: 3-Zone Console

```
+-------+------------------------------------------+
|       |  [Geo] [NI Locations] [Racks] [Quality]  |
|       |  +--------------------------------------+|
|       |  |                                      ||
| Side  |  |    Feature-Specific Content Area      ||
| Tree  |  |    (properties, tables, charts)       ||
|       |  |                                      ||
|       |  +--------------------------------------+|
|       |  +--------------------------------------+|
|       |  |  Tables View (child instances)        ||
|       |  +--------------------------------------+|
+-------+------------------------------------------+
|          3D Viewport (split workspace)            |
+---------------------------------------------------+
```

Existing: sidebar tree, 3D viewport, tables panel. Replaced: PropertyGrid becomes the 4-tab Feature Content Area.

---

## Tab 1: Geo-Location (Epic #7, Features #1-#6, US #8-#15, UC #16-#19)

### Feature #1 — Root Container (T1.1-T1.15)
- Section: "Temporal"
  - timestamp field (RFC 6991 date-and-time, validated on blur)
  - valid-until field (validated, check temporal relationship)
  - status icon: green (valid), yellow (no temporal context), red (expired)
- Error label under field on format violation

### Feature #2 — Reference Frame (T2.1-T2.14)
- Section: "Frame of Reference"
  - astronomical-body (text, validated against pattern, auto-lowercase)
  - alternate-system (text, hidden when feature disabled, toggle in settings)
  - default display: "earth / wgs-84" when unset

### Feature #3 — Geodetic System (T3.1-T3.14)
- Section: "Geodetic System"
  - geodetic-datum (text, validated, space-to-dash normalization)
  - coord-accuracy (number, non-negative only)
  - height-accuracy (number, non-negative only, greyed out when Cartesian active)

### Feature #4 — Ellipsoid Coordinates (T4.1-T4.14)
- Section: "Ellipsoid Coordinates"
  - latitude (decimal, Earth range -90..90, non-Earth unbounded)
  - longitude (decimal, Earth range -180..180)
  - height (decimal, 6 fraction digits)

### Feature #5 — Cartesian Coordinates (T5.1-T5.14)
- Section: "Cartesian Coordinates"
  - x, y, z (decimal, 6 fraction digits)
  - Choice radio: "Ellipsoid" / "Cartesian" — only one active

### Feature #6 — Velocity Vector (T6.1-T6.17)
- Section: "Velocity"
  - v-north, v-east, v-up (decimal, 12 fraction digits)
  - Computed display (read-only, below velocity fields):
    - Speed: sqrt(v_north² + v_east²) m/s
    - Heading: atan2(v_east, v_north) degrees from true north
    - "undefined" when both are zero

### US #8 — Query by Timestamp
- Filter bar above properties: "Show locations with timestamp after: [date picker]"

### US #9 — Validate Location Freshness
- Status badge in section header: "Fresh" (valid-until future), "No expiry", "EXPIRED" (red)

### US #10 — Compute Speed
- see Feature #6 computed display

### US #11 — Compute Heading
- see Feature #6 computed display

### US #12 — Select Frame of Reference
- Dropdown/breadcrumb in section: Earth → Moon → Mars → Custom

### US #13 — Switch Between Coordinate Systems
- see Feature #4/#5 choice radio

### US #14 — Handle Expired Location Data
- Red banner at top: "This location expired on YYYY-MM-DD. Data may be unreliable."

### US #15 — Nest Locations with Inherited Reference Frame
- "Inherit from parent" checkbox in Reference Frame section
- Shows parent values greyed out when inherited

### UC #16 — Register Core Location Entity
- "New Location" button in sidebar → opens registration form (id, type, parent dropdown)
- On save: creates NI Location properties row, appears in location tree

### UC #17 — Port Location to External Standards
- "Export" button → dropdown: IETF URI, W3C Geolocation, GML, KML
- Copies formatted value to clipboard

### UC #18 — Track Object Motion
- Velocity section with live-updating speed/heading
- "Clear Velocity" button when stationary (v-north=v-east=v-up=0)

### UC #19 — Configure Non-Earth Body
- astronomical-body dropdown with predefined bodies: Earth, Moon, Mars, Enceladus, Ceres, 67P/C-G, Sun
- Custom entry with pattern validation
- Datum dropdown updates per body selection

---

## Tab 2: NI Locations (Epic #8, Features #1-#4, US #10,#12,#15,#23,#24,#26,#27, UC #28,#30)

### Layout: Split panel — Location Tree (left) + Properties (right)

### Feature #8.1 — NI Location Entity (T8.1-T8.13)
- Location tree: hierarchical tree (site → building → room → ...)
  - Root: Tokyo-Campus
    - Building-A
      - Room-101
      - Room-201
    - Pole-TK-01
- Click node → properties panel shows:
  - Section "Identity": id, type, uuid, name, alias, description
  - Section "Classification": type (enum: site/building/room/pole/floor), parent (resolved name)
  - Section "Temporal": timestamp, valid-until
- Top-level locations have no parent (indicated by "--" or root icon)

### Feature #8.2 — Physical Address (T8.14-T8.23)
- Section "Physical Address":
  - address, postal-code, state, city
  - country-code (2-char uppercase, validated)
- Dispatch readiness badge: green (has address), grey (no address)

### Feature #8.3 — Geographic Location for NI (T8.24-T8.34)
- Sub-panel reusing Geo-Location tab sections
- Reference frame, geodetic system, coordinates, velocity
- Choice constraint warning if both ellipsoid and cartesian present

### Feature #8.4 — Location-Level Chassis Table (T8.35-T8.45)
- Table below properties: columns = chassis-id, ne-ref, component-ref
- Right-click → "Remove Chassis" / "Edit Chassis"

### US #10 — Query Location Hierarchy
- "Filter" text field above tree
- "Expand All" / "Collapse All" buttons

### US #12 — Validate Dispatch Readiness
- Badge per location in tree: 
  - Green ✓ = ready (has address or geo, valid-until future/absent)
  - Yellow ⚠ = incomplete (no address AND no geo)
  - Red ✗ = stale (valid-until expired)
- Summary bar: "12 ready, 3 incomplete, 1 stale"

### US #15 — Expired Location Handling
- "Show expired" toggle filter
- Expired nodes greyed out in tree with strikethrough

### US #23 — Navigate Full Topology (T8.61-T8.62)
- Breadcrumb bar above properties: Tokyo-Campus > Building-A > Room-101 > Rack-101-A > U-slot 10
- Each segment clickable, navigates to that node

### US #24 — Access Control (T8.63-T8.65)
- Login state indicator in toolbar
- Restricted user: geo-location fields show "[Restricted]" instead of values
- Unauthenticated: "Access Denied" overlay

### US #26 — Distributed Multi-Chassis (T8.66-T8.67)
- "Distributed View" button → panel showing all locations for a given ne-ref
- Table: location, rack, relative-position, component-ref

### US #27 — Paginated Queries (T8.68-T8.69)
- Pagination controls below location tree: "← Page 1 of 50 →" 
- Page size selector: 25, 50, 100

### UC #28 — Register Location Hierarchy (T8.70-T8.91)
- "Register Location" button → modal form:
  - id (required, text + uniqueness check)
  - type (predefined dropdown + custom)
  - parent (tree picker)
  - name, alias, description
- Duplicate check before save
- Invalid parent ref → warning, saves as top-level

### UC #30 — Enrich with Address and Geo (T8.92-T8.118)
- "Enrich Location" button on selected location
- Step wizard: 1. Physical Address → 2. Geographic Location → 3. Review → Save
- Country code validation, choice constraint enforcement
- Incomplete warning if skipping both address and geo

---

## Tab 3: Racks (Epic #9, Features #5-#7, US #17,#18,#20, UC #32,#34)

### Layout: Rack Table (top) + Rack Detail Panel (bottom)

### Feature #9.5 — Rack Entity (T9.1-T9.13)
- Rack inventory table: id | class | height | width | depth | max-voltage | max-allocated-power | status
- Click row → detail panel:
  - Section "Identity": id, rack-class (dropdown: rack-standard, rack-secure-*)
  - Section "Dimensions": height (mm), width (mm), depth (mm)
  - Section "Power": max-voltage (V), max-allocated-power (W)
  - Section "Temporal": timestamp, valid-until
- Status column: green (valid), red (expired), grey (no valid-until)

### Feature #9.6 — Rack Placement (T9.14-T9.21)
- Section "Placement":
  - location-ref (resolved name + link to location)
  - row-number, column-number (uint32)
  - Status: "Placed in Room-101 at (1,1)" or "Unplaced"
  - "Dangling reference" warning if location-ref broken

### Feature #9.7 — Rack Chassis (T9.22-T9.33)
- Table below rack detail: relative-position (U-slot) | ne-ref | component-ref
- "Add Chassis" button → form: position, ne-ref, component-ref
- Duplicate position check
- "Remove" button per row

### US #17 — Query Rack Inventory
- "Filter" bar above rack table
- Filter by rack-class, location, power range

### US #18 — Locate Racks by Facility
- "Group by Location" toggle → racks grouped under location headers
- "Show Unplaced" toggle

### US #20 — Calculate Rack Capacity (T9.37-T9.38)
- Capacity gauge per rack in table:
  - Power: used/total watts with percentage bar
  - Space: chassis count + spatial bounds check
  - Tooltip: "3,500W remaining of 8,000W (56% used)"

### UC #32 — Deploy Equipment Rack (T9.39-T9.62)
- "Deploy Rack" button → modal form:
  - id (required)
  - rack-class (identityref dropdown, validated)
  - height, width, depth (mm, uint16 validated)
  - max-voltage, max-allocated-power (uint16 validated)
- Validation errors shown inline
- Power capacity alarm if exceeded

### UC #34 — Assign Rack Location (T9.63-T9.83)
- "Assign Location" button → location tree picker + row/col inputs
- "Clear Location" for unassignment
- Spatial conflict warning if two racks at same position
- Dangling reference warning on parent location deletion

---

## Tab 4: Quality (UC #37, US #12, US #15, US #24)

### Layout: Summary dashboard + filterable status list

### UC #37 — Validate Data Quality (T8.147-T8.173)
- Summary cards at top:
  - Valid for Dispatch: 12 ✓ (green)
  - Stale (Expired): 3 ✗ (red)  
  - Incomplete: 1 ⚠ (yellow)
  - Unknown: 0 ? (grey)
- Status list below (filterable, paginated):
  - Columns: location id | type | status | valid-until | has address | has geo
  - Click row to navigate to that location in NI tab
- "Re-validate All" button
- Pagination for large sets (US #27)
- Power capacity violations flagged per rack (US #20)
- Access control: restricted users see filtered results (US #24)
- Data source staleness: stale timestamp flagged (UC #37 alt flows)

---

## Services Layer (unchanged, already built)

- GeoLocationService — timestamp, body, datum, coordinate, velocity validation
- NiLocationServices — query hierarchy, dispatch validation, staleness, rack inventory, capacity, topology trace, distributed chassis, pagination
- UseCaseOrchestrator — register location, deploy rack, validate data quality, enrich location, assign rack, deploy chassis
- VelocityUtility — speed/heading computation

## ViewModel Layer (12 new)

| ViewModel | Tab | Purpose |
|-----------|-----|---------|
| GeoInspectorViewModel | Geo | Loads node geo-location, validates, computes speed/heading |
| NiLocationTreeViewModel | NI | Loads location hierarchy, manages selection, dispatch status |
| NiLocationDetailViewModel | NI | Loads single location detail + address + geo |
| RackTableViewModel | Racks | Loads rack list, filtering, sorting |
| RackDetailViewModel | Racks | Loads single rack + placement + chassis |
| QualityDashboardViewModel | Quality | Runs validation, aggregates status counts |

## Widget Layer (12 new)

| Widget | Tab | Purpose |
|--------|-----|---------|
| GeoInspector | Geo | Sections: Temporal, Reference Frame, Geodetic, Coordinates, Velocity |
| CoordinateChoiceToggle | Geo | Ellipsoid/Cartesian radio toggle |
| VelocityComputedDisplay | Geo | Speed + heading read-only display |
| NiLocationTree | NI | Hierarchical tree of NI locations |
| NiLocationDetail | NI | Properties panel for selected location |
| DispatchBadge | NI | Green/yellow/red status indicator |
| AddressForm | NI | Physical address fields with country-code validation |
| RackTable | Racks | Sortable/filterable table of all racks |
| RackDetail | Racks | Rack properties + placement + chassis table |
| CapacityGauge | Racks | Power/space utilization bar |
| QualityDashboard | Quality | Summary cards + filterable status list |
| BreadcrumbBar | Shared | Navigable path: Site > Building > Room > Rack > Chassis |

---

## Test Plan per Feature

| Feature | Unit Tests | Widget Tests | Integration |
|---------|:----------:|:------------:|:-----------:|
| GeoLocation Root | 15 (T1.1-T1.15) | 3 | 1 |
| Reference Frame | 14 (T2.1-T2.14) | 3 | 1 |
| Geodetic System | 14 (T3.1-T3.14) | 3 | 1 |
| Ellipsoid Coords | 14 (T4.1-T4.14) | 3 | 1 |
| Cartesian Coords | 14 (T5.1-T5.14) | 3 | 1 |
| Velocity Vector | 17 (T6.1-T6.17) | 3 | 1 |
| NI Location Entity | 13 (T8.1-T8.13) | 4 | 1 |
| Physical Address | 10 (T8.14-T8.23) | 3 | 1 |
| Geo Location for NI | 11 (T8.24-T8.34) | 3 | 1 |
| Location Chassis | 11 (T8.35-T8.45) | 3 | 1 |
| Rack Entity | 13 (T9.1-T9.13) | 4 | 1 |
| Rack Placement | 8 (T9.14-T9.21) | 3 | 1 |
| Rack Chassis | 12 (T9.22-T9.33) | 3 | 1 |
| **User Stories** | 28 tests | 10 | 7 |
| **Use Cases** | 83 tests | 20 | 6 |
| **Total** | **286** | **68** | **25** |

---

## Implementation Phases

### Phase 1: Foundation (existing, done)
- Domain models, validation services, seed data, database asset
- 640 passing tests

### Phase 2: Geo Tab (Epic #7 full)
- GeoInspector widget + ViewModel
- CoordinateChoiceToggle
- VelocityComputedDisplay
- Wire to existing PropertiesViewModel for save validation
- Test: T1.1-T6.17 (75 service tests + 21 widget tests)

### Phase 3: NI Tab (Epic #8 full)
- NiLocationTree + NiLocationDetail
- DispatchBadge, AddressForm
- BreadcrumbBar
- Test: T8.1-T8.173 (128 service tests + 34 widget tests)

### Phase 4: Racks Tab (Epic #9 full)
- RackTable + RackDetail
- CapacityGauge
- Test: T9.1-T9.83 (83 service tests + 22 widget tests)

### Phase 5: Quality Tab
- QualityDashboard
- Test: UC #37 integration tests

### Phase 6: Verification
- `flutter analyze` → 0 issues
- `flutter test` → 286+ pass
- `verify_downstream_baseline.py` → exit 0
- Screenshots, release zip, walkthrough, issue closure
