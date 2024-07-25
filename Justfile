action_bin_path := "/tmp/github_actions/bin"
dagger_path := "/tmp/dag/bin"
gha_download_url := "https://github.com/dictybase-docker/github-actions/releases/download/v2.9.1/action_2.9.1_linux_amd64"
set dotenv-filename := ".deploy.development"

setup-dagger: manage-paths install-gha-binary install-dagger-binary
[group('setup-dagger')]
manage-paths: 
	@mkdir -p {{action_bin_path}} {{dagger_path}}
	@echo {{dagger_path}} >> $GITHUB_PATH
	@echo {{action_bin_path}} >> $GITHUB_PATH
[group('setup-dagger')]
install-gha-binary:
          curl -L -o {{action_bin_path}} + "/actions" {{gha_download_url}}
          chmod +x {{action_bin_path}} + "/actions"
[group('setup-dagger')]
install-dagger-binary:
	actions sd --dagger-version $DAGGER_VERSION --dagger-bin-dir {{dagger_path}}
