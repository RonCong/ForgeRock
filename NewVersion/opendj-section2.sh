#! /bin/bash
source opendj.properities
source deploymentkey

echo "Setting up DS, Press ANY key to Continue"
read -n 1 key
if [ "$key" == "" ]; then
	if [ -d "$home/opendj" ]; then	#if the opendj file has been unzipped, we can find it at root directory
		sudo cp -R "$home/opendj/." "$ds"
		if [ -d "$ds/bin" ]; then
                	echo "Create successful"
                else
                        exit 1
		fi
		sudo rm -r $home/opendj
	else
		for file in $home; do
       			if [[ $file=="DS-7"* ]] && [[ $file==*".zip" ]];then
               			sudo unzip $home/DS-7*.zip -d $home
				sudo cp -R "$home/opendj/." "$ds"
				sudo rm -r $home/opendj
				if [ -d "$ds/bin" ]; then
					echo "Create successful"
				else
					exit 1
				fi
       			else
	               		echo "No ForgeRock DS file exists, Pls download"
               		exit 1
       			fi
		done
	fi
else
	exit 1
fi

<<'COMMENT'
sudo mkdir $home/$dsname
sudo chown -R rong_cong:rong_cong $home/$dsname
sudo chmod -R 744 $home/$dsname
cd $ds/bin
deployID=$(./dskeymgr create-deployment-id --deploymentIdPassword password)
echo "The Deployment ID is $deployID"
echo "DEPLOYMENT_ID=$deployID" > /opt/script/deploymentkey

if [ -f "$home/$ds/setup" ]; then
	echo "start setup"
	# Execute the .sh file
$ds/setup --acceptLicense \
 --instancePath $home/$dsname \
 --serverId evaluation-only \
 --deploymentId $DEPLOYMENT_ID \ 
 --deploymentIdPassword password \
 --rootUserDN cn="Directory Manager" \
 --rootUserPassword password \
 --monitorUserDn uid=monitor \
 --monitorUserPassword password \
 --hostname localhost \
 --adminConnectorPort 5555 \
 --ldapPort 1389 \
 --enableStartTls \
 --ldapsPort 1636 \
 --httpsPort 9443 \
 --replicationPort 8989 \
 --bootstrapReplicationServer localhost:8989 \
 --profile ds-evaluation \
 --start \
echo "DS set up successfully."
else
	echo "Error：/$ds/setup does not exist."
	exit 1
	
fi

echo "Creating backend database."

cd $home$ds/bin/
bash dsconfig \
create-backend \
 --trustAll \
 --hostname localhost \
 --port 5555 \
 --bindDn cn="Directory Manager" \
 --bindPassword password \
 --backend-name userRoot \
 --type je \
 --set base-dn:c=us,dc=example,dc=com \
 --set enabled:true \
 --set db-directory:$home/$db \
 --no-prompt 



echo "Creating backend index."
bash dsconfig \
create-backend-index \
 --et-global-configuration-prop \
 --set je-backend-shared-cache-enabled:false \
 --hostname localhost \
 --port 5555 \
 --bindDn cn=Directory\ Manager \
 --bindPassword ****** \
 --trustAll \
 --no-promptrustALL \
 --hostname localhost \
 --port 5555 \
 --bindDN cn=Directory\ Manager \
 --bindPassword password \
 --backend-name userRoot \
 --index-name cn \
 --set index-type:equality \
 --type generic \
 --no-prompt

bash dsconfig \
create-backend-index \
 --trustALL \
 --hostname localhost \
 --port 5555 \
 --bindDN cn=Directory\ Manager \
 --bindPassword password \
 --backend-name userRoot \
 --index-name pwdaccountlockedtime \
 --set index-type:presence \
 --type generic \
 --no-prompt

bash dsconfig \
create-backend-index \
 --trustALL \
 --hostname localhost \
 --port 5555 \
 --bindDN cn=Directory\ Manager \
 --bindPassword password \
 --backend-name userRoot \
 --index-name pwdfailuretime \
 --set index-type:presence \
 --type generic \
 --no-prompt

bash dsconfig \
create-backend-index \
 --trustALL \
 --hostname localhost \
 --port 5555 \
 --bindDN cn=Directory\ Manager \
 --bindPassword password \
 --backend-name userRoot \
 --index-name pwdgraceusetime \
 --set index-type:presence \
 --type generic \
 --no-prompt

bash dsconfig \
create-backend-index \
 --trustALL \
 --hostname localhost \
 --port 5555 \
 --bindDN cn=Directory\ Manager \
 --bindPassword password \
 --backend-name userRoot \
 --index-name uid \
 --set index-type:equality \
 --set index-type:substring \
 --set index-entry-limit:50000 \
 --type generic \
 --no-prompt

bash dsconfig \
create-backend-index \
 --trustALL \
 --hostname localhost \
 --port 5555 \
 --bindDN cn=Directory\ Manager \
 --bindPassword password \
 --backend-name userRoot \
 --index-name uniquemember \
 --set index-type:equality \
 --type generic \
 --no-prompt

