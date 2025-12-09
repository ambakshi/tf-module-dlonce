.PHONY: test init validate lint clean fmt

# Initialize terraform
init:
	cd tests && terraform init

# Format terraform files
fmt:
	terraform fmt -recursive

# Validate terraform configuration
validate: init
	terraform validate
	cd tests && terraform validate

# Run tflint
lint: init
	tflint --recursive

# Run tests (apply the test configuration)
test: init
	cd tests && terraform apply -auto-approve
	@echo "Verifying downloaded file exists..."
	@ls -la tests/downloads/
	@echo "Test passed!"

# Clean up test artifacts
clean:
	rm -rf tests/downloads
	rm -rf tests/.terraform
	rm -f tests/.terraform.lock.hcl
	rm -f tests/terraform.tfstate*

# Full test cycle
all: fmt validate lint test
