{
  "Version": "2012-10-17",
  "Id": "AWSConsole-AccessLogs-Policy-1572026561834",
  "Statement": [
      {
          "Sid": "AWSConsoleStmt-1572026561834",
          "Effect": "Allow",
          "Principal": {
              "AWS": "arn:aws:iam::${alb_account_id}:root"
          },
          "Action": "s3:PutObject",
          "Resource": "${s3_arn}/AWSLogs/${account_id}/*"
      },
      {
          "Sid": "AWSLogDeliveryWrite",
          "Effect": "Allow",
          "Principal": {
              "Service": "delivery.logs.amazonaws.com"
          },
          "Action": "s3:PutObject",
          "Resource": "${s3_arn}/AWSLogs/${account_id}/*",
          "Condition": {
              "StringEquals": {
                  "s3:x-amz-acl": "bucket-owner-full-control"
              }
          }
      },
      {
          "Sid": "AWSLogDeliveryAclCheck",
          "Effect": "Allow",
          "Principal": {
              "Service": "delivery.logs.amazonaws.com"
          },
          "Action": "s3:GetBucketAcl",
          "Resource": "${s3_arn}"
      }
  ]
}