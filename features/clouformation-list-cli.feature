Feature: cli to list contents of a cloudformation stack as an ARN per line

In order to be able to cooperate with the output of other resource
listing tools Michael as an account administrator would like a cli to
list the ARNs all of the resources created by a cloudformation stack
with one ARN listed per line.

  @wip
  Scenario: list the ARNs of an existing stack
  given that I have access to an account which has non-cloud formation resources
  and that I have a stack in cloudformation with resources created
  when I run cloudformation-stack-ls with the ARN of my stack
  then all of the resources in that stack should be output
  and each ARN should be listed on a separate line.