import csv
import json
import boto3
import requests
from os import getenv

# utils
s3 = boto3.client('s3', region_name=getenv("AWS_REGION", 'us-east-1'))
ssm_client = boto3.client('ssm', region_name=getenv("AWS_REGION", 'us-east-1'))
db_endpoint = "https://api.findcovidtesting.com" if "production" in getenv("ENVIRONMENT") else "https://api.staging.findcovidtesting.com"
db_url = f'{db_endpoint}/api/v1/location'

def get_param(param_name, app_name="backend", decrypt=True):
  try:
    response = ssm_client.get_parameter(
      Name=f'/{getenv("ENVIRONMENT", "dev")}/{app_name}/{param_name}',
      WithDecryption=decrypt
    )
    return response.get("Parameter").get("Value")
  except ssm_client.exceptions.ParameterNotFound:
    return ""

def lambda_handler(event, context):
  # Get bucket and object name from event
  BASIC_AUTH_USERNAME = get_param("BASIC_AUTH_USERNAME")
  BASIC_AUTH_PASSWORD = get_param("BASIC_AUTH_PASSWORD")
  temp_csv_file = '/tmp/csv_file.csv'
  temp_json_file = '/tmp/json_file.json'
  
  bucket_name =  event.get("Records")[0]["s3"]["bucket"]["name"]
  csv_file_name = event.get("Records")[0]["s3"]["object"]["key"]
  
  json_blob_list = []
  # Download csv
  with open(temp_csv_file, 'wb') as file:
    s3.download_fileobj(bucket_name, csv_file_name, file)

  # convert csv to json
  with open(temp_csv_file, 'r') as csv_file:
    with open(temp_json_file, 'w') as json_file:
      # read the csv and store it as a dict
      reader = csv.DictReader(csv_file)
      for row in reader:
        # remove these fields just in case they exist
        row.pop('location_id')
        row.pop('record_id')
        row.pop('created_on')
        row.pop('updated_on')
        row.pop('deleted_on')
        json_blob_list.append(row)
      # write the data as json
      json_out = json.dumps( json_blob_list )
      json_file.write(json_out)

  # upload the processed file for archival, later validation if needed - processed/$csvfile.csv.json
  s3.upload_file(temp_json_file, bucket_name, f'{csv_file_name.replace("unprocessed", "processed")}.json')
  # archive the csv, basically rename the file
  s3.copy_object(
    ACL='private',
    Bucket=bucket_name,
    CopySource=f"{bucket_name}/{csv_file_name}",
    Key=f"{csv_file_name.replace('unprocessed', 'processed')}",
    ServerSideEncryption="AES256"
  )
  s3.delete_object(
    Bucket=bucket_name,
    Key=f"{csv_file_name}"
  )

  # upload the json to db
  headers = {'Content-Type':'application/json'}
  r = requests.post(db_url, auth=(BASIC_AUTH_USERNAME, BASIC_AUTH_PASSWORD), data=open(temp_json_file, 'rb'), headers=headers)

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