.PHONY: encrypt decrypt

# Usage: make encrypt orgName=<org-name> projectName=<project-name> input=<input-path> [secret=<secret-name>]
# Example: make encrypt orgName=my-org projectName=my-project input=./my-secret.env
encrypt:
	@if [ -z "$(orgName)" ] || [ -z "$(projectName)" ] || [ -z "$(input)" ]; then \
		echo "Error: Missing required arguments." >&2; \
		echo "Usage: make encrypt orgName=<org-name> projectName=<project-name> input=<input-path> [name=<secret-name>]"; \
		echo "" ; \
		echo "Arguments:"; \
		echo "  org-name: The organization name, used as the namespace."; \
		echo "  project-name: The project name."; \
		echo "  input-path: Path to a file or directory to create the secret from."; \
		echo "              If a directory, creates a secret with --from-file."; \
		echo "              If a file, creates a secret with --from-env-file."; \
		echo "  secret-name: (Optional) The name of the secret."; \
		echo "               Defaults to <org-name>-<project-name>-config if input-path is a directory."; \
		echo "               Defaults to <org-name>-<project-name>-env if input-path is a file."; \
		exit 1; \
	fi
	@if [ ! -e "$(input)" ]; then echo "Error: input path '$(input)' not found." >&2; exit 1; fi

	@# Define variables
	$(eval NAMESPACE := $(orgName))
	$(eval INPUT_PATH := $(input))
	$(eval SECRET_NAME := $(if $(name),$(name),$(shell if [ -d "$(INPUT_PATH)" ]; then echo "$(orgName)-$(projectName)-config"; elif [ -f "$(INPUT_PATH)" ]; then echo "$(orgName)-$(projectName)-env"; fi)))

	@# Validate SECRET_NAME (in case input path was invalid)
	@if [ -z "$(SECRET_NAME)" ]; then echo "Error: input-path '$(INPUT_PATH)' is not a valid file or directory" >&2; exit 1; fi

	@# Get SOPS public key
	$(eval PUB_KEY := $(shell kubectl exec --kubeconfig /export/kubeconfig.yaml \
		deploy/sops-sops-secrets-operator -n sops -- \
		sh -c 'cat $$SOPS_AGE_KEY_FILE' \
		| head -n 2 | tail -n 1 | awk '{ print $$4 }'))
	@if [ -z "$(PUB_KEY)" ]; then echo "Error: Failed to retrieve SOPS public key." >&2; exit 1; fi

	@# Create temporary files
	$(eval SECRET_FILE := $(shell mktemp --suffix=.yaml))
	$(eval SOPS_FILE := $(shell mktemp --suffix=.yaml))
	$(eval ENC_FILE := $(shell mktemp --suffix=.yaml))

	@# Generate the base secret
	@if [ -d "$(INPUT_PATH)" ]; then \
		kubectl create secret generic -n "$(NAMESPACE)" "$(SECRET_NAME)" --from-file="$(INPUT_PATH)" --dry-run=client -o yaml > $(SECRET_FILE); \
	else \
		kubectl create secret generic -n "$(NAMESPACE)" "$(SECRET_NAME)" --from-env-file="$(INPUT_PATH)" --dry-run=client -o yaml > $(SECRET_FILE); \
	fi

	@# Transform to SopsSecret
	@yq eval '.kind = "SopsSecret" | .apiVersion = "isindir.github.com/v1alpha3" | .spec.secretTemplates[0].name = .metadata.name | .spec.secretTemplates[0].stringData = (.data | map_values(@base64d)) | del(.data)' "$(SECRET_FILE)" > "$(SOPS_FILE)"

	@# Encrypt with sops
	@sops --encrypt --age "$(PUB_KEY)" --encrypted-regex '^(data|stringData)$$' "$(SOPS_FILE)" > "$(ENC_FILE)"

	@# Output the result and clean up
	@cat "$(ENC_FILE)"
	@rm -f "$(SECRET_FILE)" "$(SOPS_FILE)" "$(ENC_FILE)"

.PHONY: decrypt
# Usage: make decrypt input=<encrypted-file>
# Example: make decrypt input=out.yaml
decrypt:
	@if [ -z "$(input)" ]; then \
		echo "Error: Missing required arguments." >&2; \
		echo "Usage: make decrypt input=<input-path> "; \
		echo "" ; \
		echo "Arguments:"; \
		echo "  input-path: Path to encrypted SopsSecret file to decrypt."; \
		exit 1; \
	fi
	@if [ ! -f "$(input)" ]; then echo "Error: File '$(input)' not found" >&2; exit 1; fi

	@# Get SOPS private key
	$(eval SECRET_KEY := $(shell kubectl exec --kubeconfig /export/kubeconfig.yaml \
		deploy/sops-sops-secrets-operator -n sops -- \
		sh -c 'cat $$SOPS_AGE_KEY_FILE' \
		| tail -n 1))
	@if [ -z "$(SECRET_KEY)" ]; then echo "Error: Failed to retrieve AGE secret key." >&2; exit 1; fi

	@# Decrypt the file
	@SOPS_AGE_KEY="$(SECRET_KEY)" sops --decrypt "$(input)"
