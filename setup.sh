#!/bin/bash

####################################################################
# This script demonstrates how you can use detect / docker inspector
# running inside a docker container.
####################################################################

####################################################################
# ==> Adjust the value of hostSharedDirPath
# This path cannot have any symbolic links in it
####################################################################
hostSharedDirPath=~/blackduck/shared
imageInspectorVersion=4.5.0
gitlabRunnerJavaHome=${HOME}/java8home/jre1.8.0_221/
gitlabRunnerRegistrationToken="iJ4xjx_UwR-iP_CcMHJR"

####################################################################
# Start gitlab early since it takes a while to start up
####################################################################
docker pull store/gitlab/gitlab-ce:11.10.4-ce.0
docker run --detach --publish 443:443 --publish 80:80 --publish 2222:22 --name gitlab --restart always --volume ${HOME}/gitlab/config:/etc/gitlab --volume ${HOME}/gitlab/logs:/var/log/gitlab --volume ${HOME}/gitlab/data:/var/opt/gitlab gitlab/gitlab-ce:latest

####################################################################
# This script will start the imageinspector alpine service (if
# it's not already running).
#
# This script will leave the alpine imageinspector service running
# (and will re-use it on subsequent runs)
# For troubleshooting, you might need to do a "docker logs" on
# the imageinspector service container.
#
# To expand this to cover all linux distros, you would need two more "docker run" commands to start two more services (centos and ubuntu)
# on two other ports. All three "docker run" commands will have all 3 port numbers in them, so every service knows how to find
# every other service.
# The alpine service would then be able to redirect requests to those other services when necessary.
####################################################################

mkdir -p ${hostSharedDirPath}/target

##xxx## # Make sure the alpine service is running on host

##xxx## alpineServiceIsUp=false

##xxx## successMsgCount=$(curl http://localhost:9000/health | grep "\"status\":\"UP\"" | wc -l)
##xxx## if [ "$successMsgCount" -eq "1" ]; then
	##xxx## echo "The alpine image inspector service is up"
	##xxx## alpineServiceIsUp=true
##xxx## else
	##xxx## # Start the image inspector service for alpine on port 9000
	##xxx## docker run -d --user 1001 -p 9000:8081 --label "app=blackduck-imageinspector" --label="os=ALPINE" -v ${hostSharedDirPath}:/opt/blackduck/blackduck-imageinspector/shared --name blackduck-imageinspector-alpine blackducksoftware/blackduck-imageinspector-alpine:${imageInspectorVersion} java -jar /opt/blackduck/blackduck-imageinspector/blackduck-imageinspector.jar --server.port=8081 --current.linux.distro=alpine --inspector.url.alpine=http://localhost:9000 --inspector.url.centos=http://localhost:9001 --inspector.url.ubuntu=http://localhost:9002
##xxx## fi

##xxx## while [ "$alpineServiceIsUp" == "false" ]; do
	##xxx## successMsgCount=$(curl http://localhost:9000/health | grep "\"status\":\"UP\"" | wc -l)
	##xxx## if [ "$successMsgCount" -eq "1" ]; then
		##xxx## echo "The alpine service is up"
		##xxx## alpineServiceIsUp=true
		##xxx## break
	##xxx## fi
	##xxx## echo "The alpine service is not up yet"
	##xxx## sleep 15
##xxx## done

# Make sure the centos service is running on host

##xxx## centosServiceIsUp=false

##xxx## successMsgCount=$(curl http://localhost:9001/health | grep "\"status\":\"UP\"" | wc -l)
##xxx## if [ "$successMsgCount" -eq "1" ]; then
	##xxx## echo "The centos image inspector service is up"
	##xxx## centosServiceIsUp=true
