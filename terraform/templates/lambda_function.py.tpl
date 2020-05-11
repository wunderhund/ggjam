# Inspired by: https://www.linkedin.com/pulse/use-aws-codecommit-lambda-trigger-codebuild-container-trevor-sullivan/

import boto3

def entrypoint(event, context):
  print('Starting a new build ...')
  cb = boto3.client('codebuild')
  build = {
    'projectName': '${codebuild_project}'
  }
  print('Starting build for project {0}'.format(build['projectName']))
  cb.start_build(**build)
  print('Successfully launched a new CodeBuild project build!')
