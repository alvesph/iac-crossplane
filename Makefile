include ./.env

add_repo:
	helm repo add crossplane-stable https://charts.crossplane.io/stable

update_repo:
	helm repo update

install_crossplane: add_repo update_repo
	helm upgrade --install crossplane --namespace crossplane-system --create-namespace crossplane-stable/crossplane 

install_provider_s3:
	kubectl apply -f 0-crossplane/1-provider-aws-s3.yaml

install_secret:
	kubectl create secret generic aws-secret \
	-n crossplane-system \
	--from-file=creds=./aws-credentials.txt

install_aws_config:
	kubectl apply -f 0-crossplane/0-provider-aws-config.yaml

install_aws_s3:
	kubectl apply -f 1-s3/0-bucket.yaml

deploy:
	- helm upgrade --install --namespace argocd infra-crossplane ./application/infra-helm \
		--values ./application/infra-helm/values.yaml \
		--set destination.server='$(SERVER_DEV)' \
		--set source.path=./infra-helm \
		--set source.repoURL='$(SOURCE_REPOURL)' \
		--set project=services \
		--set secrets.data.creds="'[default]\naws_access_key_id = \naws_secret_access_key = '"