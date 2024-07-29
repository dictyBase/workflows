dagger_version := "v0.11.9"
kops_module := "github.com/dictybase-docker/dagger-of-dcr/kops@main"
gh_deployment_module := "github.com/dictybase-docker/dagger-of-dcr/gh-deployment@develop"
bin_path := `mktemp -d`
action_bin := bin_path + "/actions"
dagger_bin := bin_path + "/dagger"
kubectl_file := `mktemp -d` + "/dictycr.yaml"

base_gha_download_url := "https://github.com/dictybase-docker/github-actions/releases/download/v2.10.0/action_2.10.0_"
gha_download_url := if os() == "macos" {
    base_gha_download_url + "darwin_arm64"
} else {
    base_gha_download_url + "linux_amd64"
}

file_suffix := ".tar.gz"
dagger_file := if os() == "macos" {
    "darwin_arm64" + file_suffix
} else {
    "linux_amd64" + file_suffix
}
set dotenv-filename := ".deploy.development"

system-info:
    @echo this is an {{arch()}} os {{os()}}

setup: install-gha-binary install-dagger-binary
[group('setup-tools')]
install-gha-binary:
	@curl -L -o {{action_bin}} {{gha_download_url}}
	@chmod +x {{action_bin}} 
[group('setup-tools')]
install-dagger-binary:
	{{action_bin}} sd --dagger-version {{dagger_version}} --dagger-bin-dir {{bin_path}} --dagger-file {{dagger_file}}

export-kubectl cluster cluster-state gcp-credentials-file: setup
    #!/usr/bin/env bash
    set -euxo pipefail
    {{dagger_bin}} call -m {{kops_module}} \
    with-kops with-kubectl \
    with-state-storage --storage={{cluster-state}} \
    with-credentials --credentials={{gcp-credentials-file}} \
    with-cluster --name={{cluster}} \
    export-kubectl --output={{kubectl_file}}

deploy cluster cluster-state gcp-credentials-file ref user pass token: 
    #!/usr/bin/env bash
    set -euxo pipefail
    just export-kubectl {{cluster}} {{cluster-state}} {{gcp-credentials-file}}
    deployment_id=`{{dagger_bin}} call -m {{gh_deployment_module}} \ 
        with-application --application=$APP \
        with-docker-image --docker-image=$DOCKER_IMAGE \
        with-docker-namespace --docker-namespace=$DOCKER_NAMESPACE \
        with-dockerfile --dockerfile=$DOCKERFILE \
        with-project --project=$PROJECT \ 
        with-stack --stack=$STACK \
        with-environment --environmant=$ENVIRONMENT \
        with-repository --repository=$REPOSITORY \
        with-ref --ref={{ref}} \
        create-github-deployment --token={{token}}`
    {{dagger_bin}} call -m {{gh_deployment_module}} \
        with-repository --repository=$REPOSITORY \
        set-deployment-status --token={{token}} \
        deployment_id=$deployment_id \
        status="in_progress"
    {{dagger_bin}} call -m {{gh_deployment_module}} \
        with-repository --repository=$REPOSITORY \
        set-deployment-status --token={{token}} \
        deployment_id=$deployment_id \
        status="queued"
     {{dagger_bin}} call -m {{gh_deployment_module}} \
        with-repository --repository=$REPOSITORY \
        set-deployment-status --token={{token}} \
        deployment_id=$deployment_id \
        status="success"

