# Drivly vs Client Requirement — Gap Analysis & Build Plan

**Comparison of the built Drivly demo app against the client SRS** (`rent-a-car-system.docx` — "Automated Car-Sharing Platform, Free-Floating & Station-Based").

> **One-line finding:** the client asked for an *operator-owned, automated, keyless IoT car-sharing platform*; what was built (Drivly) is a *peer-to-peer rental marketplace*. They share a large supporting base, but the keyless/IoT/geofencing core that defines the client product is the real remaining work — and ~90-95% of it can be built without hardware.

**Status legend:** `[DONE]` built & usable · `[PARTIAL]` exists, needs rework · `[MISSING]` not built · `[REPURPOSE]` built for the wrong model, must be re-aimed/removed.
**Effort legend:** `S` ~1-3 dev-days · `M` ~4-8 dev-days · `L` ~2-3 dev-weeks · `XL` ~4+ dev-weeks.

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Two Different Products: What Was Asked vs What Was Built](#2-two-different-products-what-was-asked-vs-what-was-built)
- [3. Full Requirements Inventory (the Client SRS, decomposed)](#3-full-requirements-inventory-the-client-srs-decomposed)
- [4. Gap Analysis — Where We Stand (requirement by requirement)](#4-gap-analysis-where-we-stand-requirement-by-requirement)
- [5. Target Architecture, Data Model & MVC Design](#5-target-architecture-data-model-mvc-design)
- [6. End-to-End Flows & All Scenarios](#6-endtoend-flows-all-scenarios)
- [7. Feasibility — Can We Build It Without the Hardware?](#7-feasibility-can-we-build-it-without-the-hardware)
- [8. Roadmap, Effort, Timeline & Cost](#8-roadmap-effort-timeline-cost)

---
## 1. Executive Summary

We compared two things: the **client requirement** for an *Automated Car-Sharing Platform* (operator-owned fleet, fully contactless, IoT keyless cars, GPS geofencing) against **Drivly**, the application built so far. The single most important finding is a **business-model mismatch**: Drivly is a **peer-to-peer rental marketplace** (Turo/Getaround style — individual hosts list their own cars, earn payouts, and chat with renters), while the client asked for a **single operator that owns the whole fleet and runs it with zero on-site staff via IoT-enabled keyless cars**. That is not a missing-features problem; it is a different product aimed at a different owner. The good news: the *supporting half* of the platform — login/KYC, payments, the booking wizard, the map and discovery screens, trip start/end, photo-based inspections, disputes, and the admin panel — is genuinely built and reusable, so this is a strong head start rather than a restart. **Yes, this can be built, and roughly 90-95% of it can be built and demoed now without any hardware**, using a "swap-in" gateway adapter (a software car simulator today; the real vendor plugged in later). The real differentiating work — IoT lock/unlock/immobilize, geofencing, proximity unlock, the live Control Tower map, deposit holds, and per-hour/per-day automated billing with penalties — is largely still ahead of us.

### Where We Stand (estimates toward the *target* product)

These bars show how far the existing code carries us **toward the new operator-owned target** — not how "finished" Drivly is. Drivly is a working app; it is simply aimed at a different model. Note that the on-device "GPS control center" ([gps_control_screen.dart](frontend/lib/features/trip/presentation/screens/gps_control_screen.dart)) is **fully simulated** — there is no real IoT, geofencing, or proximity gating behind it today.

```text
PROGRESS TOWARD TARGET — Automated Car-Sharing Platform
(each block ~= 5%)

Customer Mobile App        [##########..........]  ~50%
  auth/KYC/booking/inspection done; keyless+proximity+billing missing

Web Admin / Control Tower  [######..............]  ~30%
  Filament CRUD done; live fleet map, geofence editor, tariff/penalty missing

Backend + IoT Gateway      [####................]  ~20%
  API/services/models solid; real IoT, PostGIS geofencing, telemetry missing

Cross-cutting              [###############.....]  ~75%
  auth, payments, push, uploads largely reusable as-is
(auth/KYC/payments)

-----------------------------------------------------------------
OVERALL toward target      [#########...........]  ~40-45%
```

### Bottom Line

| Question | Honest answer |
|---|---|
| Is it the same product? | No — Drivly is a peer-to-peer marketplace; the target is an operator-owned, zero-human, IoT keyless fleet. |
| How much is reusable? | Roughly half — auth/KYC, payments/wallet, discovery + map, booking wizard, inspections, disputes, admin, and push all carry over. |
| Biggest risk | The vendor GPS/IoT API and a test device — until they arrive, the keyless/telemetry path cannot be validated against real hardware. |
| Can it be built without hardware? | Yes — ~90-95% via a `VehicleGateway` adapter with a software simulator (the existing on-device GPS prototype is an early version of this idea). |
| Realistic timeline | The proposal's 11-12 weeks is optimistic for the full target; the realistic range is **12-16 weeks (most likely 14-16)** once the model pivot, geofencing/IoT scope, and real-hardware integration are accounted for. |
| Realistic cost framing | The $7,500 / 5-milestone structure is a reasonable baseline, but the model change and IoT/geofencing scope warrant revisiting the M4 effort honestly rather than treating it as "wiring." |
| Hard dependency | Vendor name + full API docs + test-device login by ~end of Week 1, or milestone M4 (IoT/payments/pricing) slips by the same delay. |

### Top 5 Things to Build Next

1. **IoT VehicleGateway** [MISSING] — one interface (unlock / lock / immobilize / status+telemetry) with a software simulator now and the real vendor adapter later.
2. **Geofencing engine (PostGIS)** [MISSING] — operational zones + drop-off zones, out-of-bounds detection, and the `<=15m` proximity gate for unlock.
3. **Keyless flow rework** [PARTIAL] — proximity-gated "Unlock & Start", strict 4-photo walkaround enforcement, and pre-lock automated checks (in-zone, ignition off, doors shut).
4. **Live Control Tower** [MISSING] — admin fleet map with color-coded statuses (Green / Blue / Red / Orange) fed by 60s telemetry.
5. **Deposit holds + dynamic pricing/penalty matrix** [MISSING] — Stripe pre-auth holds and forfeiture, plus hourly/daily/seasonal tariffs with grace-period late-return auto-billing.

---

## 2. Two Different Products: What Was Asked vs What Was Built

The single most important thing to understand before reading any feature list is this: **the document you commissioned and the app that was built describe two different businesses that happen to share the same screens.** They are both "car rental apps," but they sit at opposite ends of the rental world. What you asked for is an **operator-owned, fully automated, keyless car-sharing fleet** — one company owns every car, and a customer can walk up, unlock with their phone, drive, and drop off with zero human involvement. What was built, **Drivly**, is a **peer-to-peer (P2P) marketplace** — many private owners ("hosts") list their own cars and renters book them, much like Turo. The good news, covered at the end of this section, is that the *plumbing* underneath both is largely the same, so this is a pivot on a strong foundation, not a rebuild from zero.

### 2.1 Side-by-Side: The Two Business Models

The table below contrasts the two products on the dimensions that actually change the code and the contract. Read it as "the world the requirement assumes" versus "the world Drivly was coded for."

| Dimension | Client Requirement — Automated Free-Floating Car-Sharing | What Was Built — Drivly P2P Marketplace |
|---|---|---|
| **Who owns the cars** | One operator owns and manages the entire fleet. | Many independent private owners ("hosts"), each owning their own car. |
| **Who lists them** | Nobody self-lists — the operator (admin) adds vehicles in the back-office, including each car's IoT device IMEI. | Hosts self-list cars via a host app (make/model/price/photos), then admin approves. |
| **Human at handover?** | **None.** 100% contactless, zero on-site staff — the defining promise. | Manual / owner-mediated handover is the implicit norm; no keyless layer exists. |
| **How you get the key** | Phone unlocks the car remotely when within ≤15 m; physical key waits in the glovebox; engine started by the customer. | Out of scope as built — there is no keyless access; key exchange happens off-app between host and renter. |
| **Billing model** | On-demand, fine-grained: counter starts at unlock and stops at lock (per-minute / per-hour / per-day), plus grace periods and late penalties. | Daily-rental oriented: a booking spans whole days; trip extension is measured in **days**, not minutes. |
| **Core tech moat** | Keyless IoT (unlock / lock / immobilize + 60 s telemetry) and **geofencing** (PostGIS zones, ≤15 m proximity gate, out-of-bounds detection). | Listing/marketplace mechanics: search, reviews, host earnings, host↔renter chat. No IoT; no geofencing (plain lat/lng columns, no PostGIS). |
| **Real-world analogue** | **Zipcar / Share Now / Free2Move / Getaround-Connect** — operator fleet, keyless, app-unlock. | **Turo / classic Getaround** — peer hosts, owner or manual handover. |
| **Trust & safety mechanism** | Remote immobilize for theft, geofence/border alerts + SMS, security-deposit **hold** with forfeiture, cross-user damage comparison flagging the previous driver. | Host verification, KYC review, disputes, reviews — people-and-reputation based, not device-and-geofence based. |
| **Revenue flow** | All revenue flows to the single operator; no payouts to third parties. | Renter pays → platform takes a cut → **host receives a payout** (earnings, wallet, withdraw). |

### 2.2 Why This Matters for the Code, Not Just the Pitch

The model mismatch is not a marketing nuance — it determines which existing code is an asset, which must be re-aimed, and which must be deleted. The P2P concepts below exist *only* because Drivly is a marketplace, and have no home in the operator world:

| Built concept | Why it exists in Drivly (P2P) | Fate under the Automated Platform |
|---|---|---|
| Hosts, host roles, host app screens | A marketplace needs sellers | [REPURPOSE] — becomes the single operator's fleet-management role |
| Host payouts / earnings / wallet withdraw | Owners must be paid | [REPURPOSE] — operator owns all revenue; third-party payout logic is N/A and is removed |
| Host verification | Vet private owners | [REPURPOSE] — folded into operator/admin onboarding, not customer-facing |
| Host↔renter chat | Two parties must coordinate | [REPURPOSE] — at most an optional customer-support channel |
| Instant / request booking | Host accepts/declines requests | [REPURPOSE] — "take the car now" on-demand or a simple time-slot reservation |
| Keyless IoT, geofencing, Control Tower live map | Not part of a P2P marketplace | [MISSING] — these *define* the client product and were never built |

In short: the parts that make Drivly a *marketplace* are exactly the parts the client product does not have, and the parts that make the client product *automated* (the IoT gateway, geofencing engine, proximity unlock, live fleet map, deposit holds, dynamic pricing/penalty matrix) are precisely the parts Drivly never built. The on-device GPS control screen ([gps_control_screen.dart](frontend/lib/features/trip/presentation/screens/gps_control_screen.dart), backed by [gps_device_provider.dart](frontend/lib/features/trip/domain/providers/gps_device_provider.dart)) is the one place the client's core idea appears — and its own header comment admits the device state is **"simulated on-device so the whole flow is demoable before the third-party GPS API is wired up."** It is a convincing demo, not a working gateway: there is no backend gateway, no real IoT, and no real geofencing or proximity gating behind it.

### 2.3 But the Overlap Is Large — This Is a Pivot, Not a Restart

Here is the encouraging part, stated plainly: **both products are car-rental apps, and roughly half of the supporting platform is genuinely reusable today.** Account creation with email / OTP / social login, KYC document upload with admin review, Stripe payments and the wallet, car discovery with a map and filters, the booking wizard (dates → pricing → pay), pre/post-trip inspection **with photo upload** (which maps almost exactly onto the required 4-photo Digital Walkaround), the trip start/end/extend lifecycle, the dispute flow, reviews, settings, push notifications, and the Filament admin (users, cars, bookings, disputes, promo codes) all exist and work. That is a real head start.

A fair rough estimate: of the *whole* target platform, the shared foundation already covers on the order of **45–55%** of the supporting (non-differentiating) work — auth, KYC, payments, discovery, booking, inspection, disputes, admin scaffolding. The remaining effort concentrates in the **differentiating layer** the requirement is actually about: IoT gateway, geofencing / PostGIS, proximity unlock, Control Tower, deposit holds, dynamic pricing / penalties, and the per-minute/hour billing model. (One caveat on the demo today: Stripe, Firebase, Apple/Google sign-in, and Maps currently run in a credential-free **demo mode**, and the map screen renders a styled placeholder rather than live Google Maps tiles until a real key is supplied — so "works" here means the flows are built, not that they are wired to live services.) The correct mental model is therefore: **a solid platform was built for the wrong business model, and now needs its rental "engine" re-aimed and a keyless/geofencing layer added on top.**

### 2.4 The Two Value Chains at a Glance

The clearest way to see the difference is to follow the car and the money through each model.

```text
  P2P MARKETPLACE  (What Was Built — Drivly / Turo-style)
  ----------------------------------------------------------------------
     HOST (private owner)                            RENTER (customer)
         |  lists own car                                  ^
         |  sets price                                     |  books, pays
         v                                                 |  manual key handover
   +-----------------------------+   payout (host cut)  +--+----------------+
   |   PLATFORM  (Drivly app)    |--------------------->|   $ to HOST       |
   |  search * chat * reviews    |<---------------------|   platform keeps  |
   |  host verify * disputes     |    renter payment    |   a commission    |
   +-----------------------------+                      +-------------------+
   No IoT. No geofencing. Key changes hands between two people.


  AUTOMATED FREE-FLOATING FLEET  (What Was Asked — Zipcar / Share Now-style)
  ----------------------------------------------------------------------
     OPERATOR / FLEET (single owner, owns every car + IoT box)
         |  adds cars + IMEI in Control Tower
         v
   +-----------------------------+   unlock/lock/immobilize   +----------------+
   |  PLATFORM + IoT GATEWAY     |--------------------------->|  CAR Smart Box |
   |  geofencing (PostGIS)       |<---------------------------|  GPS/fuel/odo  |
   |  live map * deposit hold    |   60s telemetry            +----------------+
   +--------------+--------------+
                  |  proximity-gated unlock (<=15 m), per-min/hour billing
                  v
              DRIVER (customer)  -- walks up, taps Unlock, drives, taps Lock
   All revenue -> the OPERATOR. Zero human at handover.
```

The left chain has **three parties and a commission split**; the right chain has **one owner, a device on every car, and software where the human used to be.** Everything in the rest of this document follows from moving Drivly from the left picture to the right one.

---

## 3. Full Requirements Inventory (the Client SRS, decomposed)

This section breaks the client's brief for the **Automated Car-Sharing Platform** into a numbered, atomic list of requirements. Every other part of this document refers back to these IDs, so they are the shared spine of the build plan. Each requirement carries a stable ID whose prefix says which part of the system owns it: **MOB-** (customer mobile app), **ADM-** (web admin / Control Tower), **BE-** (backend, IoT gateway, geofencing), and **NFR-** (non-functional: security, infrastructure, languages, scale).

A note on the "Hardware-dependent?" column, because it drives the schedule and the payment milestones: **No** means it can be built and fully tested today against a software simulator; **Partial** means most of it can be built now but final validation needs the vendor's GPS/IoT device; **Yes** means it genuinely cannot be confirmed until real hardware and the vendor API are in hand. As covered in the feasibility note, the large majority of the platform is **No** or **Partial**, so almost everything can proceed before the hardware arrives.

Priority uses MoSCoW: **Must** = the product does not work or does not match the operator-owned model without it; **Should** = strongly expected, can briefly trail first launch; **Could** = valuable but deferrable. Important framing for the rest of the document: every requirement below describes the **target operator-owned free-floating product**. The current build, Drivly, is a peer-to-peer marketplace; where Drivly already contains something reusable it is noted in later sections, not here.

### 3.1 Customer Mobile App (MOB-)

Plain-language summary: this is the app the renter holds. It must let a new user sign up and prove who they are, find and pay for a nearby car, walk to it, unlock it without any staff present, drive, then return and lock it to stop the meter.

| ID | Requirement (one line) | Source clause | Priority | Hardware-dependent? |
|---|---|---|---|---|
| MOB-01 | Account creation via email, phone, or social login (Apple / Google) | SRS 3.1 | Must | No |
| MOB-02 | Phone number verified by OTP (one-time code) | SRS 3.1 | Must | No |
| MOB-03 | Mandatory KYC: upload Government ID / Passport **and** Driver License (two documents) | SRS 3.1 | Must | No |
| MOB-04 | Payment setup: secure tokenization of credit / debit cards | SRS 3.1 | Must | No |
| MOB-05 | Digital wallet support (Apple Pay / Google Pay) | SRS 3.1 | Should | No |
| MOB-06 | Hard block: car cannot be booked without a verified payment method on file | SRS 3.1 | Must | No |
| MOB-07 | Proximity map of available cars within walking distance | SRS 3.2 | Must | No |
| MOB-08 | Each map car shows real-time fuel level, vehicle model, and distance to user | SRS 3.2 | Must | Partial |
| MOB-09 | Booking wizard Step 1: select vehicle + rental duration (start / end date & time) | SRS 3.2 | Must | No |
| MOB-10 | Booking wizard Step 2: choose add-ons — Premium Insurance, Child Seat, Extra Mileage Package | SRS 3.2 | Must | No |
| MOB-11 | Booking wizard Step 3: authorize security deposit (held funds) + process upfront payment | SRS 3.2 | Must | No |
| MOB-12 | Pedestrian / walking navigation to the precise car GPS location | SRS 3.3 | Must | No |
| MOB-13 | Proximity-gated unlock: "Unlock & Start Rental" stays disabled until phone GPS is <=15m from car's live GPS | SRS 3.3 | Must | Partial |
| MOB-14 | Digital Walkaround: user must take and submit 4 photos (front, back, left, right) before unlock | SRS 3.3 | Must | No |
| MOB-15 | Tap Unlock -> trigger sent to IoT gateway -> doors unlock | SRS 3.3 | Must | Yes |
| MOB-16 | After unlock, app instructs user to retrieve physical key from glovebox to start engine | SRS 3.3 | Must | No |
| MOB-17 | Rental time counter officially begins at the moment of unlock | SRS 3.3 | Must | No |
| MOB-18 | Return: user must park inside a valid geofenced drop-off zone, shown on the map | SRS 3.4 | Must | Partial |
| MOB-19 | Drop-off checklist: tick "keys left in glove compartment" and "personal belongings collected" | SRS 3.4 | Must | No |
| MOB-20 | "Lock & End Rental" sends Lock command; only after IoT confirms physical lock does the counter stop and the invoice generate | SRS 3.4 | Must | Yes |

### 3.2 Web Admin / Control Tower (ADM-)

Plain-language summary: this is the operator's command center in a browser. The operator owns the entire fleet, so this dashboard is where they watch every car live, configure zones and prices, approve users, and handle damage disputes — all without anyone visiting a car in person.

| ID | Requirement (one line) | Source clause | Priority | Hardware-dependent? |
|---|---|---|---|---|
| ADM-01 | High-frequency live tracking map of every car in the fleet (the "Control Tower") | SRS 4.1 | Must | Partial |
| ADM-02 | Color-coded car statuses: Available=Green, Rented=Blue, Out-of-Bounds/Alert=Red, Maintenance/Low-Fuel=Orange | SRS 4.1 | Must | Partial |
| ADM-03 | Fleet matrix to add / edit vehicles: brand, model, license plate, **and IMEI of the IoT device** | SRS 4.2 | Must | No |
| ADM-04 | Automated maintenance logs: track mileage via GPS odometer | SRS 4.2 | Must | Partial |
| ADM-05 | Auto-flag vehicles due for oil change, insurance renewal, technical inspection | SRS 4.2 | Must | No |
| ADM-06 | User moderation: review / approve / reject uploaded licenses & KYC | SRS 4.2 | Must | No |
| ADM-07 | "Blacklist" tool to ban fraudulent accounts | SRS 4.2 | Must | No |
| ADM-08 | Tariff manager: dynamic hourly / daily / seasonal pricing per vehicle category | SRS 4.3 | Must | No |
| ADM-09 | Automated grace period (e.g. 15 min) before late penalties apply | SRS 4.3 | Must | No |
| ADM-10 | Late-return auto-billing: on overrun without extension, auto-bill next full day + admin penalty (e.g. $50 flat or hourly), fully customizable | SRS 4.3 | Must | No |
| ADM-11 | Cross-user damage comparison: if User B reports a dent / dirt on pickup, system instantly flags previous driver User A | SRS 4.4 | Should | No |
| ADM-12 | Deposit forfeiture: admins review pre / post-rental photos and deduct damage fees from the held security deposit | SRS 4.4 | Must | No |

### 3.3 Backend, IoT Gateway & Geofencing (BE-)

Plain-language summary: this is the invisible engine. It speaks to the cars through the third-party GPS/IoT vendor, holds the geofence zones, ingests live telemetry every minute, runs the safety checks, and triggers theft alarms. This is where the differentiating, hardware-touching work lives.

| ID | Requirement (one line) | Source clause | Priority | Hardware-dependent? |
|---|---|---|---|---|
| BE-01 | Central backend brokering between Customer App, Web Admin, and the third-party GPS/IoT API | SRS 2 (architecture) | Must | No |
| BE-02 | Ingest inbound telemetry: live GPS lat/long, ignition state, central-locking status, fuel %/battery %, odometer | SRS 2 (telemetry) | Must | Partial |
| BE-03 | `POST /api/v1/vehicle/unlock` — opens central locking, starts rental counter, app switches to trip mode | SRS 5 (IoT API) | Must | Yes |
| BE-04 | `POST /api/v1/vehicle/lock` — closes locking, stops counter, generates invoice, returns car to map | SRS 5 (IoT API) | Must | Yes |
| BE-05 | `GET /api/v1/vehicle/status` polled every 60s — transmits lat/long, fuel %, odometer; updates live admin map | SRS 5 (IoT API) | Must | Partial |
| BE-06 | `POST /api/v1/vehicle/immobilize` — cuts starter motor relay, vehicle cannot restart, alerts police | SRS 5 (IoT API) | Must | Yes |
| BE-07 | Geofencing engine using PostGIS: operational urban zones + designated drop-off / station zones | SRS 6 (stack) / 3.4 | Must | No |
| BE-08 | Proximity calculation: real distance between phone GPS and car's live GPS to gate the <=15m unlock | SRS 3.3 | Must | Partial |
| BE-09 | Out-of-bounds detection: is a car inside its allowed zone? | SRS 4.1 / 3.4 | Must | Partial |
| BE-10 | Pre-lock automated checks before allowing end-rental: car inside perimeter? ignition off? all doors & windows shut? | SRS 3.4 | Must | Yes |
| BE-11 | Free-floating billing engine: per-minute / per-hour / per-day on-demand metering tied to unlock/lock events | SRS 3.3 / 3.4 | Must | No |
| BE-12 | Security deposit HOLD / pre-authorization (held, not captured) + later capture or release | SRS 3.2 / 4.4 | Must | No |
| BE-13 | Dead-zone fail-safe: BLE fallback commands directly to the smart box (if hardware supports) | SRS 7 (edge cases) | Should | Yes |
| BE-14 | Dead-zone fail-safe: emergency offline toll-free verification code as an alternative | SRS 7 (edge cases) | Should | Partial |
| BE-15 | Theft mode: car leaves allowed zone / crosses national border without active rental -> immediate high-priority admin alert | SRS 7 (edge cases) | Must | Partial |
| BE-16 | Theft mode: automated SMS to operations team | SRS 7 (edge cases) | Should | No |
| BE-17 | Theft mode: prepare a safe remote engine-kill command for admin confirmation | SRS 7 (edge cases) | Should | Yes |
| BE-18 | Vendor-agnostic gateway adapter so the same backend works against a simulator now and the real vendor later | SRS 2 (architecture) | Must | No |

```text
Required data flow (every BE- item lives somewhere on this path)

 [Customer App] <----> [Central Backend / API] <----> [3rd-party GPS/IoT API] <----> [Vehicle Smart Box]
       ^                       ^   ^                                                     (TCU / OBD-II)
       |                       |   |
   trip mode            [PostGIS zones]                inbound : GPS, ignition, lock state, fuel%, odometer
   unlock/lock          [Web Admin /                   outbound: Unlock / Lock / Immobilize
   proximity gate        Control Tower map]            telemetry cadence: every 60s
```

### 3.4 Non-Functional Requirements (NFR-)

Plain-language summary: the qualities the system must have regardless of any single feature — the database it runs on, how fast and securely it handles data, the platforms it ships to, and the languages it speaks.

| ID | Requirement (one line) | Source clause | Priority | Hardware-dependent? |
|---|---|---|---|---|
| NFR-01 | Database = PostgreSQL with the PostGIS extension for precise geofence boundary lookups | SRS 6 (stack) | Must | No |
| NFR-02 | Backend = Laravel, chosen for fast async webhook handling from GPS gateways | SRS 6 (stack) | Must | No |
| NFR-03 | Mobile app delivered on **both** iOS and Android (Flutter or React Native) | SRS 3 / 6 | Must | No |
| NFR-04 | Security: tokenized payment credentials, secure KYC document storage, authenticated APIs | SRS 3.1 | Must | No |
| NFR-05 | Scalability: reliably ingest 60s telemetry across the whole fleet without backlog | SRS 5 | Must | Partial |
| NFR-06 | Multi-language UI: Arabic, French, English with RTL support (Morocco market) | Proposal (Morocco) | Should | No |
| NFR-07 | Bi-directional, real-time data flow between cars, backend, app, and admin map | SRS 2 (architecture) | Must | Partial |

### 3.5 Inventory Count Summary

```text
Total requirements: 57   (MOB 20 | ADM 12 | BE 18 | NFR 7)

By priority:
  Must   = 50   (MOB 19 | ADM 11 | BE 14 | NFR 6)
  Should =  7   (MOB-05 | ADM-11 | BE-13, BE-14, BE-16, BE-17 | NFR-06)
  Could  =  0   (every item the client wrote is at least a Should)

By hardware dependency:
  No      (build & test fully today)       = 35
  Partial (build now, validate later)      = 14
  Yes     (gated on vendor + device)       =  8   (MOB-15, MOB-20, BE-03, BE-04,
                                                   BE-06, BE-10, BE-13, BE-17)
```

**One-line count:** 57 atomic requirements — 50 Must / 7 Should / 0 Could; of these only 8 are hard hardware-dependent (Yes) and 14 are Partial, meaning 49 of 57 (~86%) can be built and demonstrated now against a simulator before the GPS/IoT hardware arrives.

---

## 4. Gap Analysis — Where We Stand (requirement by requirement)

This section maps every requirement from Section 3 onto what Drivly actually contains today. The headline is simple: Drivly is a well-built peer-to-peer (P2P) car-rental marketplace — Turo/Getaround style — while the target is an operator-owned, fully automated, keyless free-floating fleet. The biggest gap is therefore a business-model mismatch, not a feature count. Roughly half of the *supporting* platform (auth, KYC, payments, discovery, booking, inspections, disputes, admin) is genuinely reusable. The half that defines the product — real IoT keyless access, geofencing, live fleet control, deposit holds, and on-demand billing — is not built. One screen *looks* like the connected-car core, but it is a UI prototype running fake on-device data, not working IoT.

Status legend: [DONE] built & usable - [PARTIAL] exists but needs rework - [MISSING] not built - [REPURPOSE] built for the wrong (P2P) model and must be re-aimed or removed.

> **On IDs:** the gap tables below group the 57 atomic requirements from Section 3 into build-relevant units, so the IDs are renumbered per pillar (e.g. MOB-1..MOB-17 here vs MOB-01..MOB-20 in Section 3). Cross-reference by **requirement name**, not by exact ID number.

Effort legend: S = ~1-3 dev-days - M = ~4-8 dev-days - L = ~2-3 dev-weeks - XL = ~4+ dev-weeks.

### 4.1 Mobile App (Customer) — Section 3.1-3.4

| ID | Requirement (short) | Status | What exists in Drivly today | What still must be built | Effort | Hardware-gated? |
|----|---------------------|--------|------------------------------|--------------------------|--------|-----------------|
| MOB-1 | Account: email / phone-OTP / social login | [DONE] | Full auth: register, login, Google, Apple, OTP send/verify, forgot/reset password (runs in demo mode without live keys) | Wire live keys (Firebase/Google/Apple); enforce phone-OTP at signup | S | No |
| MOB-2 | KYC: upload Gov ID/Passport AND Driver License | [PARTIAL] | KYC upload + admin review built (`KycService`, KycDocument, kyc submit/review, Filament review); photo upload via Spatie media | Enforce **two** mandatory docs (ID *and* license) as distinct document types | S | No |
| MOB-3 | Payment setup: tokenize card / Apple Pay / Google Pay; no booking without verified method | [PARTIAL] | Stripe integration + Wallet; card charge/confirm flow; payment_methods screen (demo mode) | Card tokenization / save-on-file; enforce "no booking without verified method"; wallet / Apple-Google Pay validation | M | No |
| MOB-4 | Discovery map: nearby available cars, live fuel, model, distance | [PARTIAL] | Discovery (home, search, car_detail, map, filters); google_maps_flutter + geolocator present | Map renders a **styled canvas placeholder** unless a real Maps key is added; no **live** telemetry markers; fuel/distance derive from static listing data, not a live GPS feed | M | Partly (live fuel/GPS) |
| MOB-5 | Booking wizard Step 1: vehicle + rental duration (start/end) | [DONE] | Booking flow: datetime -> summary -> success; pricing endpoint; daily-rental dates | Keep; extend duration model to support on-demand / hourly (see MOB-16) | S | No |
| MOB-6 | Booking wizard Step 2: add-ons (Premium Insurance, Child Seat, Extra Mileage) | [MISSING] | No add-on / option concept in booking | Add-on catalog + line items + price impact in booking summary and invoice | M | No |
| MOB-7 | Booking wizard Step 3: security deposit HOLD + upfront payment | [PARTIAL] | Upfront payment via Stripe exists | **Deposit hold / pre-authorization** (Stripe manual capture) and the held-funds lifecycle are not built | M | No |
| MOB-8 | Keyless pickup: pedestrian / walking navigation to car | [MISSING] | Map screen exists; no walking-navigation mode | Pedestrian routing to precise car GPS location | S | No |
| MOB-9 | Proximity-gated unlock: button locked until phone <=15m of car live GPS | [MISSING] | [gps_control_screen.dart](frontend/lib/features/trip/presentation/screens/gps_control_screen.dart) has an unlock button, but distance is **simulated on-device** — no real phone-vs-live-car GPS check | Real proximity gate: phone GPS vs car **live** IoT GPS, <=15m enforcement | M | Partial (distance math + button-gating are simulator-testable; only validation against a real car's live GPS is gated) |
| MOB-10 | Digital Walkaround: 4 photos (front/back/left/right) pre-inspection | [PARTIAL] | Inspection model + pre/post-trip inspection **with photo upload** (`TripService` creates a pre_trip Inspection); maps directly to the 4-photo idea | Enforce **exactly 4 labeled shots** (front/back/left/right) as a hard gate before unlock | S | No |
| MOB-11 | Unlock -> IoT trigger -> doors open -> retrieve key -> counter starts | [MISSING] | Simulated lock/unlock toggle only ([gps_control_screen.dart](frontend/lib/features/trip/presentation/screens/gps_control_screen.dart)) — no backend gateway, no real trigger | Real unlock command via gateway; "retrieve key from glovebox" UX; counter start tied to confirmed unlock | M | Yes |
| MOB-12 | Return: park inside valid geofenced drop-off zone (map) | [MISSING] | No geofence concept anywhere | Drop-off zones + in-zone validation on map | M | No (zone logic) |
| MOB-13 | Pre-lock automated checks: in perimeter? ignition off? doors/windows shut? | [MISSING] | None | Pre-lock check sequence reading live telemetry before allowing end-rental | M | Yes (telemetry) |
| MOB-14 | Drop-off checklist (keys left inside; belongings collected) | [MISSING] | None | Simple checklist gate before Lock & End | S | No |
| MOB-15 | "Lock & End Rental": Lock command -> IoT confirms locked -> counter stops -> invoice | [PARTIAL] | Trip end exists (`endTrip`: Completed, snapshots end mileage/fuel) but ends **manually**, with no IoT lock confirmation and a daily invoice | Lock command + confirmation gate; stop counter on confirmed lock; generate invoice from per-min/hr usage | M | Yes (lock confirm) |
| MOB-16 | In-trip billing model (free-floating per-minute / per-hour) | [PARTIAL] | Trip lifecycle is **daily-oriented**; extension is measured in **whole DAYS** (`extension_days`); no per-minute / per-hour counter | New billing engine: per-minute/hour metering, live running cost, on-demand "take now" | L | No |
| MOB-17 | Multi-language (Arabic / French / English) + RTL | [MISSING] | Locale is persisted (`MaterialApp.locale`) but **UI strings are English only**; no RTL. Currency & units already applied app-wide | Full i18n string extraction + AR/FR translations + RTL layout | M | No |

### 4.2 Web Admin — "Control Tower" — Section 4.1-4.4

| ID | Requirement (short) | Status | What exists in Drivly today | What still must be built | Effort | Hardware-gated? |
|----|---------------------|--------|------------------------------|--------------------------|--------|-----------------|
| ADM-1 | Live fleet map, high-frequency tracking, color-coded statuses | [MISSING] | Filament admin exists (Users/Cars/Bookings/Disputes/Promo) but **no live map / Control Tower** | Live tracking map; status colors (Available=Green, Rented=Blue, Alert=Red, Maintenance/Low-fuel=Orange); telemetry feed | L | Partly (live feed) |
| ADM-2 | Fleet matrix: add/edit vehicle with brand, model, plate, **IMEI** | [PARTIAL] | CarResource CRUD with make/model/plate exists | Car model has **no IMEI / IoT device id**; add a fleet vehicle model carrying IMEI + device link | M | No |
| ADM-3 | Automated maintenance logs (odometer-driven oil/insurance/inspection flags) | [MISSING] | Mileage field exists but no live odometer and no auto-flagging | Maintenance rules engine driven by GPS odometer; auto-flags + renewal tracking | M | Partly (live odometer) |
| ADM-4 | User moderation: approve/reject KYC + license | [DONE] | kyc pending/review endpoints + Filament; users suspend/unsuspend | Confirm review covers both ID and license (see MOB-2) | S | No |
| ADM-5 | Blacklist tool to ban fraudulent accounts | [PARTIAL] | suspend/unsuspend user exists | Dedicated blacklist (hard ban) distinct from suspend | S | No |
| ADM-6 | Geofencing config (operational zones + drop-off zones) | [MISSING] | **No PostGIS, no spatial capability** — geo is plain decimal lat/lng columns + a `[lat,lng]` index | PostGIS + zone editor (draw/edit polygons); zone storage & lookup | L | No |
| ADM-7 | Dynamic pricing: hourly/daily/seasonal tariff manager per category | [MISSING] | Car has a `dynamic_pricing_enabled` **flag only** (no engine); daily_price + discount %s; PricingService is daily | Tariff matrix + dynamic pricing engine per vehicle category | L | No |
| ADM-8 | Penalty matrix: grace period + late-return auto-billing | [MISSING] | Trip can reach `overdue` status but no auto-billing | Grace period (e.g. 15 min); auto-bill next full day + admin penalty; fully customizable | M | No |
| ADM-9 | Automated claims: cross-user damage comparison (flag previous driver) | [MISSING] | Disputes exist (file + resolve/escalate) but no cross-user auto-flag | Compare pre/post photos across consecutive renters; auto-flag prior driver | M | No |
| ADM-10 | Deposit forfeiture: deduct damage fees from held deposit | [MISSING] | Dispute resolve exists; **no deposit hold to deduct from** | Deposit-deduction workflow tied to the MOB-7 hold | M | No |
| ADM-11 | Admin disputes review (file + resolve/escalate) | [PARTIAL] | DisputeService + customer file + admin resolve/escalate + Filament DisputeResource | Add deposit / photo-comparison tie-ins (ADM-9/10) | S | No |

### 4.3 Backend, IoT Gateway & Geo — Section 3 (architecture) + IoT endpoints

| ID | Requirement (short) | Status | What exists in Drivly today | What still must be built | Effort | Hardware-gated? |
|----|---------------------|--------|------------------------------|--------------------------|--------|-----------------|
| BE-1 | Laravel backend + token auth + admin panel + queues | [DONE] | Laravel 12, Sanctum, Filament 3, Horizon (Redis), Reverb (WS), ~90 REST routes | Keep as foundation | — | No |
| BE-2 | PostgreSQL + **PostGIS** for geofencing | [MISSING] | Prod target Postgres + Redis, but **no PostGIS**; geo is plain lat/lng decimals | Install/enable PostGIS; spatial columns + indexes + zone lookups | M | No |
| BE-3 | IoT gateway: vendor adapter with unlock/lock/immobilize/getStatus | [MISSING] | Only an **on-device simulation** ([gps_device_provider.dart](frontend/lib/features/trip/domain/providers/gps_device_provider.dart)) — no backend gateway at all | `VehicleGateway` interface + SimulatedGateway (now) + VendorGateway (on vendor docs) | L | Yes (VendorGateway) |
| BE-4 | POST /api/v1/vehicle/unlock (open lock, start counter, trip mode) | [MISSING] | None on backend | Command endpoint + state transition + counter start | M | Yes |
| BE-5 | POST /api/v1/vehicle/lock (close lock, stop counter, generate invoice) | [MISSING] | None on backend | Command endpoint + lock confirmation + invoice + return to map | M | Yes |
| BE-6 | GET /api/v1/vehicle/status every 60s (lat/long, fuel %, odometer) | [MISSING] | `Trip.last_known_lat/lng` set by a **manual phone POST** (`/trips/{trip}/location`) — not an IoT feed; no live fuel/odometer | 60s telemetry ingest (webhook/poller) -> live store -> admin map | L | Yes (real cadence) |
| BE-7 | POST /api/v1/vehicle/immobilize (cut starter relay; alert police) | [MISSING] | Simulated immobilizer toggle only (on-device) | Real immobilize command + alerting | M | Yes |
| BE-8 | Live telemetry fields on a fleet vehicle (live GPS/fuel/ignition/lock/odometer) | [MISSING] | Car has **static** listing lat/lng; **no** IMEI, no live telemetry, no live odometer/fuel | Telemetry schema + ingestion + history | M | Partly |
| BE-9 | Theft mode: out-of-zone w/o active rental -> high-priority alert + SMS + prepared engine-kill | [MISSING] | None | Geofence-violation watcher; admin alert + SMS; staged remote kill command | M | Partly |
| BE-10 | Fail-safe: BLE fallback to smart box + offline unlock code (dead zones) | [MISSING] | None | BLE command path (hardware-dependent) + offline verification code fallback | L | Yes (BLE) |
| BE-11 | Payments backend: charges + webhook | [DONE] | Stripe + PaymentService + Stripe webhook | Add deposit pre-auth / manual capture (MOB-7) | — | No |
| BE-12 | Push notifications + device tokens | [DONE] | FCM via Firebase, DeviceToken, register/unregister | Keep; reuse for theft/late alerts | — | No |

### 4.4 Non-Functional / Cross-Cutting

| ID | Requirement (short) | Status | What exists today | What still must be built | Effort | Hardware-gated? |
|----|---------------------|--------|--------------------|--------------------------|--------|-----------------|
| NFR-1 | Operator owns the entire fleet (single owner, zero-human) | [REPURPOSE] | P2P: cars are **host-owned** (`Car.host_id` FK to users), host roles, host verification | Re-aim to operator-owned: remove host ownership; admin manages all cars | M | No |
| NFR-2 | Live credentials (Stripe/Firebase/Maps/SMS) | [PARTIAL] | Stripe, Firebase, Apple/Google sign-in and Maps all run in **demo mode** without real keys | Wire client-provided live keys (per proposal, Anouar supplies) | S | No |
| NFR-3 | Real-time channel for live map / trip | [DONE] | Laravel Reverb (WS) + Flutter web_socket_channel | Connect to the telemetry stream | S | No |

### 4.5 The "Connected-Car" Screen Is a Prototype, Not Working IoT

To be brutally clear for both Anouar and the team: the existing connected-car control center is a convincing demo, but none of it talks to a real car.

- [gps_control_screen.dart](frontend/lib/features/trip/presentation/screens/gps_control_screen.dart) provides lock/unlock and engine-immobilizer toggles plus a telemetry readout.
- [gps_device_provider.dart](frontend/lib/features/trip/domain/providers/gps_device_provider.dart) generates **all of that state on the phone itself** — fake telemetry, fake lock state, fake proximity.
- Its own code comments confirm it: *"the prototype of the client's core idea ... simulated on-device so the flow is fully demoable without the third-party GPS provider's API."*

There is **no backend gateway, no real IoT device, no geofencing, and no real proximity gate** behind it. It validates the *flow and UX*, which is genuinely useful, but it is 0% of the real telematics integration. The upside (see Section 6 / feasibility): this same screen becomes the ideal front-end for a real `VehicleGateway` once the simulator and vendor adapter are built behind it.

```text
  WHAT THE PROTOTYPE DOES TODAY           WHAT THE TARGET NEEDS
  ---------------------------             ---------------------------------
  [Phone UI]                             [Phone UI]
     |  (button tap)                        |  unlock/lock command
     v                                      v
  [on-device fake state]  <-- ALL FAKE   [Central Backend / VehicleGateway]
     ^                                      |   (Simulated now / Vendor later)
     |  fake telemetry                      v
  (no backend, no car)                   [Third-Party GPS/IoT API] <-> [Car Smart Box]
                                              ^  real GPS/fuel/lock/odometer (60s)
```

### 4.6 Reuse Ledger — every Drivly capability classified

KEEP = use as-is or with light tweaks - REPURPOSE = re-aim from P2P to operator model - REMOVE = not needed in the target product.

| Drivly capability | Decision | Why | Notes |
|-------------------|----------|-----|-------|
| Email / phone-OTP / social auth | KEEP | Identical need in target | Wire live keys |
| KYC upload + admin review | KEEP | Target requires ID + license KYC | Enforce both doc types |
| Stripe payments + webhook | KEEP | Core to target | Add deposit pre-auth |
| Wallet + transactions | KEEP | Useful for balances/refunds | Optional cash/wallet per open questions |
| Discovery (home/search/car_detail/filters) | KEEP | Maps to proximity discovery | Needs live data feed |
| Map screen | KEEP | Reusable shell | Add real Maps key + live markers |
| Booking wizard (dates -> pricing -> pay) | KEEP | Direct reuse for Steps 1 & 3 | Add Step 2 add-ons; on-demand mode |
| Pre/post-trip inspection + photo upload | KEEP | Maps to 4-photo Digital Walkaround | Enforce 4 labeled shots |
| Trip start/end/extend lifecycle | KEEP | Skeleton reusable | Re-bill per-min/hr; gate on IoT |
| Disputes (file + resolve/escalate) | KEEP | Foundation for claims | Add cross-user flag + deposit deduct |
| Filament admin (users/cars/bookings/disputes/promo) | KEEP | Back-office base | Extend into Control Tower |
| Reviews / ratings | KEEP | Optional but harmless | Lower priority |
| Push notifications + device tokens | KEEP | Alerts / comms | Reuse for theft/late alerts |
| Generic file uploads (POST /uploads) | KEEP | Used by KYC / inspection | — |
| Settings (currency/units/locale persistence) | KEEP | Already app-wide | Add real translations |
| Reverb WebSockets | KEEP | Powers live map | Connect telemetry |
| Host app screens (dashboard, add_car, cars, bookings) | REPURPOSE | No external hosts; operator manages fleet | Become operator / fleet admin UI |
| Host roles / host verification | REPURPOSE | Operator is the only "host" | Collapse into admin / ops roles |
| Instant / request booking | REPURPOSE | Target is on-demand "take now" or time-slot | Simplify booking modes |
| Car model (host-owned listing) | REPURPOSE | Must become operator fleet vehicle | Add IMEI, telemetry, zone link; drop `host_id` |
| Host<->renter chat | REPURPOSE | No host counterpart | At most an optional support channel |
| Host payouts / earnings (Earning, payouts) | REMOVE | Operator owns all revenue — no payouts | Earning model N/A |
| Daily-only billing assumptions | REMOVE | Replaced by per-min/hr free-floating | Keep daily as one tariff option |

### 4.7 Where We Stand — pillar rollup

Percentages are a directional read of progress toward the *target* product (not toward "a P2P app," which is far more complete). This view complements the Section 1 dashboard — it swaps the cross-cutting pillar for a "business-model fit" pillar — and uses the same per-pillar figures.

| Pillar | % toward target | One-line reason |
|--------|-----------------|------------------|
| Customer Mobile App | ~50% | Auth, KYC, booking, inspection, map shell and settings reuse well; keyless IoT, proximity gate, deposit, add-ons, per-min billing and i18n are missing |
| Web Admin / Control Tower | ~30% | Filament base with user/car/booking/dispute/promo exists; live map, geofence editor, tariff/penalty matrix, maintenance logs and telemetry are missing |
| Central Backend + IoT/Geo | ~20% | Strong Laravel/payments/auth/queues/WS base; no IoT gateway, no PostGIS/geofencing, no telemetry ingest, no theft/BLE fail-safes |
| Business-model fit | ~40% | Built as a P2P marketplace; needs re-aiming to an operator-owned zero-human fleet (the single biggest gap) |
| **Overall** | **~40-45%** | Half the supporting platform is a real head start; the differentiating telematics + geofencing + on-demand core is still to build |

---

## 5. Target Architecture, Data Model & MVC Design

This section is the engineering blueprint for the **Automated Car-Sharing Platform**. It is design-only — no implementation code — written so Anouar can follow the shape of the system, while the dev team can build directly from it. The single most important decision is the **VehicleGateway adapter**: it lets us build, demo and test roughly 90-95% of the platform *now*, against a software simulator, then plug in the real GPS/IoT vendor later with no rewrite. Everything else hangs off that decision.

A short orientation before the detail: Drivly today is a **peer-to-peer marketplace** (hosts list their own cars). The target is an **operator-owned fleet** of keyless IoT cars with zero on-site staff. This architecture keeps the genuinely reusable plumbing (auth, KYC, Stripe, bookings, inspections, disputes, the Filament admin) and adds the differentiating spine the model requires — IoT commands, live telemetry, geofencing, deposits, dynamic pricing and penalties.

### 5.1 System architecture (target)

Plain-language version: the customer's phone and the admin Control Tower both talk to **one central Laravel backend**. That backend never talks to a car directly — it talks to a **Gateway adapter**, which either pretends to be a car (simulator, today) or relays to the **third-party GPS/IoT API** controlling the real **Smart Box** in each car (later). Telemetry flows *in* from the car roughly every 60 seconds; commands (unlock / lock / immobilize) flow *out*.

```text
        TELEMETRY IN  (every ~60s: lat/lng, ignition, lock state, fuel%, odometer)
   <==========================================================================

  +---------------------+        +---------------------+
  | Customer App        |        | Admin Control Tower |
  | (Flutter, iOS/Andr) |        | (Web - Filament)    |
  +----------+----------+        +----------+----------+
             |  HTTPS/JSON + WebSocket (live updates)  |
             +--------------------+--------------------+
                                  |
                                  v
                 +-------------------------------------+
                 |        CENTRAL BACKEND (Laravel)    |
                 |  REST API (Sanctum) | Filament Admin|
                 |  Queues (Horizon/Redis) | Reverb WS |
                 |  GeofenceService | DepositService   |
                 |  PenaltyService | TelemetryIngest   |
                 +----+-------------------+------------+
                      |                   |
   side services      |                   |   VehicleGatewayService
  +----------------+  |                   v   (one interface)
  | Stripe (pay,   |<-+        +----------------------------+
  | deposit holds) |           |   VehicleGateway (adapter) |
  | Google Maps    |<-+        |  Simulated <OR> Vendor impl |
  | SMS (theft/OTP)|  |        +-------------+--------------+
  | Push (FCM)     |<-+                      |
  +----------------+  |        COMMANDS OUT  |  (unlock/lock/immobilize)
  +----------------+  |                      v
  | PostgreSQL +   |<-+        +----------------------------+
  | PostGIS (geo)  |           | Third-Party GPS / IoT API  |   <-- webhook -->
  | Redis (cache,  |           +-------------+--------------+      telemetry
  | queue, locks)  |                         |
  +----------------+                         v
                              +----------------------------+
                              | Vehicle Smart Box (TCU /   |
                              | OBD-II dongle, per car)    |
                              +----------------------------+
   ==========================================================================>
        COMMANDS OUT (backend -> gateway -> vendor -> car)
```

Key points for the client:
- **One backend, two front-ends.** The phone app and the Control Tower share the same API and database, so what an admin sees on the live map is what the cars report.
- **The car is never trusted blindly.** Every command and every telemetry reading passes through the backend, which logs it, checks geofences and updates billing.
- **The side services are the accounts you (Anouar) provide:** Stripe, Google Maps, an SMS provider, and push (Firebase). The DB is PostgreSQL with the **PostGIS** geo-extension — which Drivly does **not** have today and which we must add.

### 5.2 The VehicleGateway adapter pattern (the linchpin)

Plain-language version: we define a single fixed "remote control" contract for a car — *unlock, lock, immobilize, release immobilizer, read status*. We then write **two boxes that obey that contract**: a fake one we use today, and a real one we drop in when the vendor hardware arrives. The rest of the platform only ever talks to the contract, so it never knows or cares which box is plugged in.

#### Interface (illustrative signature, not code)

```text
interface VehicleGateway
  unlock(vehicle)            -> CommandResult { accepted, commandId, latencyMs }
  lock(vehicle)              -> CommandResult
  immobilize(vehicle)        -> CommandResult   // cut starter relay (anti-theft)
  releaseImmobilizer(vehicle)-> CommandResult
  getStatus(vehicle)         -> Telemetry { lat, lng, ignition, locked, fuelPct, odometer, at }
```

#### Two implementations

| Implementation | Available | Behaviour | Used for |
|---|---|---|---|
| **SimulatedGateway** | Today (new backend code) | Holds in-memory/DB state per vehicle; applies commands with a realistic delay; emits synthetic telemetry on a timer; can fake dead-zones and out-of-bounds | Build + demo + automated tests of the *entire* flow before hardware exists |
| **VendorGateway** | After M4 (vendor API docs + test device arrive) | Translates our calls into the vendor's real HTTP API; ingests the vendor's webhook/poll telemetry | Real physical unlock/lock/immobilize and real telemetry |

Switching is a **one-line configuration change** (which class the container binds), not a code rewrite. This is what makes the no-hardware build honest: the customer journey, the Control Tower, geofencing, deposits, pricing and penalties are all exercised against `SimulatedGateway` end-to-end.

> **Precursor that already exists (on-device only):** [gps_device_provider.dart](frontend/lib/features/trip/domain/providers/gps_device_provider.dart) is an *on-device, fully simulated* early version of this idea — it fakes lock/unlock, an engine immobilizer, telemetry (battery/signal/nudged GPS) and a command history, with **no backend, no real IoT, no geofencing and no real proximity gate** behind it. Its own comments call it "the prototype of the client's core idea ... simulated on-device so the whole flow is demoable before the third-party GPS API is wired up." For the target product this logic **moves to the backend** as `SimulatedGateway`, so the admin map and billing see the same simulated state the phone does. The Flutter screen [gps_control_screen.dart](frontend/lib/features/trip/presentation/screens/gps_control_screen.dart) becomes a thin client of the backend gateway rather than the source of truth.

#### How telemetry arrives

Telemetry is **pushed in**, not asked for screen-by-screen. Two supported modes, both normalized into one internal shape:

```text
  (A) Vendor WEBHOOK  -->  POST /webhooks/telemetry  --+
                                                       +--> normalize --> TelemetryEvent
  (B) 60s POLLER (queued job) --> gateway.getStatus() -+        |
                                                                v
                              writes vehicle live fields, runs GeofenceService,
                              pushes to Reverb (live map), checks pre-lock rules
```

Whether the vendor offers webhooks or only polling, the backend converts each reading into a single `TelemetryEvent` record. Downstream logic (live map, geofence check, billing) only ever reads `TelemetryEvent` / the vehicle's live fields — so the ingest mechanism can change without touching the rest.

### 5.3 Geofencing design (PostGIS)

Plain-language version: we draw zones on a map as polygons — *where cars may operate*, *where they may be parked/returned*, and *where they must never go*. The database answers three geographic questions fast: "is this car inside a valid drop-off zone?", "is the phone within 15 m of the car?", and "has a car left its allowed area?".

> **Today's gap [MISSING]:** Drivly stores only plain `lat` / `lng` decimal columns with a simple `[lat,lng]` index and has **no PostGIS, no polygons and no spatial queries**. Adding the PostGIS extension and `geometry`/`geography` columns is net-new work and a prerequisite for the whole free-floating model.

| Zone type | Geometry | Used for |
|---|---|---|
| **Operational zone** | Polygon | The city area where cars may be driven/parked at all |
| **Drop-off / parking zone** | Polygon(s) | A return is valid only if the car is *inside one of these* |
| **No-go / border zone** | Polygon | Crossing into these without an active rental -> theft alert |

Three spatial operations:

```text
1. VALID RETURN?      ST_Contains(dropoff_zone.geom, car.point)        -> true/false
2. PROXIMITY UNLOCK   ST_Distance(phone.point, car.live_point) <= 15m  -> gate the button
3. OUT-OF-BOUNDS      NOT ST_Contains(operational_zone.geom, car.pt)   -> raise alert
                      OR ST_Contains(no_go_zone.geom, car.point)
```

PostGIS gives correct, fast point-in-polygon and great-circle distance checks — far more reliable than hand-rolled lat/lng math, especially for the <=15 m proximity gate and irregular city boundaries.

### 5.4 Laravel MVC mapping (new vs reused)

Plain-language version: the table shows, for each capability, what database **Model**, **Controller** (API), **Service** (business logic) and **View layer** (Filament admin page and/or JSON API resource) is needed — and whether it already exists in Drivly or is new.

| Capability | Model | Controller (API) | Service | View / Admin | Status |
|---|---|---|---|---|---|
| Fleet vehicle (operator-owned + IMEI + live telemetry) | **Vehicle** (evolve `Car`) | VehicleController | (uses gateway) | VehicleResource (rework CarResource) | [REPURPOSE] |
| IoT command bus | **VehicleCommand** (new) | VehicleControlController (new) | **VehicleGatewayService** (new) | Command log page (new) | [MISSING] |
| Live telemetry ingest | **TelemetryEvent** (new) | TelemetryWebhookController (new) | TelemetryIngestService (new) | (feeds live map) | [MISSING] |
| Geofencing / zones | **GeoZone** (new) | GeoZoneController (new) | **GeofenceService** (new) | GeoZone map editor (new) | [MISSING] |
| Control Tower live map | — | — | (reads telemetry) | **Live Fleet Map page** (new) | [MISSING] |
| Proximity-gated unlock (<=15m) | (uses Vehicle live GPS) | VehicleControlController | GeofenceService | — | [MISSING] |
| Pre-lock automated checks | (reads telemetry) | TripController | GeofenceService + TripService | — | [MISSING] |
| Security deposit (hold/forfeit) | **Deposit** (new) | DepositController (new) | **DepositService** (new) + PaymentService | shown on Rental page | [MISSING] |
| Dynamic pricing tariffs | **Tariff** (new) | TariffController (new) | PricingService (extend) | **Tariff Matrix page** (new) | [PARTIAL] |
| Penalties / grace / late fees | **PenaltyRule** (new) | — | **PenaltyService** (new) | **Penalty Matrix page** (new) | [MISSING] |
| Maintenance logs (odometer-driven) | **MaintenanceLog** (new) | — | MaintenanceService (new) | Maintenance page (new) | [MISSING] |
| Booking add-ons | **Addon** + **RentalAddon** (new) | (in booking flow) | BookingService (extend) | Addon catalog page (new) | [MISSING] |
| Rental (free-floating billing) | **Trip** -> evolve to per-min/hr | TripController (rework) | TripService (rework) | Rental page (rework) | [REPURPOSE] |
| Auth / OTP / social | User | AuthController | — | UserResource | [DONE] reuse |
| KYC upload + review | KycDocument, HostVerification\* | KycController | KycService | KYC review (reuse) | [DONE] / [REPURPOSE] |
| Payments + wallet | Payment, Wallet | BookingController (pay) | PaymentService, WalletService | — | [DONE] reuse |
| Booking wizard | Booking | BookingController | BookingService | BookingResource | [DONE] extend |
| 4-photo walkaround | Inspection, CarPhoto | TripController | TripService | Inspection view | [PARTIAL] enforce |
| Disputes + deduction | Dispute | DisputeController | DisputeService | DisputeResource | [DONE] extend |
| Reviews, push, uploads | Review, DeviceToken | several | Notification / Review | several | [DONE] reuse |

\* `HostVerification` and host roles are **repurposed** into operator/admin fleet management; host payouts/earnings (`Earning`, `Wallet` withdraw) become N/A for the customer because the operator owns all revenue. The 4-photo walkaround is marked [PARTIAL] because the inspection model and photo upload exist, but the strict "4 photos required before unlock" enforcement does not yet.

### 5.5 Flutter clean-architecture mapping

Plain-language version: the app already separates each feature into **data** (API calls), **domain** (state/providers) and **presentation** (screens). New work slots into the same shape; nothing about the layering needs to change.

Existing pattern (confirmed in repo): each feature folder has `data/`, `domain/providers/`, `presentation/screens/` — e.g. `features/trip/` holds [trip_service.dart](frontend/lib/features/trip/data/trip_service.dart), [gps_device_provider.dart](frontend/lib/features/trip/domain/providers/gps_device_provider.dart) and screens like [active_trip_screen.dart](frontend/lib/features/trip/presentation/screens/active_trip_screen.dart).

| New / changed piece | Layer | Where it goes |
|---|---|---|
| **fleet / keyless** feature | new feature folder | `features/keyless/{data,domain,presentation}` |
| Backend-driven vehicle control client | data | `keyless/data/vehicle_gateway_service.dart` (replaces on-device sim) |
| Telemetry stream provider (WebSocket) | domain | `keyless/domain/providers/telemetry_provider.dart` |
| Proximity-gate provider (phone GPS vs car live GPS) | domain | `keyless/domain/providers/proximity_provider.dart` |
| Geofence-aware map (real Google Maps tiles + zone polygons) | presentation | extend the discovery [map_screen.dart](frontend/lib/features/discovery/presentation/screens/map_screen.dart) |
| Pre-lock checklist + return flow | presentation | `keyless/presentation/screens/return_screen.dart` |
| Deposit / add-ons in booking | data + presentation | extend `features/booking` |

Note on the map: [map_screen.dart](frontend/lib/features/discovery/presentation/screens/map_screen.dart) today renders a **styled-canvas placeholder** (real Google Maps tiles only appear when a real Maps key is supplied — Maps currently runs in demo mode). The geofence-aware map adds live car positions and zone polygons on top of real tiles. The existing [gps_control_screen.dart](frontend/lib/features/trip/presentation/screens/gps_control_screen.dart) is **re-pointed** to call the backend gateway and subscribe to live telemetry instead of driving the on-device simulator.

### 5.6 ERD sketch (new/changed tables and links to existing)

Plain-language version: this shows the new tables (vehicle telemetry, zones, commands, deposits, tariffs, penalties, maintenance, add-ons) and how they connect to the existing User / Booking / Trip / Payment / Inspection / Dispute tables.

```text
                  +-----------+                         +-----------+
                  |   User    |                         |  GeoZone  |  (PostGIS polygon)
                  +-----------+                         | id        |
                       | 1                              | type:     |
                       |                                |  oper/drop/nogo
                       | books                          | geom      |
                       v *                              +-----+-----+
+-----------+     +-----------+     +-----------+             | drop-off lookup
|  Tariff   |---->|  Booking  |---->|   Rental  |<------------+
| id        | *   | id        | 1 1 | (Trip++)  |
| category  |     | user_id   |     | status    |        +----------------+
| hourly/   |     | vehicle_id|     | start/end |        | RentalAddon    |
| daily/    |     | tariff_id |     | bill_mode |<-------| rental_id      |
| seasonal  |     +-----+-----+     | (min/hr/  |   *    | addon_id ------+--> Addon
+-----------+           |           |  day)     |        +----------------+    (insurance,
                        | 1         +--+--+--+--+                              child seat,
                        v *            |  |  |  | 1                            extra mileage)
                  +-----------+        |  |  |  +-----> +-------------+
                  |  Payment  |        |  |  |          | Inspection  | (4-photo walkaround)
                  +-----------+        |  |  |          +-------------+
                        | 1           1|  |  | *
                        v *            v  |  v        +-------------+
                  +-----------+  +---------+  +------->|   Dispute   |--> cross-user
                  |  Deposit  |  | Vehicle |          +-------------+    compare +
                  | hold/auth |  | (Car++) |                            deduct from
                  | forfeited |  | imei    |                            Deposit
                  +-----------+  | live_lat/lng
                                 | ignition, locked
                                 | fuel_pct, odometer
                                 | status (color)
                                 +----+----+----+--------------+
                                      | 1  | 1  | 1            |
                            *         v    | *  v *            v *
                      +------------+  +-----+----+  +----------------+  +---------------+
                      |VehicleCmd  |  |Telemetry |  | MaintenanceLog |  |  PenaltyRule  |
                      |unlock/lock/|  |Event     |  | type:oil/insp/ |  | grace_min,    |
                      |immobilize  |  |lat/lng,  |  | insurance,     |  | late_fee,     |
                      |status,result| |fuel,odo, |  | due_at,        |  | auto_day_bill |
                      +------------+  |ignition  |  | odometer_at    |  +---------------+
                                      +----------+  +----------------+
```

New fields on the evolved **Vehicle** (was `Car`): `imei`, live `latitude/longitude`, `ignition_state`, `lock_state`, `fuel_pct`, `odometer`, `status` (Available / Reserved / Rented / Returning / Maintenance / LowFuel / Alert / Offline), and a link to its operational `GeoZone`. The `host_id` column is dropped or fixed to a single operator (no per-car host).

### 5.7 Example IoT API contracts

Plain-language version: these are the four core endpoints the client's spec asks for, with a short illustrative request/response and what the software does as a result. These are served by *our* backend; internally each delegates to the VehicleGateway.

**POST /api/v1/vehicle/unlock** — opens central locking, starts the rental counter.
```text
Req : { "vehicle_id":"v_123", "rental_id":"r_88", "phone_lat":33.59, "phone_lng":-7.61 }
Res : { "accepted":true, "command_id":"cmd_5f", "lock_state":"unlocked", "latency_ms":820 }
Consequence: proximity (<=15m) re-verified -> Rental -> InTrip, counter starts,
             app shows "retrieve key from glovebox", VehicleCommand logged.
```

**POST /api/v1/vehicle/lock** — closes locking, stops counter, generates invoice.
```text
Req : { "vehicle_id":"v_123", "rental_id":"r_88" }
Res : { "accepted":true, "command_id":"cmd_60", "lock_state":"locked" }
Consequence: only allowed after pre-lock checks pass -> counter stops, invoice
             calculated (incl. penalties), deposit hold released or partially
             captured, vehicle returns to map as Available.
```

**GET /api/v1/vehicle/status** — live snapshot (also pushed every ~60s).
```text
Res : { "vehicle_id":"v_123","lat":33.5912,"lng":-7.6101,"ignition":"off",
        "locked":true,"fuel_pct":62,"odometer":48213,"at":"2026-06-26T10:00:00Z" }
Consequence: writes TelemetryEvent, updates live admin map color, runs geofence
             check, feeds maintenance odometer flags.
```

**POST /api/v1/vehicle/immobilize** — cuts starter relay (anti-theft).
```text
Req : { "vehicle_id":"v_123", "reason":"out_of_bounds" }
Res : { "accepted":true, "command_id":"cmd_61", "engine":"immobilized" }
Consequence: vehicle cannot restart, high-priority admin alert raised, SMS to ops.
```

**Telemetry ingest (vendor -> us)** — normalized into a `TelemetryEvent`.
```text
POST /webhooks/telemetry
Body: { "imei":"86xxxxxx","ts":"2026-06-26T10:01:00Z","gps":{"lat":33.59,"lng":-7.61},
        "ign":1,"lock":0,"fuel":61,"odo":48230 }
Consequence: normalize -> TelemetryEvent -> update Vehicle live fields ->
             GeofenceService.check() -> if out-of-bounds w/o active rental -> theft mode.
```

### 5.8 State machines

Plain-language version: two simple "what state can it be in next" charts — one for a car, one for a rental. These drive the map colors and the billing.

**(a) Vehicle status** (drives Control Tower colors: Green / Blue / Red / Orange)

```text
            reserve            unlock              lock(valid return)
 AVAILABLE --------> RESERVED --------> RENTED ----------------------> AVAILABLE
   ^  ^                |                  |  \                            ^
   |  |  reservation   |   (in trip)      |   \ leaves zone w/o rental    |
   |  +----------------+                  |    +--> ALERT/OUT-OF-BOUNDS --+ (resolve)
   |                                      |          (immobilize, SMS)
   |   maintenance done                   v  return started
   +---------------------- MAINTENANCE   RETURNING --(pre-lock fail)--> RENTED
   |                          ^
   |   refuel/resolve         | low fuel / due service
   +------- LOW-FUEL <--------+        OFFLINE (no telemetry >N min) -- any state
                                       (recover on next TelemetryEvent)
```

**(b) Rental / Trip lifecycle**

```text
 BOOKED --auth deposit--> DEPOSIT_AUTHORIZED --arrive--> AT_VEHICLE
                                                             |
                                              proximity <=15m + 4 photos
                                                             v
                                                     PROXIMITY_OK
                                                             | tap Unlock
                                                             v
   +------------------ overdue past return -------->  UNLOCKED / IN_TRIP
   |                  (grace -> PenaltyRule)               |
   v                                                       | tap End
 OVERDUE/PENALTY --extend or return--+                     v
                                     +-------------> RETURN_REQUESTED
                                                           |
                                          PRE_LOCK_CHECKS (in zone? ign off?
                                          doors/windows shut?)
                                            | pass            | fail
                                            v                 +--> back to IN_TRIP
                                     LOCKED / COMPLETED
                                            |
                                            v
                                        INVOICED --(damage claim)--> DISPUTE_OPEN
                                                                     (deduct deposit)
```

These two machines are the contract between the IoT layer, the geofence/penalty services and the UI: the map color comes from (a); the customer's screen and billing come from (b).

---

## 6. End-to-End Flows & All Scenarios

This section walks through exactly how the **Automated Car-Sharing Platform** should behave, step by step, in the normal case and in every important "what if" case. Each flow lists the steps in plain order and then shows a small diagram you can follow with your finger.

Two framing points before the flows:
- **The flows below describe the TARGET product, not what Drivly does today.** Drivly is a peer-to-peer (Turo/Getaround-style) marketplace where individual hosts list their own cars. The target is an operator-owned, free-floating fleet with keyless IoT access and zero on-site human contact. Several Drivly pieces are reused (noted inline), but the end-to-end keyless/IoT/geofence/deposit flow does **not** exist yet.
- Today's [gps_control_screen.dart](frontend/lib/features/trip/presentation/screens/gps_control_screen.dart) and [gps_device_provider.dart](frontend/lib/features/trip/domain/providers/gps_device_provider.dart) already render lock / unlock / immobilize / telemetry, but **all of it is simulated on the phone** — there is no Backend gateway, no real geofence, and no real proximity gate behind it. The real version is delivered by the **VehicleGateway** adapter (Simulated implementation now, Vendor implementation later).

Throughout, five actors do the work:

| Actor | Who / What it is |
|-------|------------------|
| **User** | The customer holding the phone |
| **App** | The mobile app (Flutter) running on the phone |
| **Backend** | The Laravel central server + database (the brain) |
| **IoT** | The third-party GPS gateway + the in-car Smart Box (TCU / OBD-II dongle) |
| **Admin** | The web "Control Tower" and the operations team behind it |

A reminder of how these connect (from the architecture section):

```text
[User+App] <--HTTPS/WebSocket--> [Backend/API] <--vendor API/webhook--> [IoT Gateway] <--cellular/BLE--> [Smart Box]
                                       ^
                                       |  (live map, commands, alerts)
                                  [Admin Control Tower]
```

Where the requirement uses the IoT reference endpoints, they appear inline: `POST /vehicle/unlock`, `POST /vehicle/lock`, `GET /vehicle/status` (every 60s), `POST /vehicle/immobilize`.

---

### 6.1 The Happy Path (Golden Flow), end to end

In plain words: a first-time user signs up and proves who they are, sees live cars on a map, books one, walks to it, unlocks it with the app, drives, returns it inside an allowed zone, locks it, gets an invoice with the deposit released, and leaves a review — with **zero human contact** at any point.

**Steps**

1. **User** opens the app for the first time.
2. **User** registers (email / phone-OTP / social) and verifies the OTP. *(Reuses Drivly auth — [DONE].)*
3. **User** completes KYC: uploads **Government ID/Passport AND Driver License** (two documents). **Admin** (or an auto-rule) approves. *(Reuses Drivly KYC upload + admin review — [PARTIAL]; dual-doc enforcement to confirm.)*
4. **User** adds a payment method — card tokenized, or Apple Pay / Google Pay. **Booking is impossible until this exists.** *(Drivly has Stripe + wallet; runs in demo mode without real keys — [PARTIAL].)*
5. **App** shows the **proximity map** of *live, operator-owned* cars within walking distance, each with **live fuel %, model, and distance to user**. *(Today the map is a styled canvas placeholder backed by static listing lat/lng; the live telemetry feed is [MISSING].)*
6. **User** taps a car and opens the **booking wizard**:
   - Step 1 — choose the car + rental **duration** (start/end date & time, or "take it now").
   - Step 2 — choose **add-ons** (Premium Insurance, Child Seat, Extra Mileage Package). *([MISSING].)*
   - Step 3 — **authorize the security deposit (held funds)** + process the upfront payment. *(Deposit pre-auth needs Stripe manual-capture — [MISSING].)*
7. **Backend** confirms the upfront charge + deposit hold succeeded; booking becomes **Confirmed**.
8. **App** starts **walking navigation** to the car's precise GPS point. *([MISSING].)*
9. **App** continuously compares phone GPS to the car's **live** GPS. The **"Unlock & Start Rental"** button stays **disabled until the phone is ≤ 15 m** from the car. *([MISSING] — see note in 6.4.)*
10. **User** is now ≤ 15 m → button activates. **App** requires the **4-photo Digital Walkaround** (front, back, left, right). *(Maps to Drivly's pre-trip Inspection + photo upload — [PARTIAL]; strict 4-photo enforcement is new.)*
11. **User** taps **Unlock** → **Backend** calls `POST /vehicle/unlock` → **IoT** opens central locking and confirms. *([MISSING].)*
12. **App** tells **User** to take the **physical key from the glovebox** and start the engine. **The rental counter starts now** (free-floating per-minute / per-hour, or per-day). *(Per-min/hour billing model is [MISSING]; Drivly trip billing is day-based.)*
13. **User** drives. **IoT** streams `GET /vehicle/status` every 60 s; **Backend** updates the live map and watches the geofence. *([MISSING].)*
14. **User** drives to a **valid drop-off geofenced zone** (shown on map) and parks.
15. **App** runs the **drop-off checklist** (user ticks "keys left in glovebox", "belongings collected"). *([MISSING].)*
16. **Backend** runs **pre-lock automated checks** via IoT: *inside perimeter? ignition off? all doors/windows shut?* All must pass. *([MISSING].)*
17. **User** taps **"Lock & End Rental"** → **Backend** calls `POST /vehicle/lock` → **IoT** confirms doors **physically locked**.
18. **Backend** **stops the counter**, calculates the **invoice**, **releases the deposit hold** (less any charges), and returns the car to the map as **Available**.
19. **User** rates / reviews the trip. *(Reuses Drivly reviews — [DONE].)*

**Swimlane diagram (happy path)**

```text
 USER            APP                 BACKEND              IoT / SMART BOX        ADMIN
  |   register     |                    |                      |                   |
  |--------------->| OTP + KYC dual-doc |                      |                   |
  |                |------------------->| store, queue review  |                   |
  |                |                    |---- approve KYC --------------------->[approve]
  |  add card      |                    |                      |                   |
  |--------------->| tokenize (Stripe)  |                      |                   |
  |                |                    | [no card => BLOCKED] |                   |
  |  see map       |  live cars (fuel/model/dist) <--- 60s status ---|            |
  |<---------------|<-------------------|<---------------------|  (live map feed)->|
  |  book wizard   | duration->add-ons->deposit hold + pay     |                   |
  |--------------->|------------------->| auth deposit + charge |                  |
  |                |                    | booking=Confirmed     |                  |
  |  walk to car   | nav + distance gate|                      |                   |
  |                |   [>15m: locked]   |                      |                   |
  |  arrive <=15m  | Unlock ACTIVATES   |                      |                   |
  |  4 photos      |------------------->| store walkaround     |                   |
  |  tap UNLOCK    |------------------->| POST /vehicle/unlock ---------------->[doors open]
  |                |  "get key,start"   | COUNTER STARTS <-----| confirm unlocked  |
  |  drive ...     |                    |<------ 60s status ----|---- live map ---->|
  |  park in zone  | drop-off checklist |                      |                   |
  |  tap LOCK&END  |------------------->| pre-lock checks: in-zone? ign off? shut? |
  |                |                    |---[FAIL: block, keep counting]           |
  |                |                    |---[PASS] POST /vehicle/lock -------->[doors lock]
  |                |  invoice + receipt | COUNTER STOPS <------| confirm locked    |
  |                |                    | release deposit hold; car -> Available -->|
  |  rate trip     |------------------->| save review          |                   |
```

---

### 6.2 No verified payment method, or KYC pending/rejected → booking blocked

Plain words: the user can browse, but cannot book until **both** identity and payment are in good standing.

**Steps**
1. User tries to open the booking wizard.
2. Backend checks: KYC = approved? Payment method = present & valid?
3. If either fails, the wizard is blocked and the app shows a clear next step:
   - **KYC pending** → "Your documents are under review."
   - **KYC rejected** → reason + "Re-upload your Driver License."
   - **No payment method** → "Add a card or Apple/Google Pay to continue."

```text
 [Tap Book] --> KYC approved? --no--> show KYC status / re-upload --> STOP
                    |yes
                Payment on file & valid? --no--> "Add payment method" --> STOP
                    |yes
                Open booking wizard
```

---

### 6.3 Deposit authorization declined / card fails

Plain words: if the bank refuses the hold or the upfront charge, no booking is created and no car is reserved.

**Steps**
1. At wizard Step 3, Backend asks Stripe to **authorize the deposit hold** + take the upfront payment.
2. If declined / insufficient funds / expired card → Backend aborts, the booking is **not** created, the car stays **Available**.
3. App shows the decline reason and offers: try another card, or retry.

```text
 [Pay step] --> auth deposit + charge --ok--> booking=Confirmed
                       |declined
                 keep car Available; "Payment failed: <reason>"
                       |
                 [Try another card] --> retry  |  [Cancel] --> back to map
```

---

### 6.4 User not within 15 m → unlock stays locked

Plain words: the unlock button will not work until the phone is right next to the car. This stops people unlocking a car they cannot see.

**Steps**
1. App reads phone GPS and the car's **live** GPS, computes the distance.
2. If distance > 15 m → Unlock button **disabled**; app shows distance + a walking arrow ("42 m away — keep walking").
3. When distance ≤ 15 m → button enables, and the 4-photo walkaround unlocks.

```text
 phone GPS  vs  car live GPS  --> distance > 15m? --yes--> [Unlock DISABLED] + guidance
                                          |no
                                   [Unlock ENABLED] --> proceed to 4-photo walkaround
```

> Today this gate does not exist — the on-device prototype's unlock is always tappable and uses no real distance check. The real implementation needs the car's **live** GPS (not the static listing lat/lng) and a continuous distance comparison. **[MISSING]**

---

### 6.5 Unlock command fails or IoT times out

Plain words: if the car does not confirm it unlocked, the rental does **not** start and the user is not charged for time.

**Steps**
1. User taps Unlock → Backend sends `POST /vehicle/unlock`.
2. Backend waits for IoT confirmation within a timeout.
3. **No confirmation** → counter is **NOT** started; App shows "Couldn't reach the car — retry."
4. After N retries → offer in-app support / emergency-code path and raise an Admin alert.

```text
 [Unlock] --> POST /vehicle/unlock --> confirmed? --yes--> COUNTER STARTS
                                            |no (timeout)
                                     retry (x N) --confirmed--> COUNTER STARTS
                                            |still failing
                                     "Contact support" + Admin alert ; NO billing
```

---

### 6.6 Dead cellular zone at pickup or return → BLE fallback / offline code

Plain words: if the car is underground or in a rural blind spot and cannot be reached over the network, the app falls back to a short-range Bluetooth command, or gives a one-time toll-free code.

**Steps**
1. Backend cannot reach the Smart Box over cellular (no `status` heartbeat / command not acknowledged).
2. **If hardware supports BLE** → App connects phone-to-Smart Box directly and sends Unlock/Lock over **BLE**.
3. **Else** → App shows an **emergency offline verification code** + toll-free line so ops can authorize.
4. Once back online, the Smart Box reconciles its state with Backend.

```text
 command --> cellular reachable? --yes--> normal IoT path
                  |no
            BLE supported? --yes--> phone <--BLE--> Smart Box (unlock/lock)
                  |no
            show offline code + toll-free verification ; reconcile when back online
```

> Status: BLE fallback and the offline-code path are **[MISSING]** and are vendor/hardware-gated (validated in milestone **M4**).

---

### 6.7 Pre-lock check fails (out of zone, ignition on, or a door open)

Plain words: you cannot end the rental and stop paying until the car is genuinely returned safely. The app tells you exactly what to fix; the meter keeps running.

**Steps**
1. User taps "Lock & End Rental".
2. Backend asks IoT: inside perimeter? ignition off? all doors/windows shut?
3. Any check fails → end-rental **blocked**, **counter keeps running**, App shows the specific fix:
   - Outside zone → "Move the car into the highlighted drop-off area."
   - Ignition on → "Turn off the engine."
   - Door/window open → "Close the rear-left door."
4. User fixes it and taps again → checks pass → lock proceeds (as 6.1 step 17).

```text
 [Lock & End] --> in-zone? --no--> "Move into zone"      -+
                  ign off? --no--> "Turn off engine"      |--> BLOCKED, counter RUNS
                  doors/windows shut? --no--> "Close door"+
                       | all pass
                  POST /vehicle/lock --> counter STOPS, invoice
```

---

### 6.8 Return outside any valid zone → options / penalty

Plain words: if the user wants to stop far from any allowed drop-off zone, they cannot just end the rental — they either drive into a zone or accept an out-of-zone penalty if the operator allows it.

**Steps**
1. The pre-lock check finds the car outside every valid drop-off geofence.
2. App offers: (a) navigate to the nearest valid zone, or (b) if the operator permits, **end with an out-of-zone penalty** (a relocation fee from the penalty matrix).
3. If neither → rental continues and the counter runs.

```text
 outside all zones? --yes--> [Nav to nearest zone]  OR  [End + out-of-zone fee*]
                                   |                         (*if policy allows)
                              return in zone (6.1)      counter stops, fee added to invoice
```

---

### 6.9 Late return: grace period → auto-bill + penalty (and the extend alternative)

Plain words: if you keep the car past your booked end time without extending in the app, you get a short grace window; after that the system automatically charges the next full day plus an admin penalty.

**Steps**
1. The scheduled end time passes. Backend starts a **grace period** (e.g. 15 min, configurable).
2. If the user **extends in-app** before/within grace → new end time, normal billing, no penalty. *(Drivly extend exists but is day-based — [PARTIAL]; needs hour/minute granularity.)*
3. If grace expires with no extension → Backend **auto-bills the next full day + admin penalty** (e.g. $50 flat or hourly, per the penalty matrix), notifies the user, and flags the car as overdue on the Admin map.

```text
 scheduled end --> within grace window?
        |                         |
   extend in app? --yes--> new end time, no penalty
        |no                       |grace expired, no extend
        +----------------> AUTO: next full day + admin penalty --> notify user, mark overdue
```

---

### 6.10 Geofence violation / Theft mode (car moves while NOT rented)

Plain words: if a car leaves its allowed area or crosses a border while nobody has it rented, the system treats it as theft — it instantly alerts the operator, texts the team, and gets a remote engine-kill ready.

**Steps**
1. `GET /vehicle/status` shows the car moving / leaving allowed zones / crossing a national border **with no active rental**.
2. Backend raises an **immediate high-priority Admin alert** on the Control Tower (the car turns **Red**).
3. Backend sends an **automated SMS** to operations.
4. Backend **prepares** a remote engine-kill (`POST /vehicle/immobilize`) — armed for one-tap human authorization (or auto, per policy). Optionally alerts police.

```text
 60s status --> active rental? --yes--> normal tracking
                     |no
              moving / out-of-zone / border crossed?
                     |yes
        HIGH-PRIORITY admin alert (car=RED) + SMS to ops
                     |
        ARM POST /vehicle/immobilize --> [admin confirms] --> engine cut, cannot restart, alert police
```

> The on-device prototype has an immobilizer **toggle**, but it is simulation only — no backend, no geofence, no real command. Real theft mode needs the geofence engine + alert/SMS pipeline + a real `immobilize` command. **[MISSING]**

---

### 6.11 Damage reported by next user → cross-user comparison → deposit forfeiture

Plain words: if the next renter reports a dent or a dirty car at pickup, the system automatically points to the previous driver and lets an admin charge that person's deposit after comparing the before/after photos.

**Steps**
1. User B's **4-photo walkaround** (or a report) shows new damage / dirt at pickup.
2. Backend runs the **cross-user comparison**: it identifies **User A**, the previous driver of that same car, and **flags A's trip**.
3. Backend bundles **User A's post-trip photos** vs **User B's pre-trip photos** into a dispute case.
4. **Admin** reviews both photo sets and decides.
5. If A is at fault → Backend **deducts the damage fee from A's held security deposit** (deposit forfeiture); the remainder is released.

```text
 User B walkaround/report (damage) --> system finds previous driver = User A
                 |                                   |
          build case: A post-photos  vs  B pre-photos
                 |
          ADMIN reviews --> A at fault? --yes--> deduct fee from A's deposit; release rest
                                          --no--> release A's deposit; no charge
```

> Drivly has Disputes (customer file + admin resolve/escalate) and pre/post inspection photos — a real head start ([PARTIAL]). The **automatic "flag the previous driver"** linkage and **deposit deduction** are new ([MISSING]).

---

### 6.12 Low fuel / maintenance auto-flag → car removed from map

Plain words: when telemetry shows a car is low on fuel/battery or due for service, the system quietly takes it off the customer map and tells operations.

**Steps**
1. `GET /vehicle/status` reports low fuel/battery, or the odometer crosses a maintenance threshold (oil change / inspection / insurance renewal).
2. Backend sets the car to **Maintenance/Low-Fuel** (Orange on the Control Tower) and **hides it from the customer map** so it cannot be booked.
3. Ops is notified; the car returns to the map after servicing / refuelling.

```text
 60s status --> low fuel/battery OR odometer >= service threshold?
                     |yes
        set status=Orange (Maintenance/Low-Fuel) --> remove from customer map --> notify ops
                     | serviced/refuelled
                back to Available (Green)
```

---

### 6.13 Booking cancellation & refund / no-show

Plain words: a user can cancel before pickup (refund per policy, deposit hold released); if they never show up, the booking auto-expires and the car goes back on the map.

**Steps**
1. **User-initiated cancel** (before unlock): Backend applies the cancellation policy, refunds per the rules, **releases the deposit hold**, and returns the car to the map. *(Drivly already has booking cancel + Stripe refunds — [PARTIAL]; deposit-hold release is new.)*
2. **No-show**: if the booking window passes with no unlock, Backend **auto-expires** it, releases the deposit hold (or applies a no-show fee per policy), and frees the car. *([MISSING].)*

```text
 booking Confirmed --> user cancels before unlock? --yes--> refund per policy + release hold + free car
                            |no
                       pickup window passed without unlock? --yes--> auto-expire
                            |                                          (release hold or no-show fee)
                       proceed to pickup (6.1)
```

---

### 6.14 Scenario coverage summary

| # | Scenario | Drivly reuse today | New work needed | Effort |
|---|----------|--------------------|-----------------|--------|
| 6.1 | Happy path | Auth, KYC, payments, booking wizard, inspection photos, trip lifecycle, reviews | Live telemetry map, deposit hold, add-ons, proximity gate, real IoT unlock/lock, pre-lock checks, per-min/hour billing | XL |
| 6.2 | KYC/payment block | KYC + Stripe present | Gate the wizard on both | S |
| 6.3 | Deposit/card decline | Stripe charges | Manual-capture pre-auth + abort path | S–M |
| 6.4 | Not within 15 m | Map/geolocator present | Phone-vs-live-car distance gate | M |
| 6.5 | Unlock fail/timeout | — | Gateway timeout/retry, no-bill rule | M |
| 6.6 | Dead zone (BLE/offline) | — | BLE fallback + offline code (HW-gated) | L |
| 6.7 | Pre-lock check fail | Trip end exists | IoT in-zone/ignition/door checks | M |
| 6.8 | Return out of zone | — | Geofence drop-off + relocation fee | M |
| 6.9 | Late return penalty | Day-based extend | Grace + auto-bill + penalty matrix; hour/min extend | M–L |
| 6.10 | Theft mode | Immobilizer (simulated only) | Geofence watch + alert + SMS + real immobilize | L |
| 6.11 | Damage claim | Disputes + inspection photos | Auto-flag previous driver + deposit deduction | M |
| 6.12 | Low fuel / maintenance | CarResource admin | Telemetry-driven auto-flag + hide from map | M |
| 6.13 | Cancel / no-show | Booking cancel + refunds | Hold release + no-show auto-expire | S–M |

Legend: S = ~1–3 dev-days, M = ~4–8 dev-days, L = ~2–3 dev-weeks, XL = ~4+ dev-weeks. Sizing assumes the **VehicleGateway** adapter (Simulated implementation) is in place so flows can be built and demoed before the vendor hardware arrives; the hardware-gated parts of 6.5 / 6.6 / 6.7 / 6.10 are validated in milestone **M4**.

---

## 7. Feasibility — Can We Build It Without the Hardware?

**Verdict, plainly: YES.** Roughly **90-95% of the Automated Car-Sharing Platform can be built, tested, and demoed today without any GPS/IoT hardware.** The whole journey — discovery, booking, deposit hold, proximity-gated unlock, trip billing, geofenced return, the admin Control Tower, pricing and penalties — can run end-to-end against a software simulator. Only a short list of items that physically touch a real vehicle (actual door lock/unlock, true telemetry accuracy, engine immobilization, BLE fallback, dead-zone behavior) genuinely need a device, and those are exactly the integration tasks parked in milestone **M4**, which depends entirely on the hardware vendor.

This works because of an **adapter pattern**: we define one `VehicleGateway` interface (`unlock`, `lock`, `immobilize`, `getStatus`/telemetry) and write two implementations behind it — a `SimulatedGateway` we build now, and a `VendorGateway` we plug in when the vendor's API and test device arrive. The rest of the platform never knows the difference. Drivly already contains an early, on-device version of this idea in [gps_device_provider.dart](frontend/lib/features/trip/domain/providers/gps_device_provider.dart) and [gps_control_screen.dart](frontend/lib/features/trip/presentation/screens/gps_control_screen.dart) — its own comments describe it as "the prototype of the client's core idea ... simulated on-device so the flow is fully demoable without the third-party GPS provider's API." Note that this is a P2P-marketplace app being re-aimed at an operator-owned fleet, so this prototype is a reference, not a drop-in component (see 7.2).

### 7.1 Capability-by-capability: what needs hardware and what doesn't

Lead read: almost everything is buildable now; the simulator stands in for the car. Only the bottom five rows truly require a physical unit.

| Capability | Buildable without hardware? | How we de-risk it now |
|---|---|---|
| Customer app & admin Control Tower UI | **Yes** | Pure software — screens, flows, state, API calls. Drivly already has many screens to repurpose, though the live fleet map / Control Tower itself is not built today. |
| Geofencing / PostGIS zones (operational + drop-off, out-of-bounds) | **Yes** | Build PostGIS zone tables + point-in-polygon lookups (none exist today — Drivly uses plain lat/lng columns, no PostGIS); test with synthetic GPS points fed from the simulator. No car needed for the boundary math. |
| Booking, security-deposit hold, payments | **Yes** | Stripe test mode (manual-capture pre-auth for deposits, not built yet); no vehicle involved in the money flow. |
| Dynamic pricing + penalty/grace-period engine | **Yes** | Pure backend logic over the clock + tariff tables (none built today); validate with fast-forwarded test clocks. |
| Unlock / Lock / Immobilize **commands** (the app/backend side) | **Yes-simulated** | `SimulatedGateway` accepts the command, simulates round-trip latency, flips a state flag, and logs it — the same idea as the existing on-device prototype, but moved server-side. |
| Telemetry pipeline (lat/lng, fuel %, odometer, ignition, lock state, 60s cadence) | **Yes-simulated** | A **synthetic telemetry generator** pushes a moving GPS track + draining fuel + ticking odometer into the same ingest path the real webhook/poller will use. |
| Proximity gate (<=15m unlock rule) | **Yes-simulated** | Compare the **real phone GPS** against the **simulated car point**; the distance math and the locked/unlocked button are fully testable. |
| Pre-lock checks (inside perimeter? ignition off? doors/windows shut?) | **Yes-simulated** | Simulator exposes these flags; QA toggles them to force pass/fail paths. |
| **Real physical door lock/unlock + command latency** | **No, needs device** | Only a real unit proves doors actually move and how fast. M4, vendor-gated. |
| **Real telemetry accuracy & cadence** | **No, needs device** | GPS drift, fuel-sensor precision, true 60s timing only verifiable on hardware. M4. |
| **Engine immobilization (starter-relay cutoff)** | **No, needs device** | Cutting a real starter motor cannot be simulated. M4, safety-critical. |
| **BLE fallback to the smart box** | **No, needs device** | The Bluetooth handshake depends on the specific hardware's BLE support. M4. |
| **Dead-cellular-zone behavior** | **No, needs device** | Genuine signal loss + offline-code/BLE fallback must be tested in the field. M4. |

### 7.2 Simulator strategy — how we demo the whole journey before a device exists

Plain version: we build a fake car in software so the client and QA can click through the entire experience now, then swap in the real car later by flipping one switch.

```text
                 ONE INTERFACE, TWO IMPLEMENTATIONS

   App + Admin + Pricing + Geofence  ----->  VehicleGateway (interface)
        (never changes)                       unlock() lock()
                                              immobilize() getStatus()
                                                     |
                       +-----------------------------+---------------------------+
                       v                                                         v
          SimulatedGateway  (build NOW)                      VendorGateway  (plug in at M4)
          - fake lock/unlock/immobilize                      - calls real vendor IoT API
          - synthetic telemetry generator                    - receives real 60s webhooks
            (moving GPS, fuel drain, odometer)               - real door/engine commands
          - configurable signal/battery/flags                - same method signatures
                       +------------------- config flag selects one -------------+
                               GATEWAY_DRIVER = simulated | vendor
```

How it pays off:

- **End-to-end demos today.** With the `SimulatedGateway` + synthetic telemetry generator, Anouar can walk the full loop on a phone: find a (fake) car on the map, book it, have the deposit held, approach it, watch the unlock button arm at <=15m, "unlock", drive a simulated track, return inside a geofence, pass the pre-lock checks, "Lock & End Rental", and see the invoice. The admin Control Tower shows the same car moving and changing color (Green/Blue/Red/Orange) in real time.
- **QA can force edge cases on demand.** The simulator lets testers toggle "out of bounds," "ignition still on," "door open," "low signal/battery," or "border crossing" to exercise the theft-mode alert and the pre-lock failure paths — scenarios that are slow or impossible to stage with a real car.
- **A clean swap, not a rewrite.** Going live is a **config flag** (`GATEWAY_DRIVER = simulated | vendor`). Because both implementations satisfy the same `VehicleGateway` contract, the app, geofencing, pricing, and deposit logic are untouched. The synthetic telemetry path becomes the real webhook ingest path with the same shape.
- **The prototype is a head start, not the finished thing.** Today's [gps_device_provider.dart](frontend/lib/features/trip/domain/providers/gps_device_provider.dart) simulates state *on the phone only* — there is no backend gateway, no real proximity check, no geofence. The production `SimulatedGateway` must move that logic **server-side** (so the admin Control Tower and billing see the same truth) and drive it from the synthetic telemetry generator. It is a strong starting reference, not a reusable component as-is.

### 7.3 What hardware truly unlocks

Plain version: a handful of things can only be proven on a real car, and they all sit in milestone M4.

| Hardware-only item | Why it cannot be faked | Milestone / dependency |
|---|---|---|
| Real door lock/unlock + actual command latency | Physical actuation; round-trip time is vendor-network-specific | M4 — needs vendor API + test unit |
| Real telemetry accuracy & cadence | GPS drift, fuel-sensor precision, true 60s timing | M4 — test unit |
| Engine immobilization (starter cutoff) | Cuts a real relay; safety-critical, cannot simulate | M4 — test unit |
| BLE fallback to the smart box | Depends on the specific hardware's BLE capability | M4 — test unit (plus confirmation the hardware supports BLE) |
| Dead-zone offline behavior (BLE / offline code) | Requires genuine signal loss in the field | M4 — field test |

All of these are **gated on the vendor delivering full API docs plus at least one test device.** Until then they cannot start; the rest of the build proceeds in parallel against the simulator.

### 7.4 The second feasibility dimension — non-hardware decisions the client must make

Plain version: hardware is not the only thing standing between us and a shippable product. Several business and account decisions only Anouar can make, and some block specific milestones.

| Dependency | Why it gates feasibility | Decision needed from client (Anouar) |
|---|---|---|
| Payment provider in Morocco | Stripe availability/merchant onboarding in Morocco is uncertain; the local option is CMI. The deposit **hold/pre-auth** capability depends on the chosen provider supporting it. Drivly is wired for Stripe today (in demo mode, no real keys). | Confirm provider (CMI vs Stripe), whether it supports deposit pre-auth, and whether we accept **cards only** or also **cash / mobile wallet**. Provide test + live keys. |
| SMS provider | OTP at sign-up and **theft-mode SMS alerts to operations** both require an SMS gateway. | Pick a provider (e.g. Twilio or a local SMS gateway) and supply account/credentials. |
| Google Maps key & billing | The map currently renders a styled-canvas placeholder unless a real key is supplied; live tiles + pedestrian navigation need a billed key. | Provide a Google Maps API key on Anouar's billing account. |
| Apple / Google developer accounts | Store submission and keyless features (push, location) require accounts owned by the client. | Create/own Apple Developer ($99/yr) and Google Play ($25 one-time) accounts. |
| PostgreSQL **+ PostGIS** hosting | Geofencing needs the PostGIS extension. Drivly today uses plain lat/lng columns with **no PostGIS**; production hosting must enable it. | Approve a Postgres host that supports the PostGIS extension. |
| Arabic / French localization + RTL | App is **English-only** today (locale is persisted but UI strings are not translated; no RTL layout). Morocco needs Arabic and/or French. | Decide primary + supported languages and supply translations (or approve a translation budget). |
| Legal / insurance for deposits & penalties | Deposit holds, forfeiture, and late-return penalties must match insurance terms and local law to be enforceable. | Provide insurance partner rules and legal/ToS/privacy inputs. |
| Who defines the map zones | Geofencing cannot be configured without the actual operational and drop-off zone boundaries. | Decide who draws the zones and deliver the city/zone definitions. |

### 7.5 Blunt risk callout

**The single biggest feasibility risk is the hardware vendor — not the software.** As of now the vendor is unconfirmed: unknown brand, unknown API quality, unknown documentation completeness, and unknown test-device timing. Everything keyless — real unlock/lock, immobilization, true telemetry, BLE fallback, dead-zone handling — depends on it. The proposal's own timeline assumes full API docs + a test device by **end of Week 1**, and explicitly states that if the vendor is late, **M4 slips by the same amount**. The simulator strategy deliberately insulates ~90-95% of the work from this risk so the project can move at full speed regardless, but the final keyless capability **cannot be declared done until a real device is in hand and integrated**. Securing the vendor's name, API docs, and a test unit is therefore the highest-priority client action.

---

## 8. Roadmap, Effort, Timeline & Cost

This section lays out an honest path from Drivly as it exists today to the Automated Car-Sharing Platform. The good news first: Drivly already covers roughly half of the supporting software (auth, KYC, payments, discovery, booking, inspection photos, disputes, admin panel, push). The hard, differentiating work — geofencing, the IoT gateway, proximity unlock, deposits, the pricing/penalty engine, and the live Control Tower — is still ahead, plus the one-time cost of pivoting the codebase away from its peer-to-peer (host-owned) shape. We map this onto Umer's existing 5-milestone proposal so the commercial structure stays familiar, then size each workstream, lay out a calendar, and list the decisions only Anouar can unblock.

One framing point underpins everything below: Drivly is a peer-to-peer (Turo/Getaround-style) marketplace where individual hosts list their own cars; the target is an operator-owned, zero-human, keyless free-floating fleet. The biggest item in this plan is not a missing feature — it is that business-model pivot.

### 8.1 Phase Plan (mapped onto the existing 5 milestones)

The original milestones are kept. What changes is the *content* inside each one: less greenfield plumbing (Drivly gives us a head start) and more pivot + IoT/geofencing work folded into M2 and M4. Status glyphs: [DONE] built & usable, [PARTIAL] exists but needs rework, [MISSING] not built, [REPURPOSE] built but aimed at the wrong model.

| Phase | Goal (plain language) | Key deliverables | Reused from Drivly | Net-new work |
|---|---|---|---|---|
| **M1 — Planning** (Wk 1-2) | Lock the design, confirm the model pivot, prove we can talk to the GPS vendor | System & DB design (incl. PostGIS + fleet/IoT schema), API plan, repo setup, first contact test with vendor API, define the `VehicleGateway` interface | [DONE] Laravel 12 + Filament + Flutter codebase as the foundation | Operator data model design; PostGIS adoption plan; gateway interface contract; vendor API spike |
| **M2 — Backend + Admin basics** (Wk 3-5) | Stand up the operator backend and admin core, with geofencing in place | Operator auth/roles, KYC review, fleet vehicle model (IMEI/telemetry fields), PostGIS geo-zones (operational + drop-off), live-map skeleton | [DONE] Sanctum auth, KYC upload+review, Filament Users/Cars/Bookings/Disputes, Stripe wiring | [REPURPOSE] host roles/ownership → operator; [MISSING] PostGIS + geofence editor; [MISSING] IMEI/telemetry fields on a fleet vehicle; [MISSING] zone CRUD |
| **M3 — Mobile main screens** (Wk 6-8) | Customer app end-to-end against the simulator | Sign-up/KYC, proximity map, booking wizard + add-ons, proximity-gated unlock screen, 4-photo walkaround, active-trip + return flow | [DONE] auth/OTP/social screens, discovery+map+filters, booking wizard, inspection-photo upload, trip start/end UI; [PARTIAL] the simulated [gps_control_screen.dart](frontend/lib/features/trip/presentation/screens/gps_control_screen.dart) | [MISSING] real proximity gate (phone vs live car GPS); [MISSING] add-ons step; [MISSING] return checklist + pre-lock checks UI; [PARTIAL] per-hour/min trip mode (today daily-only) |
| **M4 — GPS/IoT, payments & admin tools** (Wk 9-10, **hardware-gated**) | Wire the real vendor, money, and operator tooling | `VendorGateway` against real device; 60s telemetry ingest; deposit holds (pre-auth); pricing/penalty engine; claims/forfeiture; Control Tower colour-coded map | [PARTIAL] Stripe PaymentService, DisputeService, PricingService (as a base), Filament dispute/promo tooling | [MISSING] real unlock/lock/immobilize; [MISSING] telemetry pipeline; [MISSING] Stripe manual-capture deposits; [MISSING] tariff+penalty matrix; [MISSING] cross-user damage compare; [MISSING] live fleet map |
| **M5 — Testing & launch** (Wk 11-12) | Harden, localize, ship | Full QA, hardware integration testing, AR/FR + RTL, theft-mode/BLE/dead-zone fallbacks, go-live + handover docs | [DONE] Pest test suite, demo-mode scaffolding, settings (currency/units already app-wide) | [MISSING] hardware integration QA; [MISSING] localization (EN-only today); [MISSING] fail-safe protocols; production cutover |

```text
P2P TODAY (Drivly)                         TARGET (Automated Car-Sharing)
+---------------------+                    +-----------------------------+
| Host lists own car  | --REPURPOSE-->     | Operator owns whole fleet   |
| Host earnings/payout| --REMOVE---->      | All revenue to operator     |
| Host<->renter chat  | --REPURPOSE-->     | Optional support channel     |
| Daily-rental trip   | --REWORK---->      | Per-min/hour/day on-demand   |
| Static lat/lng      | --REPLACE-->       | Live IoT GPS + telemetry     |
| Manual loc endpoint | --REPLACE-->       | 60s gateway ingest + unlock  |
| (no geofence)       | --ADD------>       | PostGIS zones + proximity    |
+---------------------+                    +-----------------------------+
```

### 8.2 Effort Estimate by Workstream

Effort legend: S = ~1-3 dev-days, M = ~4-8 dev-days, L = ~2-3 dev-weeks, XL = ~4+ dev-weeks. Assumes one experienced full-stack developer (the proposal's setup) reusing Drivly. "Hardware-gated" means it cannot be fully validated until the vendor's API docs + test device arrive.

| Workstream | Reuse from Drivly? | Effort | Hardware-gated? | Notes |
|---|---|---|---|---|
| Model pivot P2P → operator | [REPURPOSE] schema + admin re-aimed | **L** | No | Strip host ownership/payouts; re-point `host_id`, host roles → operator/fleet. Touches many models. |
| Geofencing / PostGIS | [MISSING] no PostGIS today | **L** | No | New extension, zone tables, boundary lookups for operational + drop-off zones. |
| IoT gateway + simulator | [PARTIAL] on-device [gps_device_provider.dart](frontend/lib/features/trip/domain/providers/gps_device_provider.dart) is an early sim | **M** | No (sim) | Define one interface; build a server-side `SimulatedGateway`. The existing sim is on-device only, not a backend gateway. |
| `VendorGateway` (real) | [MISSING] | **M** | **Yes** | Adapter to vendor's unlock/lock/immobilize/status. Blocked on docs+device. |
| Telemetry pipeline (60s) | [PARTIAL] Reverb/Horizon exist | **M** | **Yes** (accuracy) | Webhook/poller ingest → live fields; queue + WebSocket fan-out reuse Horizon/Reverb. |
| Proximity unlock (<=15m) | [PARTIAL] geolocator in app | **M** | **Yes** (real GPS) | Real distance check phone vs live car GPS; gate the unlock button. Today's gate is simulated. |
| Deposit holds + payments | [PARTIAL] Stripe PaymentService | **M** | No | Add Stripe manual-capture/pre-auth + release/forfeit. Core Stripe already wired. |
| Pricing + penalty engine | [PARTIAL] PricingService base | **L** | No | Hourly/daily/seasonal tariffs, grace period, auto late-billing, admin penalty. `dynamic_pricing_enabled` is a flag only today. |
| Booking add-ons | [PARTIAL] booking wizard | **S** | No | Insurance / child seat / extra mileage as priced options. |
| Control Tower live map (admin) | [PARTIAL] Filament base | **L** | No | Colour-coded fleet map; needs telemetry to be live to be meaningful. No live map exists today. |
| Maintenance logs | [PARTIAL] Filament CRUD | **M** | No | Odometer-driven flags for oil/insurance/inspection. |
| Claims / deposit forfeiture | [PARTIAL] DisputeService, inspection photos | **M** | No | Cross-user previous-driver flag + deduct from held deposit. |
| BLE / dead-zone fallback | [MISSING] | **M** | **Yes** | BLE to smart box if hardware supports; else offline unlock code. |
| Theft mode | [MISSING] | **M** | **Yes** (kill) | Out-of-bounds alert + SMS + prepared remote engine-kill. |
| Localization AR/FR + RTL | [PARTIAL] locale persisted, EN-only | **M** | No | Translate strings + RTL layout. Currency/units already app-wide. |
| QA / hardware integration | [PARTIAL] Pest suite | **L** | **Yes** | Sim-based QA now; real-device integration test in M4/M5. |

**Rough total:** summing the bands gives roughly **14-20 dev-weeks** of raw effort. The proposal's 11-12 calendar weeks stays *achievable* because (a) the Drivly head start removes a large slice of M2/M3 greenfield work, and (b) much of the work above runs in parallel where it does not share a dependency. Accounting for the pivot and PostGIS/IoT scope, the realistic calendar range is **12-16 weeks (most likely 14-16)**.

### 8.3 Calendar / Timeline (12-16 weeks)

The simulator lets us build and demo ~90-95% of everything without hardware. Only the "vendor-gated" band must wait for the vendor's API docs + test device — assumed by end of Week 1 in the proposal. If that slips, M4 (and the tail) slips by the same amount.

```text
Week:        1   2   3   4   5   6   7   8   9  10  11  12 | 13  14  15  16
            -------------------------------------------------+------------------
M1 Planning [=======]                                       |   (buffer/stretch)
M2 Backend  +Admin   [===========]                          |
  - pivot            [=======]                              |
  - PostGIS zones       [=======]                           |
M3 Mobile (sim)                  [===========]              |
  - proximity/walkaround           [=======]               |
M4 GPS/IoT+pay+admin                          [=======]     |
  - deposits/pricing                          [=======]     |
  - Control Tower map                          [=====]      |
M5 Test+localize+launch                              [======]
            -------------------------------------------------+------------------
Vendor dep: [DOCS+DEVICE by end Wk1].......needed by Wk9 >>> | if late, M4-M5
                                                            | slide right --->
Realistic:  <----------- 11-12 wk happy path ----------->   | 14-16 wk if
                                                            | vendor late OR
                                                            | RTL/pivot grows
```

Honest read: 11-12 weeks is plausible **only if** the head start truly offsets the added geofencing + IoT scope **and** the vendor delivers docs + a test device on time. The most likely stretch points are (1) vendor lateness pushing M4, (2) RTL/Arabic localization being larger than a string swap, and (3) the model pivot touching more of the schema than expected. Budget mentally for ~14-16 weeks.

### 8.4 Cost Framing

The anchor is the existing proposal: **$7,500 USD fixed, across 5 milestones** (M1 20% / M2 25% / M3 25% / M4 20% / M5 10%), each paid only after the work is shown and approved. That commercial structure still fits.

**Honest opinion on the price:** $7,500 is *lean but defensible* for this scope *because* Drivly already exists — without that head start, building geofencing, IoT, deposits, the pricing engine, and a live Control Tower from zero would normally run well above this for a single developer. The risk is not build quality but *hours*: the pivot + PostGIS + IoT integration are most likely to absorb extra time. We recommend treating M4 (IoT/payments) as the milestone most exposed to change, and agreeing in writing that vendor delays move M4's date and payment without re-opening the price.

The one-time DEV cost (the $7,500) is separate from the recurring OPERATING costs Anouar carries on his own accounts. These were explicitly excluded from the proposal:

| Operating cost (Anouar bears) | Type | Rough range | Notes |
|---|---|---|---|
| IoT hardware (smart box / OBD dongle) per car | One-time per car | Depends on vendor | Bought from Anouar's chosen GPS/IoT vendor; not in dev price |
| SIM / cellular data per car | Recurring per car | Depends on provider | Needed for 60s telemetry; scales with fleet size |
| Apple Developer account | Recurring | $99 / yr | Stated in proposal |
| Google Play account | One-time | $25 | Stated in proposal |
| Google Maps API | Recurring usage | Depends on traffic | Required for live tiles; demo mode runs without a key |
| SMS provider (Twilio / local) | Recurring usage | Depends on provider/volume | OTP + theft-mode alerts |
| Payment gateway fees | Per transaction | Depends on provider | CMI (local) vs Stripe (intl) |
| PostGIS-capable hosting + Redis | Recurring | Depends on host | Must support PostgreSQL+PostGIS; Redis for queues/WebSockets |
| Domain + SSL | Recurring | Depends on registrar | Standard |

### 8.5 Client Decisions & Dependencies to Unblock

Each item below blocks part of the build. The first is the single most important — without it, M4 cannot be completed.

- [ ] **GPS/IoT vendor name + full API docs + a test device** — CRITICAL; gates all real IoT, telemetry, proximity unlock, theft mode. Needed by end of Week 1 or M4 slips.
- [ ] **Confirm the model pivot in writing** — agree we are building operator-owned free-floating, not P2P (removes host payouts, re-aims host tooling).
- [ ] **Payment provider** — local CMI vs international Stripe; cash/wallet support? Provide test + live keys. (Drivly's Stripe path is the faster start.)
- [ ] **Google Maps API key** — for live map tiles (the app renders a styled placeholder without one).
- [ ] **SMS provider** — Twilio or local; for OTP + theft alerts.
- [ ] **Apple Developer + Google Play accounts** — owned by Anouar.
- [ ] **Hosting** — PostgreSQL+PostGIS-capable server + Redis + domain/SSL.
- [ ] **Brand materials** — logo, colours, final name.
- [ ] **Sample vehicle list** — model, category, plate, IMEI, pricing, to seed the fleet.
- [ ] **Legal / insurance** — ToS, privacy, insurance partner + rules that drive deposit/penalty amounts.
- [ ] **Zone definitions** — who draws the operational + drop-off geofence zones, and are they ready?
- [ ] **Language priority** — Arabic / French / English; which is primary (drives RTL effort)?
- [ ] **KYC approval policy** — fully automatic or Anouar's team reviews?
- [ ] **Support channel** — in-trip chat, phone, or both (decides the fate of the existing chat feature)?

### 8.6 Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Vendor delivers API docs / device late or quality is poor | M4 slips; theft mode & real unlock unverified | Build everything against `SimulatedGateway` now; isolate the vendor behind one adapter; agree slip terms in writing |
| Payments in Morocco (CMI vs Stripe; deposit/pre-auth support) | Deposit holds may not work as designed | Confirm provider early; verify manual-capture/pre-auth support before M4; Stripe path already wired in Drivly |
| Geofence accuracy in dense urban areas | False out-of-bounds / failed drop-off checks | Use PostGIS precise boundaries; add tolerance buffers; test against real device GPS in M5 |
| Deposit / penalty legal exposure | Disputes, chargebacks, regulatory issues | Tie penalty amounts to Anouar's legal/insurance rules; clear in-app disclosure; admin review before forfeiture |
| Theft mode / remote engine-kill liability | Safety + legal risk if mis-triggered | Prepare (not auto-execute) the kill command; require admin confirmation; log + alert + SMS first |
| Localization / RTL larger than a string swap | M5 stretch | Treat AR/RTL as its own task (effort M); confirm primary language early |
| Scope creep from the model pivot | Hours overrun on a fixed price | Freeze the pivot scope in M1 in writing; defer nice-to-haves; reuse Drivly schema where possible |
| Maps/Stripe/Firebase/sign-in currently in demo mode | Looks done but needs real keys | Client supplies keys early; flip out of demo mode and test before launch |

### 8.7 Recommended Next Steps

1. **Confirm the model pivot in writing** — get Anouar's sign-off that this is operator-owned free-floating, not P2P, so the host features can be re-aimed or removed without ambiguity.
2. **Lock the GPS/IoT vendor and obtain API docs + a test device** — the single most schedule-critical dependency; start the vendor conversation in Week 1.
3. **Decide the payment provider** (CMI vs Stripe) and confirm it supports deposit pre-authorization; provide test keys.
4. **Kick off M1 design against the simulator** — finalize the operator data model, the PostGIS zone schema, the `VehicleGateway` interface, and build a server-side `SimulatedGateway` so the full end-to-end flow is demoable while waiting on hardware.
5. **Collect the remaining unblockers in parallel** — Maps key, SMS provider, dev accounts, hosting (PostGIS+Redis), brand, sample fleet list, zone definitions, language priority, and KYC/support policies.
6. **Schedule weekly check-ins** with a single client contact and <=48h feedback turnaround, as the proposal requires, to keep the fixed timeline on track.
