#!/bin/bash
JMETER_HOME=/opt/jmeter
# Script install jMeter-salve for debian9
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install -y unzip bc
# Add Oracle JAVA repository
echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | sudo tee /etc/apt/sources.list.d/webupd8team-java.list
echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | sudo tee -a /etc/apt/sources.list.d/webupd8team-java.list
sudo apt-get install -y dirmngr --install-recommends && sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
echo oracle-java8-installer shared/accepted-oracle-licence-v1-1 boolean true | sudo /usr/bin/debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get update && sudo apt-get install -y oracle-java8-installer
# ==== Install jMeter-4.0 ====
cd /tmp && sudo wget http://www-us.apache.org/dist/jmeter/binaries/apache-jmeter-4.0.tgz
cd /opt && sudo tar zxvf /tmp/apache-jmeter-4.0.tgz && sudo ln -sf /opt/apache-jmeter-4.0 /opt/jmeter
cd /opt/jmeter && sudo find . -name *.bat -delete && sudo find . -name *.cmd -delete
cd /opt/jmeter/lib && sudo curl -O -J -L http://central.maven.org/maven2/kg/apc/cmdrunner/2.2/cmdrunner-2.2.jar && cd /opt/jmeter/lib/ext && sudo curl -O -J -L https://jmeter-plugins.org/get/
sudo unzip -j /opt/jmeter/lib/ext/jmeter-plugins-manager-1.1.jar "org/jmeterplugins/repository/PluginsManagerCMD.sh" -d /opt/jmeter/bin/ && sudo chmod +x /opt/jmeter/bin/PluginsManagerCMD.sh
sudo /opt/jmeter/bin/PluginsManagerCMD.sh install jpgc-casutg bzm-random-csv
# Set Environment VARs
echo -e "export JMETER_HOME=/opt/jmeter\nexport PATH=\$PATH:\$JMETER_HOME/bin" | sudo tee -a /etc/profile.d/jmeter.sh && sudo chmod +x /etc/profile.d/jmeter.sh
# Generate RMI Keystore
_CN=`/sbin/ifconfig eth0 | grep "inet " | awk '{ print $2 }'`
_PASS=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
sudo keytool -genkey -noprompt \
        -keyalg RSA -alias rmi \
        -dname "CN=_$CN, OU=DevPool, O=GoSoft, L=Silom, S=Bangkok, C=TH" \
        -keystore $JMETER_HOME/bin/rmi_keystore.jks -storepass $_PASS -keypass $_PASS -validity 7 \
        -keysize 2048
# Replace keystore path and Store Password
sudo sed -i "s|^#server\.rmi\.ssl\.keystore\.password=changeit|server\.rmi\.ssl\.keystore\.password=$_PASS|g" $JMETER_HOME/bin/jmeter.properties
sudo sed -i "s|^#server\.rmi\.ssl\.truststore\.password=changeit|server\.rmi\.ssl\.truststore\.password=$_PASS|g" $JMETER_HOME/bin/jmeter.properties
sudo sed -i "s|^#server\.rmi\.ssl\.keystore\.file=rmi_keystore\.jks|server\.rmi\.ssl\.keystore\.file=$JMETER_HOME\/bin\/rmi_keystore\.jks|g" $JMETER_HOME/bin/jmeter.properties
sudo sed -i "s|^#server\.rmi\.ssl\.truststore\.file=rmi_keystore\.jks|server\.rmi\.ssl\.truststore\.file=$JMETER_HOME\/bin\/rmi_keystore\.jks|g" $JMETER_HOME/bin/jmeter.properties

# Create local directory for jmeter 
mkdir -p ~/jmeter/{conf,log,run}
# Set HEAP = 80% of TotalMemory and Metaspace = 25% of HEAP
#_HeapMem=`grep MemTotal /proc/meminfo | awk '{print $2}' | xargs -I {} echo "scale=2; ({}/1024^2)*.8" | bc | awk '{printf "%02.2f\n", $0}'`
_HeapMem=`grep MemAvailable /proc/meminfo  | awk '{ print $2 }' | xargs -I {} echo "{}/1024" | bc`
_MetaSpaec=`echo "${_HeapMem}/2" | bc`
echo -e "HEAP=\"-Xms${_HeapMem}m -Xmx${_HeapMem}m -XX:MaxMetaspaceSize=${_MetaSpaec}m\"\n" | tee ~/jmeter/conf/jmeter-options.conf > /dev/null

