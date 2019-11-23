import sys
import os
import logging
import json
import boto3
import pymysql
import requests
from requests.exceptions import Timeout

def aws_get_secret(secret_name):
    sm_client = boto3.client('secretsmanager')
    response = sm_client.get_secret_value(SecretId=secret_name)
    sm_secret = response['SecretString']

    try:
        sm_secret = json.loads(sm_secret)
        return sm_secret
    except:
        return sm_secret

def notify_slack(message):
    slack_url = os.environ['SLACK_WEBHOOK_URL']
    slack_data = { 'text': message }

    try:
        response = requests.post(
            slack_url, data=json.dumps(slack_data),
            headers={'Content-Type': 'application/json'},
            Timeout=5
        )
    except:
        raise Exception("ERROR: Could not connect to Slack webhook endpoint")

    if response.status_code != 200:
        raise ValueError(
            'Request to slack returned an error %s, the response is:\n%s'
            % (response.status_code, response.text)
        )

creds = aws_get_secret('db-prod-aurora-cluster-monitor-creds')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

try:
    conn = pymysql.connect(creds['host'], user=creds['username'], passwd=creds['password'], db=creds['database'], connect_timeout=5)
except pymysql.MySQLError as e:
    logger.error("ERROR: Unexpected error: Could not connect to MySQL instance.")
    logger.error(e)
    sys.exit()

logger.info("SUCCESS: Connection to RDS MySQL instance succeeded")

def handler(event, context):

    with conn.cursor() as cur:
        rows = cur.execute("show full processlist")

    if rows > 0:
        #notify_slack("No process running")
        logger.info("No process running")

    return None