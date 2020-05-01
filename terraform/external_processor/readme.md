# External S3 Processor

this module ingests files in s3


## Architecture

S3 object created event trigger lambda
get the object path, prefix
lambda -> psycog2 create table, index if not exist
upload jsonb
move file to archive folder

#TODO
create separate lambda/mechanism for data promotion
