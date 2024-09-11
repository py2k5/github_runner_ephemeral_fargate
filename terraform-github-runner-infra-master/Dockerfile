FROM python:3.9

WORKDIR /app

RUN apt-get update && apt-get install -y zip

CMD cd /app/package && zip -r ../deployment_package.zip .

