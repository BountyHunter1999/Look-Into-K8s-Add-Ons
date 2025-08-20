# echo "k3d image import $*-app:la
# test --cluster mycluster"
build-%:
	@echo "Building $*-app"
	docker build -t $*-app $*-app/
	k3d image import $*-app:latest --cluster mycluster  ||   kind load docker-image $*-app:latest --name nice-cluster