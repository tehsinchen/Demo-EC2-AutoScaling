PROFILE ?= default

init:
	packer init .
build: fmt
	packer build .
plan: fmt
	packer validate .
fmt:
	packer fmt .
login:
	aws sso login --profile ${PROFILE}
