Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash
#start tomacat
echo "shutdown&startup api tomcat"
su - gkapp -c '/bin/bash /home01/tomcat/api/apache-tomcat-8.5.72/bin/shutdown.sh'
su - gkapp -c '/bin/bash /home01/tomcat/api/apache-tomcat-8.5.72/bin/startup.sh'
echo "shutdown&startup admin tomcat"
su - gkapp -c '/bin/bash /home01/tomcat/admin/apache-tomcat-8.5.72/bin/shutdown.sh'
su - gkapp -c '/bin/bash /home01/tomcat/admin/apache-tomcat-8.5.72/bin/startup.sh'
echo "application launch completed"

#install ipa
echo "install ipa"
ipa=`ls /etc/rc* | grep ipa`
echo $ipa

if [[ "$ipa" = "" ]]
then
    cd /opt/ipa-client
    . ./ipa-uninstall.sh
    . ./setup-ipa-client.sh aws gkper-dev ansible
    . ./ipa-refresh.sh
    echo "etjR4tJ3owwANb0ARVKIbrU2E2HZhaTT" > /opt/ipa-client/.enroll_password
    . ./install-ipa-client.sh
    systemctl daemon-reload
    systemctl start ipa
    . ./ipa-check.sh
    echo "ipa installation complete"
else
    echo "ipa is already installed "
fi
--//--