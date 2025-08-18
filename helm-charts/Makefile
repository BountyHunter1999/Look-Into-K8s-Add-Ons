create-%:
	helm create $(@)

deploy-%:
	helm upgrade --install $*-app ./create-$*/ --namespace $*-app --create-namespace
	@echo "-----------------------------------------------------------------------------------------------"
	kubectl port-forward svc/$*-app-create-$* 3000:3000 -n $*-app