kops_module := "github.com/dictybase-docker/dagger-of-dcr/kops@main"
bin_path := `mktemp -d`
action_bin := bin_path + "/actions"
dagger_bin := bin_path + "/dagger"
kubectl_file := `mktemp -d` + "/dictycr.yaml"
gha_download_url := "https://github.com/dictybase-docker/github-actions/releases/download/v2.9.1/action_2.9.1_linux_amd64"
set dotenv-filename := ".deploy.development"

setup: install-gha-binary install-dagger-binary
[group('setup-tools')]
install-gha-binary:
	curl -L -o {{action_bin}} {{gha_download_url}}
	chmod +x {{action_bin}} 
[group('setup-tools')]
install-dagger-binary:
	{{action_bin}} sd --dagger-version $DAGGER_VERSION --dagger-bin-dir {{bin_path}}


export-kubectl cluster cluster-state gcp-credentials:
	#!/usr/bin/env bash
	set -euxo pipefail
        dagger call -m {{kops_module}} with-kops with-kubectl \
		with-cluster --name={{cluster}} \ 
		with-state-storage --storage={{cluster-state}} \
		with-credentials --credentials={{gcp-credentials}} \
		export-kubectl --output={{kubectl_file}}
