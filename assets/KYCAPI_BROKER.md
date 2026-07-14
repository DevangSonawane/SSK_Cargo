
Broker/driver document verification: submit documents, check own status, and an admin review queue (approve/reject).



POST
/api/kyc/broker
Submit broker KYC (broker only)


Submits the broker's legal + financial identity documents for review. Sets kyc_status to submitted. Resubmitting (e.g. after a rejection) overwrites the previous submission and clears any rejection reason.

Required document keys: pan_number, aadhaar_number, gst_number, bank_account_number, business_registration_number

Optional photo keys (get the url from POST /api/kyc/documents/upload first, then include it here): pan_photo_url, aadhaar_photo_url

Parameters
Try it out
No parameters

Request body

application/json
Example Value
Schema
{
  "documents": {
    "pan_number": "ABCDE1234F",
    "pan_photo_url": "https://gadidosti-backend.onrender.com/api/kyc/documents/file/<id>",
    "aadhaar_number": "XXXX-XXXX-1234",
    "aadhaar_photo_url": "https://gadidosti-backend.onrender.com/api/kyc/documents/file/<id>",
    "gst_number": "27ABCDE1234F1Z5",
    "bank_account_number": "1234567890123",
    "business_registration_number": "U12345MH2020PTC123456"
  }
}
Responses
Code	Description	Links
200	
KYC submitted for review

Media type

application/json
Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "Operation successful",
  "data": {}
}
No links
403	
Only broker accounts may use this endpoint

Media type

application/json
Example Value
Schema
{
  "success": false,
  "message": "Something went wrong",
  "errors": [
    {}
  ]
}
No links
422	
Validation errors — missing required documents

Media type

application/json
Example Value
Schema
{
  "success": false,
  "message": "Something went wrong",
  "errors": [
    {}
  ]
}


POST
/api/kyc/documents/upload
Upload a KYC document file


Uploads a document photo/PDF via the active StorageProvider (STORAGE_PROVIDER env var). postgres stores the bytes in the kyc_files table (persists across deploys/restarts — use this in production); fake (default) writes to local disk instead, which is lost on every deploy/restart on platforms with an ephemeral filesystem (e.g. Render) — dev only.

The uploaded file's absolute url is merged into the caller's kyc_submissions.documents under document_key immediately — it survives a page refresh even before POST /api/kyc/broker/driver is ever called. Re-uploading the same document_key replaces the previous file for that key (old row is deleted when STORAGE_PROVIDER=postgres) — this is how document photos get "edited".

document_key is restricted per role, and must be the exact key you also want it to appear under in POST /api/kyc/broker/driver's documents object:

broker: pan_photo_url, aadhaar_photo_url
driver: license_photo_url, aadhaar_photo_url
Parameters
Try it out
No parameters

Request body

multipart/form-data
file *
string($binary)
document_key *
string
Broker accounts may only use pan_photo_url/aadhaar_photo_url; driver accounts only license_photo_url/aadhaar_photo_url — a mismatched key for your role returns 422.

Responses
Code	Description	Links
200	
Document uploaded

Media type

application/json
Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "Operation successful",
  "data": {
    "document": {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "user_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "document_type": "pan_photo",
      "url": "https://gadidosti-backend.onrender.com/api/kyc/documents/file/<id>"
    }
  }
}
No links
422	
Missing file, or document_key missing/not valid for this role

Media type

application/json
Example Value
Schema
{
  "success": false,
  "message": "Something went wrong",
  "errors": [
    {}
  ]
}


GET
/api/kyc/documents
List own uploaded KYC documents, one entry per document type (broker/driver only)


Unlike GET /api/kyc/status (which returns documents merged into one object keyed by document_type), this returns each uploaded document as a separate object with its own absolute url, filename, mime type, size, and upload timestamp.

Parameters
Try it out
No parameters

Responses
Code	Description	Links
200	
Documents fetched

Media type

application/json
Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "Operation successful",
  "data": {
    "documents": [
      {
        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "document_type": "pan_photo",
        "path": "kyc/<user_id>/pan_photo/pan.pdf",
        "filename": "string",
        "mime_type": "string",
        "size_bytes": 0,
        "uploaded_at": "2026-07-14T06:19:29.731Z",
        "url": "https://gadidosti-backend.onrender.com/api/kyc/documents/file/<id>"
      }
    ]
  }
}


GET
/api/kyc/documents/file/{id}
Fetch a stored KYC document file (owner or admin only)


Serves the raw file bytes for a document uploaded while STORAGE_PROVIDER=postgres. Only the uploading user or an admin may fetch it.

Parameters
Try it out
Name	Description
id *
string($uuid)
(path)
id
Responses
Code	Description	Links
200	
File bytes

Media type

application/octet-stream
Controls Accept header.
No links
403	
Not your document

Media type

application/json
Example Value
Schema
{
  "success": false,
  "message": "Something went wrong",
  "errors": [
    {}
  ]
}
No links
404	
File not found

Media type

application/json
Example Value
Schema
{
  "success": false,
  "message": "Something went wrong",
  "errors": [
    {}
  ]
}

GET
/api/kyc/status
Get own KYC status + submission


Parameters
Try it out
No parameters

Responses
Code	Description	Links
200	
KYC status fetched

Media type

application/json
Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "Operation successful",
  "data": {
    "kyc_status": "pending",
    "submission": {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "user_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "documents": {
        "license_number": "MH-2020123456789",
        "license_photo_url": "https://gadidosti-backend.onrender.com/api/kyc/documents/file/<id>",
        "vehicle_registration_number": "MH-12-CD-5678"
      },
      "rejection_reason": "Aadhaar number does not match uploaded name",
      "reviewed_at": "2026-07-14T06:20:04.890Z",
      "submitted_at": "2026-07-14T06:20:04.890Z",
      "updated_at": "2026-07-14T06:20:04.890Z"
    }
  }
}

GET
/api/kyc/{userId}
Get own KYC status + submission by explicit user id (broker/driver only)


Self-only counterpart to GET /api/admin/kyc/{userId} — same data as GET /api/kyc/status, but addressed by id instead of implicitly via the bearer token. Passing any id other than your own returns 404 (not 403), so it doesn't reveal whether that id exists.

Parameters
Try it out
Name	Description
userId *
string($uuid)
(path)
userId
Responses
Code	Description	Links
200	
KYC status fetched

Media type

application/json
Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "Operation successful",
  "data": {
    "kyc_status": "pending",
    "submission": {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "user_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "documents": {
        "license_number": "MH-2020123456789",
        "license_photo_url": "https://gadidosti-backend.onrender.com/api/kyc/documents/file/<id>",
        "vehicle_registration_number": "MH-12-CD-5678"
      },
      "rejection_reason": "Aadhaar number does not match uploaded name",
      "reviewed_at": "2026-07-14T06:20:16.396Z",
      "submitted_at": "2026-07-14T06:20:16.396Z",
      "updated_at": "2026-07-14T06:20:16.396Z"
    }
  }
}
No links
404	
Not your id

Media type

application/json
Example Value
Schema
{
  "success": false,
  "message": "Something went wrong",
  "errors": [
    {}
  ]
}

