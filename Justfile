action_bin_path := "/tmp/github_actions/bin"
dagger_path := "/tmp/dag/bin"
gha_download_url := "https://github.com/dictybase-docker/github-actions/releases/download/v2.9.1/action_2.9.1_linux_amd64"
set dotenv-filename := ".deploy.development"

set-dagger-path:
	echo {{dagger_path}} >> $GITHUB_PATH
set-gha-path:
	echo {{action_bin_path}} >> $GITHUB_PATH
create-bin-paths:
	mkdir -p {{action_bin_path}} {{dagger_path}}
manage-paths: create-bin-paths set-gha-path set-dagger-path

install-gha-binary:
          curl -L -o {{action_bin_path}} + "/actions" {{gha_download_url}}
          chmod +x {{action_bin_path}} + "/actions"

install-dagger-binary:
	actions sd --dagger-version $DAGGER_VERSION --dagger-bin-dir {{dagger_path}}
