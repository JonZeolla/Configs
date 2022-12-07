#!/usr/bin/env python3

import sys, json;

try:
    data=json.load(sys.stdin)
except:
    print('Not valid JSON, exiting...')
    exit(1)

print('export AWS_ACCESS_KEY_ID="%s"' % data['Credentials']['AccessKeyId'])
print('export AWS_SECRET_ACCESS_KEY="%s"' % data['Credentials']['SecretAccessKey'])
print('export AWS_SESSION_TOKEN="%s"' % data['Credentials']['SessionToken'])
