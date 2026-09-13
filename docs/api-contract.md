
Q1 REST API Contract (proposed by Person 3, for Person 2 to confirm/adjust)
Status: DRAFT — agree this with Person 2 on day one, then delete this line. Base URL used by the client: http://localhost:9090/api (configurable, see question1-rest/client/Config.toml).

Data model
Matches the sample payload in the assignment brief.

{
  "assetTag": "NUST-LIB-3DP-001",
  "name": "Pro-Series 3D Printer",
  "description": "High-precision laboratory printer.",
  "institution": "Namibia University of Science and Technology",
  "site": "Main Campus - Innovation Lab",
  "status": "AVAILABLE",
  "dateAcquired": "2024-03-10",
  "components": [
    { "compId": "C101", "name": "High-Torque Stepper Motor", "description": "Main motor for X-axis movement." }
  ],
  "schedules": [
    { "scheduleId": "SCH-882", "type": "MAINTENANCE", "dueDate": "2026-09-01", "description": "Quarterly calibration." }
  ],
  "workOrders": [
    { "orderId": "WO-554", "status": "OPEN", "description": "Nozzle heat-bed failure",
      "tasks": [ { "taskId": "T1", "description": "Check thermal sensor connectivity.", "done": false } ] }
  ]
}
status is one of: AVAILABLE, LOANED_OUT, OCCUPIED, UNDER_MAINTENANCE, DISPOSED.

Institutions are a separate resource (not just a free-text field on assets), so they can be added/removed independently per the "Manage institutions" mark item:

{ "name": "Namibia University of Science and Technology", "sites": ["Main Campus - Innovation Lab", "Main Campus - Library"] }
Error shape
Every non-2xx response returns:

{ "message": "human readable reason" }
Endpoints the client (Person 3) calls
Method	Path	Purpose	Body	Success
GET	/assets	Global view — all assets. Optional ?institution=&site= query filters for Campus View	–	200 Asset[]
GET	/assets/overdue	Overdue dashboard — assets with a schedule whose dueDate has passed	–	200 Asset[]
GET	/assets/{assetTag}	Look up one asset	–	200 Asset / 404
POST	/assets/{assetTag}/loan	Loan or book an asset	{ "borrowerName", "purpose", "dueDate" }	200 Asset (status flips to LOANED_OUT/OCCUPIED)
POST	/assets/{assetTag}/return	Return/release an asset	–	200 Asset (status back to AVAILABLE)
POST	/assets/{assetTag}/schedules	Add a servicing/booking schedule	{ "type", "dueDate", "description" }	200 Asset
PUT	/assets/{assetTag}/schedules/{scheduleId}	Modify a schedule	{ "type", "dueDate", "description" }	200 Asset
DELETE	/assets/{assetTag}/schedules/{scheduleId}	Remove a schedule	–	200 Asset
Endpoints owned by Person 2 (not used by the CLI menu, listed for completeness)
Method	Path	Purpose
POST	/assets	Create asset
PUT	/assets/{assetTag}	Update asset
DELETE	/assets/{assetTag}	Remove asset
POST/DELETE	/assets/{assetTag}/components...	Manage components
POST/PUT/DELETE	/assets/{assetTag}/workorders...	Work orders & tasks
GET/POST/DELETE	/institutions...	Manage institutions
Why the client can start immediately
question1-rest/client/dev-stub/ is a throwaway mock service implementing the table above against an in-memory map, seeded with sample assets. Point the client at it (Config.toml already does, port 9090) to build and test all 5 menu features today. Once Person 2's real service is running on the agreed port/base path, just repoint serviceUrl in Config.toml — no client code changes needed, since the client only depends on the contract above, not on the stub's implementation.

