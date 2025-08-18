# echo "k3d image import $*-app:la
test --cluster mycluster"
build-%:
	@echo "Building $*-app"
	docker build -t $*-app $*-app/
	kind load docker-image $*-app:latest --name mycluster
