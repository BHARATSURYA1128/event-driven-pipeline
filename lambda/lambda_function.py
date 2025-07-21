import json
import boto3
import datetime

s3 = boto3.client('s3')
BUCKET = 'event-pipeline-storage'  # Replace later if changed

def lambda_handler(event, context):
    data = json.loads(event['body'])
    filename = f"event_{datetime.datetime.utcnow().isoformat()}.json"

    s3.put_object(
        Bucket=BUCKET,
        Key=f"events/{filename}",
        Body=json.dumps(data)
    )

    return {
        'statusCode': 200,
        'body': json.dumps({"message": "Data saved."})
    }
