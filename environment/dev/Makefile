PROFILE ?= default

init:
	terraform init -backend-config=backend.conf
plan: fmt
	terraform plan
apply: fmt
	terraform apply
destroy:
	terraform destroy
fmt:
	terraform fmt -recursive ../../
login:
	aws sso login --profile ${PROFILE}
