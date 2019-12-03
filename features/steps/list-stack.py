import boto3
import cloudformation_stack_ls
from hamcrest import assert_that, contains, not_, has_item, contains_string, matches_regexp
from subprocess import CalledProcessError, run

@given(u'that I have access to an account which has non-cloud formation resources')
def step_impl(context):
    context.cloudformation_client = boto3.client('cloudformation', region_name="eu-west-1" )


@given(u'that I have a stack in cloudformation with resources created')
def step_impl(context):
    cloudformation = context.cloudformation_client
    with open("fixtures/simple-stack.yml") as f:
        template = f.read()
    try:
        context.stack_setup_response = cloudformation.create_stack(
            TemplateBody = template,
            StackName = "thetest",
        )
    except cloudformation.exceptions.AlreadyExistsException:
        try: 
            context.stack_setup_response = cloudformation.update_stack(
                TemplateBody = template,
                StackName = "thetest",
            )
        except cloudformation.exceptions.ClientError as e:
            if "No updates are to be performed" in e.response['Error']['Message']:
                context.stack_setup_response = cloudformation.describe_stacks(
                    StackName = "thetest",
                )["Stacks"][0]
            

@when(u'I call cloudformation-stack-ls with the ARN of that stack')
def step_impl(context):
    context.stack_listing = cloudformation_stack_ls.list_stack(context.stack_setup_response['StackId'])


@then(u'all of the resources in that stack should be listed')
def step_impl(context):
    cloudformation = boto3.client("cloudformation", region_name="eu-west-1")
    cloudformation.list_stack_resources(StackName="thetest")
    resources=cloudformation.list_stack_resources(StackName="thetest")
    for i in [x["PhysicalResourceId"] for x in resources['StackResourceSummaries']]:
        assert_that(context.stack_listing, has_item(contains_string(i)))


fake_items = ["arn:s3://blahblahmichalestestingblah", "arn:aws:cloudformation:eu-west-1:165976801113:stack/thetest"]

@then(u'other resources in the account should not be listed')
def step_impl(context):
    for i in fake_items:
        assert_that(context.stack_listing,not_(has_item(i)))


@when(u'I run cloudformation-stack-ls with the ARN of my stack')
def step_impl(context):
    try:
        context.ls_result = run(["cloudformation-stack-ls", ], capture_output=True, check=True)
    except CalledProcessError as e:
        print("output:\n", e.stdout)
        print("error:\n", e.stderr)
        raise

@then(u'all of the resources in that stack should be output')
def step_impl(context):
    output=context.ls_result.stdout
    cloudformation = boto3.client("cloudformation", region_name="eu-west-1")
    resources=cloudformation.list_stack_resources(StackName="thetest")
    for i in [x["PhysicalResourceId"] for x in resources['StackResourceSummaries']]:
        assert_that(output.decode("utf-8"), contains_string(i))
    

@then(u'each ARN should be listed on a separate line.')
def step_impl(context):
    output=context.ls_result.stdout
    assert_that(output.decode("utf-8"), not_(matches_regexp("arn.*arn")))
    

