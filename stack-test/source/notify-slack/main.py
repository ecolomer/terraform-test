import sys
import os
import logging
import json
import requests
from requests.exceptions import Timeout


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
        raise Exception("ERROR: Could not connect to Slack webhook endpoint.")

    if response.status_code != 200:
        raise ValueError(
            'Request to slack returned an error %s, the response is:\n%s'
            % (response.status_code, response.text)
        )

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):

    sns_message = json.loads(event['Records'][0]['Sns']['Message'])
    notify_slack(sns_message['Event Message'])