##xxx## else
	##xxx## # Start the image inspector service for centos on port 9001
	##xxx## docker run -d --user 1001 -p 9001:8081 --label "app=blackduck-imageinspector" --label="os=CENTOS" -v ${hostSharedDirPath}:/opt/blackduck/blackduck-imageinspector/shared --name blackduck-imageinspector-centos blackducksoftware/blackduck-imageinspector-centos:${imageInspectorVersion} java -jar /opt/blackduck/blackduck-imageinspector/blackduck-imageinspector.jar --server.port=8081 --current.linux.distro=centos --inspector.url.alpine=http://localhost:9000 --inspector.url.centos=http://localhost:9001 --inspector.url.ubuntu=http://localhost:9002
##xxx## fi

##xxx## while [ "$centosServiceIsUp" == "false" ]; do
	##xxx## successMsgCount=$(curl http://localhost:9001/health | grep "\"status\":\"UP\"" | wc -l)
	##xxx## if [ "$successMsgCount" -eq "1" ]; then
		##xxx## echo "The centos service is up"
		##xxx## centosServiceIsUp=true
		##xxx## break
	##xxx## fi
	##xxx## echo "The centos service is not up yet"
	##xxx## sleep 15
##xxx## done

# Make sure the ubuntu service is running on host

ubuntuServiceIsUp=false

successMsgCount=$(curl http://localhost:9002/health | grep "\"status\":\"UP\"" | wc -l)
if [ "$successMsgCount" -eq "1" ]; then
	echo "The ubuntu image inspector service is up"
	ubuntuServiceIsUp=true
else
	# Start the image inspector service for ubuntu on port 9002
	docker run -d --user 1001 -p 9002:8081 --label "app=blackduck-imageinspector" --label="os=UBUNTU" -v ${hostSharedDirPath}:/opt/blackduck/blackduck-imageinspector/shared --name blackduck-imageinspector-ubuntu blackducksoftware/blackduck-imageinspector-ubuntu:${imageInspectorVersion} java -jar /opt/blackduck/blackduck-imageinspector/blackduck-imageinspector.jar --server.port=8081 --current.linux.distro=ubuntu --inspector.url.alpine=http://localhost:9000 --inspector.url.centos=http://localhost:9001 --inspector.url.ubuntu=http://localhost:9002
fi

while [ "$ubuntuServiceIsUp" == "false" ]; do
	successMsgCount=$(curl http://localhost:9002/health | grep "\"status\":\"UP\"" | wc -l)
	if [ "$successMsgCount" -eq "1" ]; then
		echo "The ubuntu service is up"
		ubuntuServiceIsUp=true
		break
	fi
	echo "The ubuntu service is not up yet"
	sleep 15
done

####################################################################
# Register and start GitLab CI runner
####################################################################

echo -n "Press Return/Enter after you've made sure gitlab is up (check http://localhost) > "
read discardedinput

echo "Registering GitLab CI runner"
docker run --rm -t -i --network="host" -v ${gitlabRunnerJavaHome}:/javahome -v ${HOME}/gitlab-runner/config:/etc/gitlab-runner gitlab/gitlab-runner register --non-interactive --executor shell --url http://localhost --registration-token "${gitlabRunnerRegistrationToken}" --description "java runner" --run-untagged=true

sleep 5

echo "Starting GitLab CI runner"
docker run -d --network="host" --name gitlab-runner --restart always -v ${gitlabRunnerJavaHome}:/javahome -v ${hostSharedDirPath}:/shared -v ${HOME}/gitlab-runner/config:/etc/gitlab-runner gitlab/gitlab-runner --debug run

# For testing: Save some docker images in the shared dir
# (Doing it from host since this detect container does not have docker)
docker save -o ${hostSharedDirPath}/target/alpine.tar alpine:latest
chmod a+r ${hostSharedDirPath}/target/alpine.tar
docker save -o ${hostSharedDirPath}/target/centos.tar centos:latest
chmod a+r ${hostSharedDirPath}/target/centos.tar
docker save -o ${hostSharedDirPath}/target/ubuntu.tar ubuntu:latest
chmod a+r ${hostSharedDirPath}/target/ubuntu.tar

echo "TBD describe what needs to be in .gitlab-ci.yml file here..."
