#! /bin/bash
source opendj.properities
<<'COMMENT'
sudo mkdir /opt/ldapdb/$dbpath/db
sudo mkdir /opt/ldaplogs/$logpath/logs
sudo chown rong_cong:rong_cong /opt/ldapdb/$dbpath/db
sudo chown rong_cong:rong_cong /opt/ldaplogs/$logpath/logs
sudo chmod 744 /opt/ldapdb/$dbpath/db
sudo chmod 744 /opt/ldaplogs/$logpath/logs


echo "How do you want to name DS?(Follow the format 'ds_<regionCode>
<appname>_<environmentType>')"
read dsname
echo "dsname=$dsname" >> /opt/script/opendj.properities
if [ -d "$home/$dsname" ]; then
	echo "Directory exists"
else
	if [ -d "$home/opendj" ]; then
		sudo mv "$home/opendj" "$home/$dsname"
		echo "Create successful"
	else
		for file in $home; do
       		if [[ $file=="DS-7"* ]] && [[ $file==*".zip" ]];then
               		sudo unzip $home/DS-7*.zip -d $home
				sudo mv "$home/opendj" "$home/$dsname"
				echo "Create successful"
       		else
               		echo "No ForgeRock DS file exists, Pls download"
               		exit 1
       		fi
		done
	fi	
fi

sudo chown -R rong_cong:rong_cong $home/$dsname
sudo chmod -R 744 $home/$dsname
cd $home/$dsname/bin
deployID=$(./dskeymgr create-deployment-id --deploymentIdPassword password)
echo "The Deployment ID is $deployID"
echo "DEPLOYMENT_ID=$deployID" >> /opt/script/opendj.properities

if [ -f "$home/$dsname/setup" ]; then
	echo "start setup"
	# Execute the .sh file
	cd $home/$dsname/
	bash setup \
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
 --acceptLicense
else
	echo "Error：/$dsname/setup does not exist."
	
fi

echo "Creating backend database."
COMMENT

cd $home/$dsname/bin/
<<'COMMENT'
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
 --set db-directory:$home/opt/ldapdb/$dbpath/db \
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
set-log-publisher-prop --publisher-name "File-Based Error Logger" --set log-file:/opt/ldaplogs/$logpath/logs/errors --set log-file-permissions:"644"
set-log-publisher-prop --publisher-name "File-Based Audit Logger" --set log-file:/opt/ldaplogs/$logpath/logs/audit --set log-file-permissions:"640"
set-log-publisher-prop --publisher-name "File-Based Access Logger" --set log-file:/opt/ldaplogs/$logpath/logs/access --set log-file-permissions:"644"
set-log-publisher-prop --publisher-name "File-Based Debug Logger" --set log-file:/opt/ldaplogs/$logpath/logs/debug --set log-file-permissions:"644"
set-log-publisher-prop --publisher-name "File-Based HTTP Access Logger" --set log-file:/opt/ldaplogs/$logpath/logs/http-access --set log-file-permissions:"644"
set-log-publisher-prop --publisher-name "Filtered Json File-Based Access Logger" --set log-directory:/opt/ldaplogs/$logpath/logs
set-log-publisher-prop --publisher-name "Replication Repair Logger" --set log-file:/opt/ldaplogs/$logpath/logs/replication --set log-file-permissions:"644"
set-log-publisher-prop --publisher-name "Json File-Based Access Logger" --set log-directory:/opt/ldaplogs/$logpath/logs
set-log-publisher-prop --publisher-name "Json File-Based HTTP Access Logger" --set log-directory:/opt/ldaplogs/$logpath/logs
EOF
echo"--------------------LOG FILE LOCATION SETS COMPLETED--------------------"
COMMENT
bash dsconfig "${auth_opt[@]}" --trustAll --no-prompt --batch <<EOF
set-log-retention-policy-prop --policy-name "File Count Retention Policy" --set number-of-files:30
set-log-publisher-prop --publisher-name "File-Based Access Logger" --add retention-policy:"Free Disk Space Retention Policy"
set-log-publisher-prop --publisher-name "File-Based Error Logger" --add retention-policy:"Free Disk Space Retention Policy"
set-log-publisher-prop --publisher-name "File-Based Audit Logger" --add retention-policy:"Free Disk Space Retention Policy"
EOF
echo"--------------LOG RETENTION & LOG PUBLISHER POLICY SETS COMPLETED--------------"
