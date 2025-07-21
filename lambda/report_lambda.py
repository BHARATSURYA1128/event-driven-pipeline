import boto3
import time
from datetime import datetime

athena = boto3.client('athena')
ses = boto3.client('ses')

# Constants
DATABASE = 'eventdb'
QUERY = "SELECT COUNT(*) FROM events_table"
ATHENA_OUTPUT = 's3://event-pipeline-storage/athena-results/'  # must exist
EMAIL = 'you@gmail.com'  # must be verified in SES

def lambda_handler(event, context):
    # Step 1: Run the Athena query
    response = athena.start_query_execution(
        QueryString=QUERY,
        QueryExecutionContext={'Database': DATABASE},
        ResultConfiguration={'OutputLocation': ATHENA_OUTPUT}
    )

    query_id = response['QueryExecutionId']

    # Step 2: Wait for query to finish (simple wait loop)
    time.sleep(10)

    # Step 3: Fetch results
    results = athena.get_query_results(QueryExecutionId=query_id)
    count = results['ResultSet']['Rows'][1]['Data'][0]['VarCharValue']

    # Step 4: Send Email via SES
    ses.send_email(
        Source=EMAIL,
        Destination={'ToAddresses': [EMAIL]},
        Message={
            'Subject': {'Data': 'Daily Event Summary'},
            'Body': {'Text': {'Data': f'Total events today: {count}'}}
        }
    )

    return {
        'statusCode': 200,
        'body': f'Sent summary email: {count} events.'
    }
