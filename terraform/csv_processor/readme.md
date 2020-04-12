# CSV S3 Processor

This module launches a lambda function triggered by an s3 object upload to the `unprocessed folder` which gets uploaded to by the api backend.

S3 upload -> notification trigger to lambda -> grab csv, remove banned fields, convert to json, archive in `processed` folder, upload to DB