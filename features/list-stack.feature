Feature: list contents of a cloudformation stack
In order to be able to identify which resources belong to a particular
stack, Michael as an account administrator would like to be able to
list the ARNs all of the resources created by a cloudformation stack

  Scenario: list the ARNs of an existing stack
  given that I have access to an account which has non-cloud formation resources
  and that I have a stack in cloudformation with resources created
  when I call cloudformation-stack-ls with the ARN of that stack
  then all of the resources in that stack should be listed
  and other resources in the account should not be listed 