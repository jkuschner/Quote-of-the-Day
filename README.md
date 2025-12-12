## Testing the container locally

```
docker run -d -p 80:5000 \
  --name quote-demo \
  -v /root/.aws:/root/.aws:ro \
  ai-quote-service:latest
```

This `docker run` command creates a volume mount inside the container for AWS credentials. This is for local testing only.

## ECR Setup
ECR login command to authenticate Docker with ECR
```
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com
```

Tag image to tell Docker that local image, `ai-quote-service:latest` belongs to the remote ECR repository
```
docker tag ai-quote-service:latest <YOUR_ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/ai-quote-service:latest
```

Push image to cloud
```
docker push <YOUR_ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/ai-quote-service:latest
```

## EC2 Setup
Run these commands inside the EC2 instance for it to host the server.
```
sudo yum update -y
sudo yum install docker -y

sudo service docker start

# Authenticate Docker with ECR
aws ecr get-login-password --region us-west-2 | sudo docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com

sudo docker run -d -p 80:5000 <YOUR_ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/ai-quote-service:latest
```