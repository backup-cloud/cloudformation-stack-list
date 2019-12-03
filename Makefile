AWS_ACCOUNT_NAME ?= michael
AWS_DEFAULT_REGION ?= us-east-2
PYTHON ?= python3
BEHAVE ?= behave
KEYFILE ?=.anslk_random_testkey
LIBDIR ?= cloudformation_stack_ls

export AWS_DEFAULT_REGION

# these variables cannot be immediate since running the prepare target
# may change the values.
ifneq ($(wildcard $(KEYFILE)),)
  RANDOM_KEY = $(shell cat $(KEYFILE))
endif
S3_TEST_BUCKET = test-backup-$(RANDOM_KEY)
export RANDOM_KEY
export S3_TEST_BUCKET


LIBFILES := $(shell find $(LIBDIR) -name '*.py')

# we want to automate all the setup but we don't want to do it by surprise so we default
# to aborting with a message to correct things
abort:
	@echo "***************************************************************************"
	@echo "* please run 'make all' to install library and programs locally then test *"
	@echo "***************************************************************************"
	@echo
	exit 2

all: develop prepare lint build test

test: develop build pytest behave doctest

behave: develop
	$(BEHAVE) --tags=-future

# develop is needed to install scripts that are called during testing 
develop: .develop.makestamp

.develop.makestamp: setup.py $(LIBDIR)/shell_start.py $(LIBFILES)
	$(PYTHON) setup.py install --force
	$(PYTHON) setup.py develop
	touch $@

checkvars:
	if [ '!' -f $${KEYFILE} ] ; then \
		echo "file: $(KEYFILE) missing - run make prepare first" ; exit 5 ; fi
	if [ -z $${RANDOM_KEY} ] ; then \
		echo 'no RANDOM_KEY found - N.B. be sure you are using a recent gmake!!! run *make prepare* to build test environment.'  ; exit 5 ; fi

pytest:
	$(PYTHON) -m pytest -vv tests

doctest:
	$(PYTHON) -m doctest -v README.md

pip_install:
	$(PYTHON) -m pip install -r requirements.txt

prepare: encrypted_build_files.tjz.enc

ENC_DIR=encrypted_build_files
ENC_FILENAMES=aws_credentials.demo.env aws_credentials.env aws_credentials_travis.yml deploy_key
ENC_FILES := $(addprefix $(ENC_DIR)/,$(ENC_FILENAMES))

encrypted_build_files.tjz: .prepare-account.makestamp .prepare-test.makestamp $(ENC_FILES)
	tar cvvjf $@ -C $(ENC_DIR) $(ENC_FILENAMES)

encrypted_build_files.tjz.enc: encrypted_build_files.tjz
	travis encrypt-file --force --no-interactive --org $<

prepare-account: .prepare-account.makestamp

.prepare-account.makestamp: prepare-account.yml $(wildcard aws_credentials_*_iam_admin.yml)  $(wildcard roles/test_account/*/*.yml) 
	ansible-playbook -vvv prepare-account.yml --extra-vars=aws_account_name=$(AWS_ACCOUNT_NAME)
	touch $@

prep_test: .prepare-test.makestamp

.prepare-test.makestamp:
	ansible-playbook -vvv prepare-test-enc-backup.yml --extra-vars=aws_account_name=$(AWS_ACCOUNT_NAME)
	touch $@

wip: develop
	$(BEHAVE) --wip


build:

lint:
	pre-commit install --install-hooks
	pre-commit run -a

testfix:
	find . -name '*.py' | xargs black --line-length=100 --diff

clean:
	rm *.makestamp

fix:
	find . -name '*.py' | xargs black --line-length=100 
.PHONY: all develop test behave behave-aws behave-mocked checkvars pytest doctest pip_install prepare prep_test prepare_account wip wip-aws wip-mocked build lint testfix fix clean
