import csv
import json
import boto3
import requests

s3 = boto3.client('s3')
fieldnames = ("")


# csvfile = open('file.csv', 'r')
# jsonfile = open('file.json', 'w')

# fieldnames = ("FirstName","LastName","IDNumber","Message")
# reader = csv.DictReader( csvfile, fieldnames)
# out = json.dumps( [ row for row in reader ] )
# jsonfile.write(out)

def lambda_handler(event, context):
  # Get bucket and object name from event
  bucket_name =  event.get("Records")[0]["s3"]["bucket"]["name"]
  csv_file_name = event.get("Records")[0]["s3"]["object"]["key"]

  print(csv_file_name)
  
  # Download csv
  with open('/tmp/csv_file.csv', 'wb') as file:
    s3.download_fileobj(bucket_name, csv_file_name, file)

  # convert csv to json
  with open('/tmp/csv_file.csv', 'r') as csv_file:
    with open('/tmp/json_file.json', 'w') as json_file:
      reader = csv.DictReader(csv_file, fieldnames)
      json_out = json.dumps( [ row for row in reader ] )
      json_file.write(json_out)
      print(json_file)

  # upload to db

  # move file to archive