import json
import boto3
from os import getenv
import re
import logging

"""
Expected params in SSM
SECRETS_ARN - arn of the secrets manager secret per env with DB credentials
"""

region = getenv("AWS_REGION", 'us-east-1')
environment = getenv("ENVIRONMENT", "dev")
account_id = boto3.client('sts').get_caller_identity().get('Account')
app_name = "external"
database_name = 'covid'

# Utils
s3 = boto3.client('s3', region_name=region)
rds_client = boto3.client('rds-data', region_name=region)
ssm_client = boto3.client('ssm', region_name=region)
logger=logging.getLogger()

if "staging" in environment:
  logger.setLevel(logging.DEBUG)
else:
  logger.setLevel(logging.INFO)

def get_param(param_name, app_name=app_name, decrypt=True):
  try:
    response = ssm_client.get_parameter(
      Name=f'/{environment}/{app_name}/{param_name}',
      WithDecryption=decrypt
    )
    return response.get("Parameter").get("Value")
  except ssm_client.exceptions.ParameterNotFound:
    return ""

def execute_statement(sql, sql_parameters=[]):
  response = rds_client.execute_statement(
      secretArn=get_param("SECRETS_ARN"),
      database=database_name,
      resourceArn=f'arn:aws:rds:{region}:{account_id}:cluster:cac-{environment}',
      sql=sql,
      parameters=sql_parameters
  )
  return response

def lambda_handler(event, context):

  logger.info("Starting log")

  # Get bucket and object name from event
  temp_json_file = '/tmp/json_file.json'
  
  bucket_name =  event.get("Records")[0]["s3"]["bucket"]["name"]
  s3_file_name = event.get("Records")[0]["s3"]["object"]["key"]
  prefix = re.match(r".*?/", s3_file_name).group(0)

  logger.debug(f"Prefix is {prefix}")

  # create the table if not exists
  execute_statement("""CREATE TABLE IF NOT EXISTS data_ingest (
    record_id SERIAL PRIMARY KEY,
    data jsonb,
    data_source text,
    ingested_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
  );"""
  )

  # create index
  execute_statement("CREATE UNIQUE INDEX data_ingest_pkey ON data_ingest(record_id int4_ops);")

  # Download json
  with open(temp_json_file, 'r') as file:
    s3.download_fileobj(bucket_name, s3_file_name, file)
    json_file = json.loads(file)
    for item in json_file.get("features"):
      logger.debug(item)
      execute_statement('INSERT INTO %s (data, data_source) VALUES (%s, %s)', ("data_ingest", item, f's3://{bucket_name}/{s3_file_name}'))

  logger.debug("Done inserting into db")
  logger.debug("archiving file")
  # archive the file
  s3.copy_object(
    ACL='private',
    Bucket=bucket_name,
    CopySource=f"{bucket_name}/{s3_file_name}",
    Key=f'processed/{s3_file_name}',
    ServerSideEncryption="AES256"
  )
  s3.delete_object(
    Bucket=bucket_name,
    Key=f"{s3_file_name}"
  )

  # close connection
  db_conn.close()

  logger.debug("finished")

if getenv("AWS_EXECUTION_ENV") is None:
  print("running locally")
  # send a mock s3 createobject event locally
  lambda_handler(context=None, event={
  "Records": [
    {
      "eventVersion": "2.1",
      "eventSource": "aws:s3",
      "awsRegion": "us-east-1",
      "eventTime": "2020-04-11T21:28:55.242Z",
      "eventName": "ObjectCreated:Put",
      "userIdentity": {
        "principalId": "AWS:AIDAZRWYIASJ7D5BZIVDG"
      },
      "requestParameters": {
        "sourceIPAddress": "100.35.58.180"
      },
      "responseElements": {
        "x-amz-request-id": "429FBB27773DCEF4",
        "x-amz-id-2": "7F1v7FLjL+DD6oKHZLRr+QQt1ct5LY28nvYIqofZoav4IKzEV9HqlmxS2sigPArUyeGy9hXLv/JsHiRV31ldwzDzfIg74zuP"
      },
      "s3": {
        "s3SchemaVersion": "1.0",
        "configurationId": "tf-s3-lambda-20200411201958259200000001",
        "bucket": {
          "name": "csv-processor-staging-9129jf",
          "ownerIdentity": {
            "principalId": "A1L038QWBHPTNL"
          },
          "arn": "arn:aws:s3:::csv-processor-staging-9129jf"
        },
        "object": {
          "key": "unprocessed/sample-entities.csv",
          "size": 2801,
          "eTag": "4ba3c98f54236b34d47d88ad75ee413b",
          "sequencer": "005E92369994E0DA3A"
        }
      }
    }
  ]
})

