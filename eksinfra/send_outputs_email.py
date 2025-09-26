#!/usr/bin/env python3
import boto3
import sys
import os
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication

def send_outputs_email():
    # Environment variables
    sender_email = os.environ.get('SENDER_EMAIL')
    recipient_email = os.environ.get('RECIPIENT_EMAIL')
    aws_region = os.environ.get('AWS_DEFAULT_REGION', 'eu-west-2')
    
    if not sender_email or not recipient_email:
        print("Error: SENDER_EMAIL and RECIPIENT_EMAIL must be set")
        sys.exit(1)
    
    # Read terraform outputs
    try:
        with open('output.json', 'r') as f:
            outputs_content = f.read()
    except FileNotFoundError:
        print("Error: output.json not found")
        sys.exit(1)
    
    # Create email
    msg = MIMEMultipart()
    msg['From'] = sender_email
    msg['To'] = recipient_email
    msg['Subject'] = f"Terraform Apply Completed - Pipeline {os.environ.get('CI_PIPELINE_ID', 'Unknown')}"
    
    # Email body
    body = f"""
Terraform Apply Successfully Completed

Project: {os.environ.get('CI_PROJECT_NAME', 'Unknown')}
Pipeline: {os.environ.get('CI_PIPELINE_ID', 'Unknown')}
Branch: {os.environ.get('CI_COMMIT_REF_NAME', 'Unknown')}
Commit: {os.environ.get('CI_COMMIT_SHA', 'Unknown')}

Infrastructure has been successfully deployed. Please find the Terraform outputs attached.

Pipeline URL: {os.environ.get('CI_PIPELINE_URL', 'N/A')}
"""
    
    msg.attach(MIMEText(body, 'plain'))
    
    # Attach outputs file
    with open('output.json', 'rb') as f:
        attachment = MIMEApplication(f.read(), _subtype='json')
        attachment.add_header('Content-Disposition', 'attachment', filename='terraform-outputs.json')
        msg.attach(attachment)
    
    # Send email via SES
    try:
        ses_client = boto3.client('ses', region_name=aws_region)
        response = ses_client.send_raw_email(
            Source=sender_email,
            Destinations=[recipient_email],
            RawMessage={'Data': msg.as_string()}
        )
        print(f"Outputs email sent successfully. Message ID: {response['MessageId']}")
    except Exception as e:
        print(f"Error sending outputs email: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    send_outputs_email()