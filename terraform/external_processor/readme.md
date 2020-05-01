# External S3 Processor

this module ingests files in s3


## Architecture

S3 object created event trigger lambda
read the object path, folder is the table suffix
lambda -> psycog2 create table if not exist, upload jsonb
move file to archive folder


- I drop a valid standard JSON file into S3 (write-only, no public read)
- 1 JSON key gets extracted
- Value is reformatted to JSONL (line delimitation)
- load to staging
- templated in some way so that I could, do this for multiple data sources.
- Each source would have its own ingest table the DB