bash dsconfig \
create-backend-index \
 --trustALL \
 --hostname localhost \
 --port 5555 \
 --bindDN cn=Directory\ Manager \
 --bindPassword password \
 --backend-name userRoot \
 --index-name member \
 --set index-type:equality \
 --type generic \
 --no-prompt

 bash rebuild-index \
 --hostname localhost \
 --port 5555 \
 --bindDN cn=Directory\ Manager \
 --bindPassword password \
 --baseDN c=us,dc=example,dc=com \
 --index cn \
 --index pwdaccountlockedtime \
 --index pwdfailuretime \
 --index pwdgraceusetime \
 --index uid \
 --index uniquemember \
 --index member \
 --trustAll
echo "Rebuild index completed."

bash dsconfig \
 set-plugin-prop \
 --plugin-name UID\ Unique\ Attribute \
 --set enabled:true \
 --hostname localhost \
 --port 5555 \
 --bindDn cn=Directory\ Manager \
 --bindPassword password \
 --trustAll \
 --no-prompt

bash dsconfig \
 set-plugin-prop \
 --plugin-name Referential\ Integrity \
 --set enabled:true \
 --hostname localhost \
 --port 5555 \
 --bindDn cn=Directory\ Manager \
 --bindPassword password \
 --trustAll \
 --no-prompt

echo "'UID Unique Attribute' and 'Referential Integrity' have enabled."

bash dsconfig \
 set-schema-provider-prop \
 --provider-name Core\ Schema \
 --set allow-zero-length-values-directory-string:true \
 --set json-validation-policy:lenient \
 --set strict-format-certificates:false \
 --set strict-format-country-string:false \
 --hostname localhost \
 --port 5555 \
 --bindDn cn=Directory\ Manager \
 --bindPassword password \
 --trustAll \
 --no-prompt

bash dsconfig \
 set-password-policy-prop \
 --policy-name Default\ Password\ Policy \
 --set allow-pre-encoded-passwords:true \
 --set default-password-storage-scheme:Salted\ SHA-512 \
 --hostname localhost \
 --port 5555 \
 --bindDn cn=Directory\ Manager \
 --bindPassword password \
 --trustAll \
 --no-prompt

echo "Core Schema Tuning Completed."

bash dsconfig \
 set-global-configuration-prop \
 --set je-backend-shared-cache-enabled:true \
 --hostname localhost \
 --port 5555 \
 --bindDn cn=Directory\ Manager \
 --bindPassword password \
 --trustAll \
 --no-prompt
echo "Je-backend cache share is ENABLED."


bash ldifmodify ~/ds_usexample_dev/config/config.ldif <<EOF
dn: cn=Access Control Handler, cn=config
changetype: modify
add: ds-cfg-global-aci
ds-cfg-global-aci: (targetattr="alive||healthy||monitor")(version 3.0; aci "Anonymous read access"; allow (read,search,compare) userdn="ldap:///anyone";)
EOF


bash dsconfig "${auth_opt[@]}" --trustAll --no-prompt --batch <<EOF
set-log-publisher-prop --publisher-name "File-Based Error Logger" --set log-file:/$logs/errors --set log-file-permissions:"644"
set-log-publisher-prop --publisher-name "File-Based Audit Logger" --set log-file:/$logs/audit --set log-file-permissions:"640"
set-log-publisher-prop --publisher-name "File-Based Access Logger" --set log-file:/$logs/access --set log-file-permissions:"644"
set-log-publisher-prop --publisher-name "File-Based Debug Logger" --set log-file:/$logs/debug --set log-file-permissions:"644"
set-log-publisher-prop --publisher-name "File-Based HTTP Access Logger" --set log-file:/$logs/http-access --set log-file-permissions:"644"
set-log-publisher-prop --publisher-name "Filtered Json File-Based Access Logger" --set log-directory:/$logs
set-log-publisher-prop --publisher-name "Replication Repair Logger" --set log-file:/$logs/replication --set log-file-permissions:"644"
set-log-publisher-prop --publisher-name "Json File-Based Access Logger" --set log-directory:/opt/ldaplogs/$logpath/logs
set-log-publisher-prop --publisher-name "Json File-Based HTTP Access Logger" --set log-directory:/$logs
EOF
echo"--------------------LOG FILE LOCATION SETS COMPLETED--------------------"

bash dsconfig "${auth_opt[@]}" --trustAll --no-prompt --batch <<EOF
set-log-retention-policy-prop --policy-name "File Count Retention Policy" --set number-of-files:30
set-log-publisher-prop --publisher-name "File-Based Access Logger" --add retention-policy:"Free Disk Space Retention Policy"
set-log-publisher-prop --publisher-name "File-Based Error Logger" --add retention-policy:"Free Disk Space Retention Policy"
set-log-publisher-prop --publisher-name "File-Based Audit Logger" --add retention-policy:"Free Disk Space Retention Policy"
EOF
echo"--------------LOG RETENTION & LOG PUBLISHER POLICY SETS COMPLETED--------------"

COMMENT

