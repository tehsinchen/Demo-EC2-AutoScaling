PROFILE ?= default

init:
	terraform init -backend-config=backend.conf
plan: fmt
	terraform plan
apply: fmt
	terraform apply
	rm -rf *.zip
destroy:
	terraform destroy
	rm -rf *.zip
fmt:
	terraform fmt -recursive ../../
login:
	aws sso login --profile ${PROFILE}
