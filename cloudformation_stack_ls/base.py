import boto3

def list_stack(stack_arn):
    """list the ARNs of created by a cloudformation stack

    This should list all the identifiable separate resources created
    by cloudformation stack.  
    """
    cloudformation = boto3.client('cloudformation',
                                  region_name="eu-west-1" )
    stacks_resource = cloudformation.list_stack_resources(
        StackName="thetest"
    )
    summaries = stacks_resource["StackResourceSummaries"]
    return [ "arn:s3://" + x['PhysicalResourceId']
             for x in summaries ]
