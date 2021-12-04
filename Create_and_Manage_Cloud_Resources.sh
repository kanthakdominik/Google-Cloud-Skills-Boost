# Task 1

gcloud config set compute/zone us-east1-b
gcloud config set compute/region us-east1

gcloud compute instances create [INSTANCE_NAME] --machine-type f1-micro 


# Task 2

gcloud container clusters create nucleus-server
gcloud container clusters get-credentials nucleus-server

kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:2.0
kubectl expose deployment hello-server --type=LoadBalancer --port [PORT_NUMBER]

kubectl get service


# Task 3

cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF


# Instance template:

gcloud compute instance-templates create nginx-template \
   --region=us-east1 \
   --tags=allow-health-check \
   --image-family=debian-10 \
   --image-project=debian-cloud \
   --metadata-from-file startup-script=startup.sh


# Target pool:

gcloud compute target-pools create nginx-pool


# Managed instance group:

gcloud compute instance-groups managed create nginx-group \
   --size=2 \
   --base-instance-name nginx \
   --template=nginx-template \
   --zone=us-east1-b  \
   --target-pool nginx-pool


# Firewall rule:

gcloud compute firewall-rules create [RULE_NAME] \
    --allow tcp:80


gcloud compute forwarding-rules create nginx-fr \
   --ports=80 \
   --target-pool nginx-pool


# Health check:

gcloud compute http-health-checks create http-basic-check

gcloud compute instance-groups managed \
   set-named-ports nginx-group \
   --named-ports http:80


# Backend service & attach the managed instance group:

gcloud compute backend-services create nginx-backend-service \
    --protocol=HTTP \
    --port-name=http \
    --http-health-checks=http-basic-check \
    --global

gcloud compute backend-services add-backend nginx-backend-service \
    --instance-group=nginx-group \
    --global


# URL map & HTTP proxy: 

gcloud compute url-maps create web-map-http \
    --default-service nginx-backend-service

gcloud compute target-http-proxies create http-proxy \
    --url-map web-map-http


# Forwarding rule & ipv4 address:

gcloud compute addresses create ipv4-address-1 \
    --ip-version=IPV4 \
    --global

gcloud compute forwarding-rules create http-content-rule \
    --address=ipv4-address-1\
    --global \
    --target-http-proxy=http-proxy \
    --ports=80


# please wait for a few minutes before checking Task 3