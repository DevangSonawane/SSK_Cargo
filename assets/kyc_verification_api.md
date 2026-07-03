POST
/api/kyc/broker
Submit broker KYC (broker only)


Submits the broker's legal + financial identity documents for review. Sets kyc_status to submitted. Resubmitting (e.g. after a rejection) overwrites the previous submission and clears any rejection reason.

Required document keys: pan_number, aadhaar_number, gst_number, bank_account_number, business_registration_number

Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "documents": {
    "pan_number": "ABCDE1234F",
    "aadhaar_number": "XXXX-XXXX-1234",
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

POST
/api/kyc/driver
Submit driver KYC (driver only)



POST
/api/kyc/documents/upload
Upload a KYC document file (not yet configured)


Reserved for uploading document photos/PDFs to object storage (S3/Cloudinary) and returning a URL to reference from POST /api/kyc/broker or /api/kyc/driver. No storage provider is configured yet, so this currently always returns 501 Not Implemented.

Parameters
Try it out
No parameters
Responses
Code	Description	Links
501	
Not configured
Media type

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
        "vehicle_registration_number": "MH-12-CD-5678"
      },
      "rejection_reason": "Aadhaar number does not match uploaded name",
      "reviewed_at": "2026-07-03T05:06:51.733Z",
      "submitted_at": "2026-07-03T05:06:51.733Z",
      "updated_at": "2026-07-03T05:06:51.733Z"
    }
  }
}