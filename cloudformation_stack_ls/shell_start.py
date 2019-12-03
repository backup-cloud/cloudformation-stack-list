import cloudformation_stack_ls

def main():
    for i in cloudformation_stack_ls.list_stack("arn:aws:cloudformation:eu-west-1:FAKEACCOUNT:stack/thetest/123"):
        print(i)
