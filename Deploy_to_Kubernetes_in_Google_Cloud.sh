# Config

gcloud config set compute/zone us-east1-b

read -p "Type project id: " PROJECT
export PROJECT

read -p "Type replicas count: " REPLICAS_COUNT
export REPLICAS_COUNT


# Task 1

source <(gsutil cat gs://cloud-training/gsp318/marking/setup_marking_v2.sh)
cd ~/

gcloud source repos clone valkyrie-app --project=$PROJECT
cd valkyrie-app

cat > Dockerfile <<EOF 
FROM golang:1.10
WORKDIR /go/src/app
COPY source .
RUN go install -v
ENTRYPOINT ["app","-single=true","-port=8080"]
EOF

docker build -t valkyrie-dev:v0.0.1 .

bash ~/marking/step1_v2.sh

 
# Task 2

docker run -p 8080:8080 --name valkyrie-dev valkyrie-dev:v0.0.1 &
bash ~/marking/step2_v2.sh


# Task 3

docker tag valkyrie-dev:v0.0.1 gcr.io/$PROJECT/valkyrie-dev:v0.0.1
docker push gcr.io/$PROJECT/valkyrie-dev:v0.0.1


# Task 4

cd ~/valkyrie-app/k8s

gcloud container clusters get-credentials valkyrie-dev --region us-east1-d

nano deployment.yaml
#change IMAGE_HERE to gcr.io/$PROJECT/valkyrie-dev:v0.0.2
#change IMAGE_HERE to gcr.io/qwiklabs-gcp-02-25aebce59e6a/valkyrie-dev:v0.0.2

kubectl create -f deployment.yaml
kubectl create -f service.yaml


# Task 5

kubectl scale deployment valkyrie-dev --replicas=$REPLICAS_COUNT

cd ~/valkyrie-app
git merge origin/kurt-dev

docker build -t valkyrie-dev:v0.0.2 .
docker tag valkyrie-dev:v0.0.2 gcr.io/$PROJECT/valkyrie-dev:v0.0.2
docker push gcr.io/$PROJECT/valkyrie-dev:v0.0.2

#kubectl edit deployment valkyrie-dev

kubectl set image deployment valkyrie-dev \
	backend=gcr.io/$PROJECT/valkyrie-dev:v0.0.2 \
	frontend=gcr.io/$PROJECT/valkyrie-dev:v0.0.2


# Task 6

printf $(kubectl get secret cd-jenkins -o jsonpath="{.data.jenkins-admin-password}" \
	| base64 --decode);echo
	
docker ps
docker container stop CONTAINER_NAME

export POD_NAME=$(kubectl get pods --namespace default -l \
	"app.kubernetes.io/component=jenkins-master" -l \
	"app.kubernetes.io/instance=cd" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 8080:8080 >> /dev/null &


# login to jenkins (user: admin, password from console)

nano Jenkinsfile )add project id)
nano html.go (change green to orange)

git config --global user.email $PROJECT
git config --global user.name $PROJECT

git add Jenkinsfile source/html.go
git commit -m "added project id to Jenkinsfile, changed green to orange color"
git push origin master




