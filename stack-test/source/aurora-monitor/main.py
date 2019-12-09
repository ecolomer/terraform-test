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

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns_topic = os.environ['SNS_SLACK_TOPIC']
creds = aws_get_secret('db-creds')

try:
    conn = pymysql.connect(creds['host'], user=creds['username'], passwd=creds['password'], db=creds['database'], connect_timeout=5)
except pymysql.MySQLError as e:
    logger.error("ERROR: Unexpected error: Could not connect to MySQL instance")
    logger.error(e)
    sys.exit()

logger.info("SUCCESS: Connection to RDS MySQL instance succeeded.")

def handler(event, context):

    sns = boto3.client('sns')

    with conn.cursor() as cur:
        rows = cur.execute("show full processlist")

    if rows > 0:
        #response = sns.publish(TopicArn=sns_topic, Message='No process running')
        logger.info("No process running")

    return None
