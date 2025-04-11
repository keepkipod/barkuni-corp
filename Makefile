all: install-dependencies

install-dependencies: install-taskfile install-kind

install-taskfile:
	@command -v task > /dev/null 2>&1 && echo "Task is already installed, ignoring." || (echo "Installing Task..." && curl --location https://taskfile.dev/install.sh -o install_task.sh && (if [ -w /usr/local/bin ]; then sh install_task.sh -d -b /usr/local/bin; else sudo sh install_task.sh -d -b /usr/local/bin; fi) && rm install_task.sh)

install-kind:
	@command -v kind > /dev/null 2>&1 && echo "Kind is already installed, ignoring." || (echo "Installing Kind..." && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-darwin-arm64 && (if [ -w /usr/local/bin ]; then chmod +x ./kind && mv ./kind /usr/local/bin/kind; else sudo chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind; fi))

.PHONY: all install-dependencies install-taskfile install-kind