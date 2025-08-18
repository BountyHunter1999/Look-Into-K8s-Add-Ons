create-%:
	helm create $(@)

build-%:
	@echo "Building $*-app"
	docker build -t $*-app $*-app/
	k3d image import $*-app:latest --cluster mycluster

deploy-%:
	helm upgrade --install $*-app ./create-$*/ --namespace $*-app --create-namespace
	@echo "-----------------------------------------------------------------------------------------------"
	kubectl port-forward svc/$*-app-create-$* 3000:3000 -n $*-app