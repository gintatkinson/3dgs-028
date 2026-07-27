---
title: "Handle Expired Location Data"
issue_id: 14
type: "user-story"
generation_mode: "subagent"
spec_source: "RFC 9179"
---

# User Story: Handle Expired Location Data

## Parent Epic
- [ ] #7 - [Geo-Location Grouping](https://github.com/gintatkinson/3dgs-028/blob/main/docs/epics/epic-01-geo-location-grouping.md) (temporal lifecycle management when location data validity expires)

## Domain Object Mapping
- **Primary Domain Objects:** GeoLocation (container geo-location), ValidUntil (leaf valid-until), Timestamp (leaf timestamp)
- **Actor/Role:** Data Retention Manager

## BDD Scenario (OOA/OOD Realization)
**Given** a geo-location entity has a valid-until timestamp set to "2022-06-01T00:00:00Z"
**When** the current system time exceeds the valid-until timestamp
**Then** the location data transitions to an expired state and consumers are notified that the data is no longer fresh

**As a** Data Retention Manager
**I want to** detect when location data has exceeded its validity period
**So that** I can initiate a re-measurement, archive stale records, or remove expired location entries

## UML Sequence Diagram
```mermaid
sequenceDiagram
    autonumber
    actor manager as "manager : DataRetentionManager"
    participant locator as "locator : GeoLocation"
    participant registry as "registry : Datastore"

    manager->>locator: checkExpiration(entityId : String)
    locator->>registry: readValidUntil(entityId : String)
    registry-->locator: validUntil : Timestamp
    Note over locator: Compare current time against validUntil

    alt [currentTime < validUntil]
        Note over locator: Location is within validity window
        locator-->manager: dataIsFresh : Status
    else [currentTime >= validUntil]
        Note over locator: Location validity has expired
        locator-->manager: dataIsExpired : Status
        opt [autoCleanupPolicyEnabled == true]
            manager->>locator: archiveExpiredData(entityId : String)
            locator->>registry: markAsExpired(entityId : String)
            registry-->locator: archived : Status
        end
    else [validUntilNotSet]
        Note over locator: No expiration, data remaining valid indefinitely
        locator-->manager: dataHasNoExpiry : Status
    end
```

## UML State Machine Diagram
```mermaid
stateDiagram-v2
    [*] --> Active : recordLocation(timestamp, validUntil)
    Active --> Expired : validUntilElapsed [currentTime >= validUntil]
    Active --> Removed : deleteLocation()
    Expired --> Removed : deleteLocation()
    Expired --> Active : refreshLocation(newValidUntil)
    Removed --> [*]
```

## Operational Context
From RFC 9179, YANG module: "leaf valid-until { type yang:date-and-time; description 'The timestamp for which this geo-location is valid until. If unspecified, the geo-location has no specific expiration time.'; }"

From RFC 9179, Section 5.1.3 (GML): "values down to the resolution of seconds for 'gml:TimePeriod' can be mapped using the 'valid-until' node of the YANG grouping."

## Required Features Matrix
- [ ] #1 - [Geo-Location Root Container](https://github.com/gintatkinson/3dgs-028/blob/main/docs/features/feat-01-geo-location-root.md) (valid-until leaf defines the expiration timestamp; timestamp leaf provides the measurement reference point)

## Source References
Structural Schema: [ietf-geo-location@2022-02-11.yang](https://github.com/YangModels/yang/blob/main/standard/ietf/RFC/ietf-geo-location%402022-02-11.yang)
Normative Specification: [RFC 9179: A YANG Grouping for Geographic Locations](https://datatracker.ietf.org/doc/rfc9179/) (Clause: Sections 2.4, 5.1.3)
