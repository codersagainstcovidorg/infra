import json
import boto3
from os import getenv
import re

"""
Expected params in SSM
SECRETS_ARN - arn of the secrets manager secret per env with DB credentials
"""

region = getenv("AWS_REGION", 'us-east-1')
environment = getenv("ENVIRONMENT", "staging")
account_id = boto3.client('sts').get_caller_identity().get('Account')
app_name = "external"
database_name = 'covid'

# Utils
s3 = boto3.client('s3', region_name=region)
rds_client = boto3.client('rds-data', region_name=region)
ssm_client = boto3.client('ssm', region_name=region)

def get_param(param_name, app_name=app_name, decrypt=True):
  try:
    response = ssm_client.get_parameter(
      Name=f'/{environment}/{app_name}/{param_name}',
      WithDecryption=decrypt
    )
    return response.get("Parameter").get("Value")
  except ssm_client.exceptions.ParameterNotFound:
    return ""

def execute_statement(sql, params=[]):
  print(sql)
  response = rds_client.execute_statement(
      secretArn=get_param("SECRETS_ARN"),
      database=database_name,
      resourceArn=f'arn:aws:rds:{region}:{account_id}:cluster:cac-{environment}',
      sql=sql,
      parameters=params
  )
  return response

def lambda_handler(event, context):
  print(event)

  print("starting")

  # Get bucket and object name from event
  temp_json_file = '/tmp/json_file.json'
  
  bucket_name =  event.get("Records")[0]["s3"]["bucket"]["name"]
  s3_file_name = event.get("Records")[0]["s3"]["object"]["key"]
  prefix = re.match(r".*?/", s3_file_name).group(0)
  print("creating table")
  # create the table if not exists
  execute_statement("""CREATE TABLE IF NOT EXISTS data_ingest (
    record_id SERIAL PRIMARY KEY,
    data jsonb,
    data_source text,
    ingested_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
  );"""
  )
  print("creating index")
  # create index
  execute_statement("CREATE UNIQUE INDEX IF NOT EXISTS data_ingest_pkey ON data_ingest(record_id int4_ops);")

  # Download json
  print("downloading json")
  with open(temp_json_file, 'wb') as file:
    s3.download_fileobj(bucket_name, s3_file_name, file)

  with open(temp_json_file, 'r') as file:
    json_file = json.load(file)
    for item in json_file.get("features"):
      print("inserting into db")
      data = {'name':'data', 'value':{'stringValue': json.dumps(item)}}
      data_source = {'name':'data_source', 'value':{'stringValue': f's3://{bucket_name}/{s3_file_name}'}}
      execute_statement("INSERT INTO data_ingest(data, data_source) VALUES(:data::jsonb, :data_source)", [data, data_source])

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

if getenv("AWS_EXECUTION_ENV") is None:
  print("running locally")
  # send a mock s3 createobject event locally
  lambda_handler(context=None, event={'Records': [{'eventVersion': '2.1', 'eventSource': 'aws:s3', 'awsRegion': 'us-east-1', 'eventTime': '2020-05-03T01:49:27.979Z', 'eventName': 'ObjectCreated:Put', 'userIdentity': {'principalId': 'AWS:AIDAZRWYIASJ7D5BZIVDG'}, 'requestParameters': {'sourceIPAddress': '100.35.58.180'}, 'responseElements': {'x-amz-request-id': 'C848808C13E4B4B9', 'x-amz-id-2': '3b8AZW31rCpjqAtX1NTHdXqlpnYqQ/ORlOE6VweZRkPYlTiLI7wdlUYUjaYv7PA/0U6k4tK5R7JTKr2ZJBvTviJBzif2SdR7'}, 's3': {'s3SchemaVersion': '1.0', 'configurationId': 'tf-s3-lambda-20200501051803146600000002', 'bucket': {'name': 'external-processor-staging-1k3o42', 'ownerIdentity': {'principalId': 'A1L038QWBHPTNL'}, 'arn': 'arn:aws:s3:::external-processor-staging-1k3o42'}, 'object': {'key': 'test/2020-04-29_1452_giscorps_safe.json', 'size': 4845527, 'eTag': '9e6c7c27d816a7761109a006b1292ab9', 'sequencer': '005EAE232A8CF160DE'}}}]})

