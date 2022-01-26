VERSION=$(shell cat VERSION)
REGISTRY_NAME=valentinb10
IMAGE_NAME=csi-rclone
IMAGE_TAG=$(REGISTRY_NAME)/$(IMAGE_NAME):$(VERSION)

.ONESHELL:

.PHONY: all image helm

all: image

image:
	docker build -t $(IMAGE_TAG) .
	docker push $(IMAGE_TAG)

helm:
	cd charts
	helm package csi-rclone
	helm repo index --url http://tech.weatherforce.org/csi-rclone/charts .