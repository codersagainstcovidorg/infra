-- FINAL VERSION
CREATE TEMP TABLE IF NOT EXISTS giscorps (
    "OBJECTID" text PRIMARY KEY,
    "location_id" text,
    -- "facilityid" text,
    -- "GlobalID" text,
    "name" text,
    "address" text,
    "phone" text,
    "period_start" date,
    "period_end" date,
    "hours_of_operation" text,
    "managing_organization" text,
    "managing_organization_kind" text,
    "managing_organization_url" text,
    "health_dept_url" text,
    "status" text,
    "services_offered_onsite" text,
    "test_kind" text,
    "test_processing" text,
    "is_flagged" boolean,
    "is_appt_only" boolean,
    "is_call_first" boolean,
    "is_referral_required" boolean,
    "is_virtual_screening_offered" boolean,
    "is_virtual_screening_required" boolean,
    "is_drive_through" boolean,
    "data_source" text,
    "EditDate" TIMESTAMP,
    "CreationDate" TIMESTAMP,
    "testcapacity" numeric,
    "numvehicles" numeric,
    "municipality" text,
    "county" text,
    "State" text,
    "lat" double precision,
    "long" double precision,
    "raw_data" jsonb
);
TRUNCATE TABLE "giscorps" RESTART IDENTITY;
WITH source AS (
  SELECT
   "data"#>>'{attributes,OBJECTID}' AS "OBJECTID"
   ,"data"#>'{geometry}' AS "geometry"
   ,"data"#>'{attributes}' AS "attr"
   ,"data" AS "raw_data"
  FROM 
    data_ingest
  LIMIT 10
)
INSERT INTO giscorps (
  "OBJECTID",
    -- "facilityid",
    -- "GlobalID",
    "location_id",
    "name",
    "address",
    "phone",
    "period_start",
    "period_end",
    "hours_of_operation",
    "managing_organization",
    "managing_organization_kind",
    "managing_organization_url",
    "health_dept_url",  
    "status",
    "services_offered_onsite",
    "test_kind",
    "test_processing",
    "is_flagged",
    "is_appt_only",
    "is_call_first",
    "is_referral_required",
    "is_virtual_screening_offered",
    "is_virtual_screening_required",
    "is_drive_through",
    "data_source",
    "EditDate",
    "CreationDate",
    "testcapacity",
    "numvehicles",
    "municipality",
    "county",
    "State",
    "lat",
    "long",
    "raw_data"
)
SELECT 
  "OBJECTID",
  -- "facilityid",
  -- "GlobalID",
  CASE
    WHEN ((COALESCE(("geometry" #>> '{Latitude}'),("geometry" #>> '{y}'))::double precision IS NOT NULL) AND (COALESCE(("geometry" #>> '{Longitude}'),("geometry" #>> '{x}'))::double precision IS NOT NULL))
    THEN uuid_in(
      md5(
        ((COALESCE(("geometry" #>> '{Latitude}'),("geometry" #>> '{y}'))::double precision)::text || (COALESCE(("geometry" #>> '{Longitude}'),("geometry" #>> '{x}'))::double precision)::text)
        )::cstring
      ) 
    ELSE uuid_in(md5(random()::text || now()::text)::cstring)
  END AS "location_id",
  
  COALESCE(TRIM("attr"#>>'{name}'), '') AS "name",
  COALESCE(TRIM("attr"#>>'{fulladdr}'), '') AS "address",
  COALESCE(TRIM("attr"#>>'{phone}'), '') AS "phone",
  COALESCE(("attr"#>>'{start_date}')::DATE,to_timestamp(("attr"#>>'{CreationDate}')::double precision / 1000)::date) AS "period_start",
  COALESCE(("attr"#>>'{end_date}')::DATE, '9999-12-31'::DATE) AS "period_end",
  COALESCE(TRIM("attr"#>>'{operhours}'), '') AS "hours_of_operation",
  COALESCE(TRIM("attr"#>>'{agency}'), '') AS "managing_organization",
  COALESCE(TRIM("attr"#>>'{agencytype}'), '') AS "managing_organization_kind",
  COALESCE(TRIM("attr"#>>'{agencyurl}'), '') AS "managing_organization_url",
  COALESCE(TRIM("attr"#>>'{health_dept_url}'), '') AS "health_dept_url",
  COALESCE(TRIM("attr"#>>'{status}'), '') AS "status",
  COALESCE(TRIM("attr"#>>'{services_offered_onsite}'), '') AS "services_offered_onsite",
  COALESCE(TRIM("attr"#>>'{test_type}'),TRIM("attr"#>>'{type_of_test}'), '') AS "test_kind",
  COALESCE(TRIM("attr"#>>'{test_processing}'), '') AS "test_processing",
  COALESCE(TRIM("attr"#>>'{red_flag}'), '') = 'Yes' AS "is_flagged",
  
  CASE 
    WHEN (NULLIF(TRIM("attr"#>>'{appt_only}'), '') IS NOT NULL) THEN TRIM("attr"#>>'{appt_only}') = 'Yes' 
    ELSE TRUE -- Default value
  END AS "is_appt_only",
  
  CASE 
    WHEN (NULLIF(TRIM("attr"#>>'{call_first}'), '') IS NOT NULL) THEN TRIM("attr"#>>'{call_first}') = 'Yes' 
    ELSE TRUE -- Default value
  END AS "is_call_first",
  
  CASE 
    WHEN (NULLIF(TRIM("attr"#>>'{referral_required}'), '') IS NOT NULL) THEN TRIM("attr"#>>'{referral_required}') = 'Yes' 
    WHEN (NULLIF(TRIM("attr"#>>'{services_offered_onsite}'), '') IS NOT NULL) THEN ("attr"#>>'{services_offered_onsite}') NOT LIKE ('%creen%')
    ELSE FALSE -- Default value
  END AS "is_referral_required",
  
  CASE 
    WHEN (NULLIF(TRIM("attr"#>>'{virtual_screening}'), '') IS NOT NULL) THEN TRIM("attr"#>>'{virtual_screening}') IN ('Available','Required')
    ELSE TRUE -- Default value
  END AS "is_virtual_screening_offered",
  
  CASE 
    WHEN (NULLIF(TRIM("attr"#>>'{virtual_screening}'), '') IS NOT NULL) THEN TRIM("attr"#>>'{virtual_screening}') IN ('Required')
    ELSE TRUE -- Default value
  END AS "is_virtual_screening_required",
  
  ("attr"#>>'{drive_through}') = 'Yes' AS "is_drive_through",
  
  COALESCE(TRIM("attr"#>>'{data_source}'), '') AS "data_source",
  
  to_timestamp(("attr"#>>'{EditDate}')::double precision / 1000) AS "EditDate",
  
  to_timestamp(("attr"#>>'{CreationDate}')::double precision / 1000) AS "CreationDate",
  
  TRIM("attr"#>>'{testcapacity}')::integer AS "testcapacity",
  
  TRIM("attr"#>>'{numvehicles}')::integer AS "numvehicles",
  
  TRIM("attr"#>>'{municipality}') AS "municipality",
  
  TRIM("attr"#>>'{county}') AS "county",
  
  TRIM("attr"#>>'{State}') AS "State",
  
  COALESCE(("geometry" #>> '{Latitude}'),("geometry" #>> '{y}'))::double precision AS "lat",
  
  COALESCE(("geometry" #>> '{Longitude}'),("geometry" #>> '{x}'))::double precision AS "long",
  
  "raw_data"
FROM
  source
;

---- Insert into entities_proc -------------------------------------
upd_1 AS (
  SELECT
    "location_id"
    ,"is_hidden"
    ,"is_verified"
    ,"location_name"
    ,"location_address_street"
    ,"location_address_locality"
    ,"location_address_region"
    ,"location_address_postal_code"
    ,"location_latitude"
    ,"location_longitude"
    ,"location_contact_phone_main"
    ,"location_contact_phone_appointments"
    ,"location_contact_phone_covid"
    ,"location_contact_url_main"
    ,"location_contact_url_covid_info"
    ,"location_contact_url_covid_screening_tool"
    ,"location_contact_url_covid_virtual_visit"
    ,"location_contact_url_covid_appointments"
    ,"location_place_of_service_type"
    ,"location_hours_of_operation"
    ,"is_evaluating_symptoms"
    ,"is_evaluating_symptoms_by_appointment_only"
    ,"is_ordering_tests"
    ,"is_ordering_tests_only_for_those_who_meeting_criteria"
    ,"is_collecting_samples"
    ,"is_collecting_samples_onsite"
    ,"is_collecting_samples_for_others"
    ,"is_collecting_samples_by_appointment_only"
    ,"is_processing_samples"
    ,"is_processing_samples_onsite"
    ,"is_processing_samples_for_others"
    ,"location_specific_testing_criteria"
    ,"additional_information_for_patients"
    ,"reference_publisher_of_criteria"
    ,"data_source"
    ,"raw_data"
    ,"geojson"
    ,"created_on"
    ,"updated_on"
    ,"deleted_on"
    ,"location_status"
    ,"external_location_id"
  FROM (
    SELECT DISTINCT
      md5(CONCAT("y","x"))::uuid AS "location_id",
      CASE
        WHEN (
          ("x" = '') OR ("y" = '')
          OR ("Status" IN ('Not Publicly Shared', 'Invalid', '', 'Missing Data', ''))
          OR ("Status" IS NULL)
        ) THEN TRUE
        ELSE FALSE
      END AS "is_hidden"
      ,CASE
        WHEN (
          ("x" = '') OR ("y" = '')
          OR ("Status" IN ('Pending Review', 'Invalid', '', 'Missing Data', ''))
          OR ("Status" IS NULL)
        ) THEN FALSE
        ELSE TRUE
      END AS "is_verified"
      ,"Name of Facility" AS "location_name"
      ,"Full Address" AS "location_address_street"
      ,'' AS "location_address_locality"
      ,'' AS "location_address_region"
      ,'' AS "location_address_postal_code"
      ,"y"::double precision AS "location_latitude"
      ,"x"::double precision AS "location_longitude"
      ,"Phone" AS "location_contact_phone_main"
      ,'' AS "location_contact_phone_appointments"
      ,'' AS "location_contact_phone_covid"
      ,"Website" AS "location_contact_url_main"
      ,'' AS "location_contact_url_covid_info"
      ,CASE 
        WHEN ("Virtual/Telehealth Screening" IN ('Available', 'Required')) THEN TRIM("Website") 
      END AS "location_contact_url_covid_screening_tool"
      ,'' AS "location_contact_url_covid_virtual_visit"
      ,'' AS "location_contact_url_covid_appointments"
      ,"Owner Type" AS "location_place_of_service_type"
      ,"Operational Hours" AS "location_hours_of_operation"
      ,TRIM("Services Offered") IN ('screening and testing', 'screening only') AS "is_evaluating_symptoms"
      ,CASE
        WHEN (
          (TRIM("Services Offered") IN ('screening and testing', 'screening only') AND ((TRIM("Call first") = 'Yes') OR ((TRIM("Referral Required") = 'Yes'))))
          AND (TRIM("Appointment Only") = 'Yes')
          ) THEN TRUE
        ELSE FALSE
      END AS "is_evaluating_symptoms_by_appointment_only"
      ,NULL::boolean AS "is_ordering_tests"
      ,TRIM("Referral Required") = 'Yes' AS "is_ordering_tests_only_for_those_who_meeting_criteria"
      ,TRIM("Services Offered") IN ('screening and testing', 'testing only') AS "is_collecting_samples"
      ,TRIM("Services Offered") IN ('screening and testing', 'testing only') AS "is_collecting_samples_onsite"
      ,NULL::boolean AS "is_collecting_samples_for_others"
      ,CASE
        WHEN (
          (TRIM("Services Offered") IN ('screening and testing', 'testing only') AND ((TRIM("Call first") = 'Yes') OR ((TRIM("Referral Required") = 'Yes'))))
          AND (TRIM("Appointment Only") = 'Yes')
          ) THEN TRUE
        ELSE FALSE
      END AS "is_collecting_samples_by_appointment_only"
      ,NULL::boolean AS "is_processing_samples"
      ,NULL::boolean AS "is_processing_samples_onsite"
      ,NULL::boolean AS "is_processing_samples_for_others"
      ,COALESCE(description."value", TRIM("Instructions", '')) AS "location_specific_testing_criteria"
      ,COALESCE(TRIM("Comments", '')) AS "additional_information_for_patients"
      ,'' AS "reference_publisher_of_criteria"
      ,CONCAT('[GISCorps] ', TRIM("Data Source")) AS "data_source"
      ,jsonb_build_object(
        'OBJECTID', NULLIF(TRIM(giscorps."OBJECTID"), 'NULL')
        ,'Facility ID', NULLIF(TRIM("Facility ID"), 'NULL')
        ,'Name of Facility', NULLIF(TRIM("Name of Facility"), 'NULL')
        ,'Full Address', NULLIF(TRIM("Full Address"), 'NULL')
        ,'Municipality', NULLIF(TRIM("Municipality"), 'NULL')
        ,'Owner Name', NULLIF(TRIM("Owner Name"), 'NULL')
        ,'Owner Type', NULLIF(TRIM("Owner Type"), 'NULL')
        ,'Phone', NULLIF(TRIM("Phone"), 'NULL')
        ,'Website', NULLIF(TRIM("Website"), 'NULL')
        ,'Operational Hours', NULLIF(TRIM("Operational Hours"), 'NULL')
        ,'Contact Name', NULLIF(TRIM("Contact Name"), 'NULL')
        ,'Contact Phone', NULLIF(TRIM("Contact Phone"), 'NULL')
        ,'Contact Email', NULLIF(TRIM("Contact Email"), 'NULL')
        ,'Comments', NULLIF(TRIM("Comments"), 'NULL')
        ,'Instructions', NULLIF(TRIM("Instructions"), 'NULL')
        ,'Vehicle Capacity', NULLIF(TRIM("Vehicle Capacity"), 'NULL')
        ,'Daily Testing Capacity', NULLIF(TRIM("Daily Testing Capacity"), 'NULL')
        ,'Status', NULLIF(TRIM("Status"), 'NULL')
        ,'CreationDate', NULLIF(TRIM("CreationDate"), 'NULL')
        ,'Creator', NULLIF(TRIM("Creator"), 'NULL')
        ,'EditDate', NULLIF(TRIM("EditDate"), 'NULL')
        ,'Editor', NULLIF(TRIM("Editor"), 'NULL')
        ,'Vetted', NULLIF(TRIM("Vetted"), 'NULL')
        ,'Drive-through', NULLIF(TRIM("Drive-through"), 'NULL')
        ,'Appointment Only', NULLIF(TRIM("Appointment Only"), 'NULL')
        ,'Referral Required', NULLIF(TRIM("Referral Required"), 'NULL')
        ,'Services Offered', NULLIF(TRIM("Services Offered"), 'NULL')
        ,'Call first', NULLIF(TRIM("Call first"), 'NULL')
        ,'Virtual/Telehealth Screening', NULLIF(TRIM("Virtual/Telehealth Screening"), 'NULL')
        ,'Local Health Department URL', NULLIF(TRIM("Local Health Department URL"), 'NULL')
        ,'State or Territory', NULLIF(TRIM("State or Territory"), 'NULL')
        ,'GlobalID', NULLIF(TRIM("GlobalID"), 'NULL')
        ,'Data Source', NULLIF(TRIM("Data Source"), 'NULL')
        ,'Test Type', NULLIF(TRIM("Test Type"), 'NULL')
        ,'County', NULLIF(TRIM("County"), 'NULL')
        ,'x', NULLIF(TRIM("x"), 'NULL')
        ,'y', NULLIF(TRIM("y"), 'NULL')
      ) AS "raw_data"
      ,NULL AS "geojson"
      ,COALESCE(NULLIF(TRIM("CreationDate"), '')::TIMESTAMP, NOW()) AS "created_on"
      ,COALESCE(NOW()) AS "updated_on"
      ,CASE WHEN "Status" = 'Closed' THEN "EditDate"::TIMESTAMP ELSE NULL END AS "deleted_on"
      ,"Status" AS "location_status"
      ,jsonb_strip_nulls(jsonb_build_array(
        CASE WHEN NULLIF(TRIM(giscorps."OBJECTID"), '') IS NOT NULL THEN jsonb_build_object(
          'use','primary'
          ,'kind','esriFieldTypeOID'
          ,'system','Esri'
          ,'field','OBJECTID'
          ,'alias','OBJECTID'
          ,'assigner','GISCorps'
          ,'value',NULLIF(TRIM(giscorps."OBJECTID"), '')
        ) ELSE NULL END
        ,CASE WHEN NULLIF(TRIM("Facility ID"), '') IS NOT NULL THEN jsonb_build_object(
          'use','other'
          ,'kind','esriFieldTypeString'
          ,'system','Esri'
          ,'field','facilityid'
          ,'alias', 'Facility ID'
          ,'assigner','GISCorps'
          ,'value',NULLIF(TRIM("Facility ID"), '')
        ) ELSE NULL END
        ,CASE WHEN NULLIF(TRIM("GlobalID"), '') IS NOT NULL THEN jsonb_build_object(
          'use','other'
          ,'kind','esriFieldTypeGlobalID'
          ,'system','Esri'
          ,'field','GlobalID'
          ,'alias', 'GlobalID'
          ,'assigner','Esri'
          ,'value',NULLIF(TRIM("GlobalID"), '')
        ) ELSE NULL END
      )) AS "external_location_id"
    FROM
      "giscorps" AS "giscorps"
      ,description
    WHERE
      ("x" <> '') 
      AND ("y" <> '')
      AND "Status" NOT IN ('Not Publicly Shared', 'Invalid', 'Missing Data', 'Pending Review', 'NULL', '') 
      AND "Status" IS NOT NULL
      AND giscorps."OBJECTID" = description."OBJECTID"
    GROUP BY
      giscorps."OBJECTID",
      description.value,
      "Facility ID", 
      "Name of Facility", 
      "Full Address", 
      "Municipality", 
      "Owner Name", 
      "Owner Type", 
      "Phone", 
      "Website", 
      "Operational Hours", 
      "Contact Name", 
      "Contact Phone", 
      "Contact Email", 
      "Comments", 
      "Instructions", 
      "Vehicle Capacity", 
      "Daily Testing Capacity", 
      "Status", 
      "CreationDate", 
      "Creator", 
      "EditDate", 
      "Editor", 
      "Vetted", 
      "Drive-through", 
      "Appointment Only", 
      "Referral Required", 
      "Services Offered", 
      "Call first", 
      "Virtual/Telehealth Screening", 
      "Local Health Department URL", 
      "State or Territory", 
      "GlobalID", 
      "Data Source", 
      "Test Type", 
      "County", 
      "x", 
      "y" 
    
  )a
)

--- Testing --
SELECT
  *
FROM
  giscorps
LIMIT 10


---- Indices -------------------------------------------------------
--CREATE UNIQUE INDEX giscorps_pkey ON giscorps("OBJECTID" text_ops);
--
---- Cleanup -------------------------------------------------------
--DROP INDEX giscorps;
--DROP TABLE giscorps;

;