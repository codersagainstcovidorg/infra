-- Insert into `entities_staging`
--TRUNCATE TABLE "entities_staging" RESTART IDENTITY; -- First, remove all existing values
--INSERT INTO "entities_staging"
--SELECT 
--  *
--FROM 
--  "entities_staging"
--ON CONFLICT ("location_latitude","location_longitude") DO NOTHING
--;


---- Insert into `entities_backup`
TRUNCATE TABLE "entities_backup" RESTART IDENTITY; -- First, remove all existing values
INSERT INTO "entities_backup"
SELECT 
  *
FROM 
  "entities"
ON CONFLICT ("location_id") DO NOTHING
;

-- Insert into `entities`
TRUNCATE TABLE "entities" RESTART IDENTITY; -- First, remove all existing values
INSERT INTO "entities"
SELECT 
  *
FROM 
  "entities_staging"
ON CONFLICT ("location_id") DO NOTHING
;

-- MAKE ALL NULL VALUES EMPTY STRINGS
UPDATE entities SET "location_name" = '' WHERE "location_name" IS NULL;

UPDATE entities SET "location_address_street" = '' WHERE "location_address_street" IS NULL;

UPDATE entities SET "location_address_locality" = '' WHERE "location_address_locality" IS NULL;

UPDATE entities SET "location_address_region" = '' WHERE "location_address_region" IS NULL;

UPDATE entities SET "location_address_postal_code" = '' WHERE "location_address_postal_code" IS NULL;

UPDATE entities SET "location_contact_phone_main" = '' WHERE "location_contact_phone_main" IS NULL;

UPDATE entities SET "location_contact_phone_appointments" = '' WHERE "location_contact_phone_appointments" IS NULL;

UPDATE entities SET "location_contact_phone_covid" = '' WHERE "location_contact_phone_covid" IS NULL;

UPDATE entities SET "location_contact_url_main" = '' WHERE "location_contact_url_main" IS NULL;

UPDATE entities SET "location_contact_url_covid_info" = '' WHERE "location_contact_url_covid_info" IS NULL;

UPDATE entities SET "location_contact_url_covid_screening_tool" = '' WHERE "location_contact_url_covid_screening_tool" IS NULL;

UPDATE entities SET "location_contact_url_covid_virtual_visit" = '' WHERE "location_contact_url_covid_virtual_visit" IS NULL;

UPDATE entities SET "location_contact_url_covid_appointments" = '' WHERE "location_contact_url_covid_appointments" IS NULL;

UPDATE entities SET "location_place_of_service_type" = 'Other' WHERE "location_place_of_service_type" IS NULL;

UPDATE entities SET "location_hours_of_operation" = '' WHERE "location_hours_of_operation" IS NULL;

UPDATE entities SET "is_evaluating_symptoms" = TRUE WHERE "is_evaluating_symptoms" IS NULL;

UPDATE entities SET "is_evaluating_symptoms_by_appointment_only" = TRUE WHERE "is_evaluating_symptoms_by_appointment_only" IS NULL;

UPDATE entities SET "is_ordering_tests" = FALSE WHERE "is_ordering_tests" IS NULL;

UPDATE entities SET "is_ordering_tests_only_for_those_who_meeting_criteria" = TRUE WHERE "is_ordering_tests_only_for_those_who_meeting_criteria" IS NULL;

UPDATE entities SET "is_collecting_samples" = FALSE WHERE "is_collecting_samples" IS NULL;

UPDATE entities SET "is_collecting_samples_onsite" = TRUE WHERE "is_collecting_samples_onsite" IS NULL;

UPDATE entities SET "is_collecting_samples_for_others" = TRUE WHERE "is_collecting_samples_for_others" IS NULL;

UPDATE entities SET "is_collecting_samples_by_appointment_only" = TRUE WHERE "is_collecting_samples_by_appointment_only" IS NULL;

UPDATE entities SET "is_processing_samples" = FALSE WHERE "is_processing_samples" IS NULL;

UPDATE entities SET "is_processing_samples_onsite" = FALSE WHERE "is_processing_samples_onsite" IS NULL;

UPDATE entities SET "is_processing_samples_for_others" = FALSE WHERE "is_processing_samples_for_others" IS NULL;

UPDATE entities SET "location_specific_testing_criteria" = TRUE WHERE "location_specific_testing_criteria" IS NULL;

UPDATE entities SET "additional_information_for_patients" = '' WHERE "additional_information_for_patients" IS NULL;

UPDATE entities SET "reference_publisher_of_criteria" = '' WHERE "reference_publisher_of_criteria" IS NULL;

UPDATE entities SET "data_source" = '' WHERE "data_source" IS NULL;

UPDATE entities SET "raw_data" = NULL::json WHERE "raw_data" IS NULL;

UPDATE entities SET "geojson" = NULL::json WHERE "geojson" IS NULL;

UPDATE entities SET "location_status" = 'Invalid' WHERE "location_status" IS NULL;

UPDATE entities SET "external_location_id" = '' ;-- WHERE "external_location_id" IS NULL;



