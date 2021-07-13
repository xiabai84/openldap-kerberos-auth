## 1 Create own CA
Assume that you don't have CA certificate yet, otherwise skip this step.
In this project I already copied the private ca.key and public ca.crt under openldap/service/slapd/certs folder. 

    $ openssl req \
    -new \
    -newkey rsa:4096 \
    -days 365 \
    -x509 \
    -subj "/CN=Security-CA" \
    -keyout ca.key \
    -out ca.crt \
    -nodes

## 2 Generate credential for Kafka Server
    $ export SRVPASS="mypassword"

### 2.1 Create Keystore
    $ keytool -genkey \
    -keystore kafka.server.keystore.jks \
    -validity 365 \
    -storepass $SRVPASS \
    -keypass $SRVPASS \
    -dname "CN=kafka" \
    -storetype pkcs12

View Keystore:

    $ keytool -list -v -keystore kafka.server.keystore.jks

### 2.2 Create new signing request
    
    $ keytool \
    -keystore kafka.server.keystore.jks \
    -certreq \
    -file signing-req \
    -storepass $SRVPASS \
    -keypass $SRVPASS

### 2.3 Sign Server certificate for Kafka Server

    $ openssl x509 \
    -req \
    -CA ca.crt \
    -CAkey ca.key \
    -in signing-req \
    -out signed-kafka.crt \
    -days 365 \
    -CAcreateserial \
    -passin pass:$SRVPASS
    
### 2.4 Create Truststore
    $ keytool \
    -keystore kafka.server.truststore.jks \
    -alias CAROOT \
    -import \
    -file ca.crt \
    -storepass $SRVPASS \
    -keypass $SRVPASS \
    -noprompt

### Adding ca.crt and signed-cert to Kafka Keystore
    $ keytool -keystore kafka.server.keystore.jks \
    -alias CARoot \
    -import \
    -file ca.crt \
    -storepass $SRVPASS \
    -keypass $SRVPASS \
    -noprompt
    
    $ keytool -keystore kafka.server.keystore.jks \
    -alias KafkaRoot \
    -import \
    -file signed-kafka.crt \
    -storepass $SRVPASS \
    -keypass $SRVPASS \
    -noprompt
