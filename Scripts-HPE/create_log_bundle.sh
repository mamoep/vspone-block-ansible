#!/bin/bash

if [ "$#" -ne 3 ]; then
	echo "Usage: ./create_log_bundle.sh ip user password"
	exit 1
fi

vro_ip=$1
vro_user=$2
vro_password=$3

SUPPORT_FOLDER="/opt/hpe/vro/support"

#log and configuration folders:
BASE_LOG_FOLDER="/var/log"
HPE_LOG_FOLDER="hpe/ansible"
BASE_CONFIGURATION_FOLDER="/opt/hpe/ansible"


DATE=`date '+%m%d%Y_%H%M'`

adapter_version="02.0.0"
LOG_BUNDLE_NAME="hpe_storage_ansible_"
LOG_BUNDLE_NAME+=$adapter_version
LOG_BUNDLE_NAME+="_log_bundle_"
LOG_BUNDLE_NAME+=$DATE
echo "LOG_BUNDLE_NAME is $LOG_BUNDLE_NAME"

mkdir -p $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/vro_service/
mkdir -p $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/vi_service/
mkdir -p $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/puma/
mkdir -p $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/configuration/vi_service/
mkdir -p $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/configuration/vro_service/

# copy the logs
cp -f -a $BASE_LOG_FOLDER/$HPE_LOG_FOLDER/vroservice*.*  $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/vro_service/
cp -f -a $BASE_LOG_FOLDER/$HPE_LOG_FOLDER/vi_service/Hitachi-VI-ServiceLog*  $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/vi_service/
cp -f -a $BASE_LOG_FOLDER/puma.log $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/puma/

#copy the configuration files:

#copy config from vi-service:
cp -f -a $BASE_CONFIGURATION_FOLDER/vi_service/VIService-ApacheLicense/*.xml  $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/configuration/vi_service/
cp -f -a $BASE_CONFIGURATION_FOLDER/vi_service/VIService-ApacheLicense/*.config  $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/configuration/vi_service/
#copy config from vro-service:
cp -f -a $BASE_CONFIGURATION_FOLDER/vro_service/*.json  $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/configuration/vro_service/
cp -f -a $BASE_CONFIGURATION_FOLDER/vro_service/*.config  $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/configuration/vro_service/
cp -f -a $BASE_CONFIGURATION_FOLDER/vro_service/Configuration  $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/configuration/vro_service/


sshpass_installed=true
# check if sshpass package is installed on the system
if ! rpm -qa | grep -qw sshpass; then
	sshpass_installed=false
fi

if [ "$sshpass_installed" = false ] ; then
	echo "Would you like to install 'sshpass' package? It is needed to ssh into vRO appliance for collecting logs. If you select 'n', we will not collect any logs from vRO appliance."
	echo -n "Please type 'y' or 'n' > "
	read user_input
	if [ $user_input = 'y' ] || [ $user_input = 'Y' ] ; then
		yum install -y sshpass
		sshpass_installed=true
	else
		echo "Skip collecting vRO appliance logs and create the bundle containing vRO Connector logs."	
	fi
fi

if [ "$sshpass_installed" = true ] ; then
	echo "Getting vRO Appliance logs."
	
	mkdir -p $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/vro_plugin/
	mkdir -p $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/vro_appliance_service/
										
	#copy the vro_plugin files:
	cd $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/vro_plugin/
	sshpass -p $vro_password scp -o StrictHostKeyChecking=no $vro_user@$vro_ip:/var/log/vmware/vco/app-server/HiStorageWebService.log .
	cd $SUPPORT_FOLDER/$LOG_BUNDLE_NAME/vro_appliance_service/
	sshpass -p $vro_password scp -o StrictHostKeyChecking=no $vro_user@$vro_ip:/var/log/vmware/vco/app-server/integration* .
fi


cd $SUPPORT_FOLDER/
tar czvf ./$LOG_BUNDLE_NAME.tar.gz $LOG_BUNDLE_NAME

#remove the temporary directory:
#echo "!path! = $SUPPORT_FOLDER/$LOG_BUNDLE_NAME"
rm -fr $SUPPORT_FOLDER/$LOG_BUNDLE_NAME

echo "Create_log_bundle script ended succesfully."