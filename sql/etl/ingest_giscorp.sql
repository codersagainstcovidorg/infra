---- Create temporary table to hold ingested data while we work -------------------------------
CREATE TEMP TABLE IF NOT EXISTS ingest_giscorps (
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
    "is_screening_onsite" boolean,
    "is_collecting_onsite" boolean,
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
    "state" text,
    "lat" double precision,
    "long" double precision,
    "raw_data" jsonb
);

TRUNCATE TABLE "ingest_giscorps" RESTART IDENTITY; -- Truncate existing table (if already existed)

---- Extract and translate ----------------------------------------------
WITH source AS (
  SELECT
   "data"#>>'{attributes,OBJECTID}' AS "OBJECTID"
   ,"data"#>'{geometry}' AS "geometry"
   ,"data"#>'{attributes}' AS "attr"
   ,"data" AS "raw_data"
  FROM 
    data_ingest
  LIMIT 150
)
INSERT INTO ingest_giscorps (
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
  "is_screening_onsite",
  "is_collecting_onsite",
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
  "state",
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
    WHEN (NULLIF(TRIM("attr"#>>'{services_offered_onsite}'), '') IS NOT NULL) THEN TRIM("attr"#>>'{services_offered_onsite}') LIKE ('%creen%')
    ELSE FALSE -- Default value
  END AS "is_screening_onsite",
  
  CASE 
    WHEN (NULLIF(TRIM("attr"#>>'{services_offered_onsite}'), '') IS NOT NULL) THEN LOWER(TRIM("attr"#>>'{services_offered_onsite}')) LIKE ('%test%')
    ELSE FALSE -- Default value
  END AS "is_collecting_onsite",
  
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

---- Transform and load into entities_proc -------------------------------------
TRUNCATE TABLE "entities_proc" RESTART IDENTITY; -- First, remove all existing values
WITH upd AS (
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
    SELECT
      "location_id",
      
      CASE
        WHEN (
          ("lat" IS NULL) OR ("long" IS NULL)
          OR ("status" IN ('Not Publicly Shared', 'Invalid', '', 'Missing Data', ''))
          OR ("status" IS NULL)
        ) THEN TRUE
        ELSE FALSE
      END AS "is_hidden"
      
      ,CASE
        WHEN (
          ("lat" IS NULL) OR ("long" IS NULL)
          OR ("status" IN ('Pending Review', 'Invalid', '', 'Missing Data', ''))
          OR ("status" IS NULL)
        ) THEN FALSE
        ELSE TRUE
      END AS "is_verified"
      
      ,"name" AS "location_name"
      ,"address" AS "location_address_street"
      ,"county" AS "location_address_locality"
      ,"state" AS "location_address_region"
      ,'' AS "location_address_postal_code"
      ,"lat" AS "location_latitude"
      ,"long" AS "location_longitude"
      ,"phone" AS "location_contact_phone_main"
      ,"phone" AS "location_contact_phone_appointments"
      ,"phone" AS "location_contact_phone_covid"
      ,"managing_organization_url" AS "location_contact_url_main"
      ,"managing_organization_url" AS "location_contact_url_covid_info"
      ,'' AS "location_contact_url_covid_screening_tool"
      
      ,CASE 
        WHEN ("is_virtual_screening_offered" OR "is_virtual_screening_required") THEN TRIM("managing_organization_url") 
      END AS "location_contact_url_covid_virtual_visit"
      
      ,'' AS "location_contact_url_covid_appointments"
      ,"managing_organization_kind" AS "location_place_of_service_type"
      ,"hours_of_operation" AS "location_hours_of_operation"
      ,("is_screening_onsite" OR "is_virtual_screening_offered") AS "is_evaluating_symptoms"
      
      ,("is_screening_onsite" AND NOT("is_virtual_screening_offered") AND ("is_appt_only" OR "is_call_first")) AS "is_evaluating_symptoms_by_appointment_only"
      
      ,(NOT("is_collecting_onsite") AND ("is_screening_onsite" OR "is_virtual_screening_offered")) AS "is_ordering_tests"
      
      ,NULL::boolean AS "is_ordering_tests_only_for_those_who_meeting_criteria"
      
      ,"is_collecting_onsite" AS "is_collecting_samples"
      ,"is_collecting_onsite" AS "is_collecting_samples_onsite"
      
      ,("is_collecting_onsite" AND NOT("is_screening_onsite" OR "is_virtual_screening_offered")) AS "is_collecting_samples_for_others"
      
      ,("is_collecting_onsite" AND ("is_appt_only" OR "is_call_first")) AS "is_collecting_samples_by_appointment_only"
      
      ,"test_processing" IN ('point-of-care','onsite lab','offsite lab','lab') AS "is_processing_samples"
      
      ,"test_processing" IN ('point-of-care','onsite lab') AS "is_processing_samples_onsite"
      
      ,(NOT("is_collecting_onsite" OR "is_screening_onsite" OR "is_virtual_screening_offered") AND ("test_processing" IN ('point-of-care','onsite lab','lab'))) AS "is_processing_samples_for_others"
      
      ,'' AS "location_specific_testing_criteria"
      ,'' AS "additional_information_for_patients"
      ,'' AS "reference_publisher_of_criteria"
      ,CONCAT('[GISCorps] ', TRIM("data_source")) AS "data_source"
      ,"raw_data" AS "raw_data"
      ,NULL::jsonb AS "geojson"
      ,"CreationDate" AS "created_on"
      ,"EditDate" AS "updated_on"
      ,CASE WHEN "status" = 'Closed' THEN "EditDate" ELSE NULL END AS "deleted_on"
      ,"status" AS "location_status"
      ,jsonb_strip_nulls(jsonb_build_array(
        CASE WHEN NULLIF(TRIM("OBJECTID"), '') IS NOT NULL THEN jsonb_build_object(
          'use','primary'
          ,'kind','esriFieldTypeOID'
          ,'system','Esri'
          ,'field','OBJECTID'
          ,'alias','OBJECTID'
          ,'assigner','GISCorps'
          ,'value',NULLIF(TRIM("OBJECTID"), '')
        ) ELSE NULL END
      )) AS "external_location_id"
    FROM
      ingest_giscorps
    WHERE
      "status" NOT IN ('Not Publicly Shared', 'Invalid', 'Missing Data', 'Pending Review', 'NULL', '<Null>','') 
      AND "status" IS NOT NULL
    GROUP BY
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
      "is_screening_onsite",
      "is_collecting_onsite",
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
      "state",
      "lat",
      "long"
  )a
)
INSERT INTO "entities_proc" AS entities (
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
  ,"created_on"
  ,"updated_on"
  ,"deleted_on"
  ,"location_status"
)
SELECT DISTINCT
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
  ,"created_on"
  ,"updated_on"
  ,"deleted_on"
  ,"location_status"
FROM upd
GROUP BY
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
  ,"created_on"
  ,"updated_on"
  ,"deleted_on"
  ,"location_status"
ON CONFLICT ("location_latitude","location_longitude") DO NOTHING
-- ON CONFLICT ("location_id","location_latitude","location_longitude") DO UPDATE
--   SET
--     "location_id" = md5(CONCAT('DUPLICATE|',entities."location_latitude",'|',entities."location_longitude"))::uuid
--     ,"is_hidden" = TRUE
--     ,"is_verified" = FALSE
--     ,"location_name" = EXCLUDED."location_name"
--     ,"location_address_street" = EXCLUDED."location_address_street"
--     ,"location_address_locality" = EXCLUDED."location_address_locality"
--     ,"location_address_region" = EXCLUDED."location_address_region"
--     ,"location_address_postal_code" = EXCLUDED."location_address_postal_code"
--     ,"location_latitude" = EXCLUDED."location_latitude"
--     ,"location_longitude" = EXCLUDED."location_longitude"
--     ,"location_contact_phone_main" = EXCLUDED."location_contact_phone_main"
--     ,"location_contact_phone_appointments" = EXCLUDED."location_contact_phone_appointments"
--     ,"location_contact_phone_covid" = EXCLUDED."location_contact_phone_covid"
--     ,"location_contact_url_main" = EXCLUDED."location_contact_url_main"
--     ,"location_contact_url_covid_info" = EXCLUDED."location_contact_url_covid_info"
--     ,"location_contact_url_covid_screening_tool" = EXCLUDED."location_contact_url_covid_screening_tool"
--     ,"location_contact_url_covid_virtual_visit" = EXCLUDED."location_contact_url_covid_virtual_visit"
--     ,"location_contact_url_covid_appointments" = EXCLUDED."location_contact_url_covid_appointments"
--     ,"location_place_of_service_type" = EXCLUDED."location_place_of_service_type"
--     ,"location_hours_of_operation" = EXCLUDED."location_hours_of_operation"
--     ,"is_evaluating_symptoms" = EXCLUDED."is_evaluating_symptoms"
--     ,"is_evaluating_symptoms_by_appointment_only" = EXCLUDED."is_evaluating_symptoms_by_appointment_only"
--     ,"is_ordering_tests" = EXCLUDED."is_ordering_tests"
--     ,"is_ordering_tests_only_for_those_who_meeting_criteria" = EXCLUDED."is_ordering_tests_only_for_those_who_meeting_criteria"
--     ,"is_collecting_samples" = EXCLUDED."is_collecting_samples"
--     ,"is_collecting_samples_onsite" = EXCLUDED."is_collecting_samples_onsite"
--     ,"is_collecting_samples_for_others" = EXCLUDED."is_collecting_samples_for_others"
--     ,"is_collecting_samples_by_appointment_only" = EXCLUDED."is_collecting_samples_by_appointment_only"
--     ,"is_processing_samples" = EXCLUDED."is_processing_samples"
--     ,"is_processing_samples_onsite" = EXCLUDED."is_processing_samples_onsite"
--     ,"is_processing_samples_for_others" = EXCLUDED."is_processing_samples_for_others"
--     ,"location_specific_testing_criteria" = EXCLUDED."location_specific_testing_criteria"
--     ,"additional_information_for_patients" = EXCLUDED."additional_information_for_patients"
--     ,"reference_publisher_of_criteria" = EXCLUDED."reference_publisher_of_criteria"
--     ,"data_source" = EXCLUDED."data_source"
--     ,"raw_data" = EXCLUDED."raw_data"
--     ,"geojson" = EXCLUDED."geojson"
--     ,"created_on" = EXCLUDED."created_on"
--     ,"updated_on" = EXCLUDED."updated_on"
--     ,"deleted_on" = EXCLUDED."deleted_on"
--     ,"location_status" = EXCLUDED."location_status"
--     ,"external_location_id" = EXCLUDED."external_location_id"
;
--- Testing --
SELECT
  *
FROM
  entities_proc
LIMIT 100


---- Indices -------------------------------------------------------
--CREATE UNIQUE INDEX giscorps_pkey ON giscorps("OBJECTID" text_ops);
--
---- Cleanup -------------------------------------------------------
--DROP INDEX giscorps;
--DROP TABLE giscorps;

;