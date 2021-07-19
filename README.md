# openldap-kerberos-auth

Kerberos + LDAP is common industry standard for authentication in distributed systems like Kafka and Hadoop.

But the most developers often face the problem of setting up such security infrastructure, because such work normally belongs to 
security team and only be setup once for the whole company. 

This project provides a dockerized openldap and kerberos environment, which is inspired by [osixia/openldap](https://hub.docker.com/r/osixia/openldap/).
With its help developer can quickly build a local production like authentication server and use it for further security configuration.

## Openldap-Server

[Openldap](https://www.openldap.org/) is used for storing user including technical user information.

You can modify the ldap-structure via web-ui by using phpldapadmin tool.

An LDAP entry could be for example:

    CN=SYS-ADMIN,OU=Kafka,OU=PermGrp,OU=MgtGrp,OU=Infrastrcuture,DC=example,DC=org

By default via docker-compose, kerberos container's IP will not be in certificate cn. That means, the container CA isn't knowned by your host.

You can use a quick and dirty solution to overcome this issue by setting **LDAP_TLS_VERIFY_CLIENT: "never"** in docker-compose.yml. 


## KDC-Server
If a new user is added in LDAP you must also register it in Kerberos as well.
By registering new user in Kerberos you can perform following command:

Docker Login:

    $ docker exec -ti kerberos bash

Test ldaps connection(password admin):

    export REALM="EXAMPLE.ORG"
    export LDAP_URL="ldaps://ldap.example.org"
    kdb5_ldap_util -r $REALM -H $LDAP_URL -D "cn=admin,dc=example,dc=org" -W view

Create test user:

    # Grab the script from test/add_user.ldif. 
    # For editing you can install vim by yourself, since container will start as root user

    $ ldapadd -x -H ldaps://ldap.example.org:636 -D "cn=admin,dc=example,dc=org" -W -f init_ldap.ldif
    
    Enter LDAP Password: admin
    adding new entry "OU=Infrastructure,DC=example,DC=org"
    adding new entry "OU=Prod,OU=Infrastructure,DC=example,DC=org"
    adding new entry "OU=Test,OU=Infrastructure,DC=example,DC=org"
    adding new entry "OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org"
    adding new entry "OU=ServiceAccount,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org"
    adding new entry "OU=TIER-PARTNER-TP,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org"
    adding new entry "CN=Reader,OU=TIER-PARTNER-TP,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org"
    adding new entry "CN=Writer,OU=TIER-PARTNER-TP,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org"
    adding new entry "CN=Viewer,OU=TIER-PARTNER-TP,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org"
    adding new entry "uid=kafka-stream-001,OU=ServiceAccount,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org"
    modifying entry "CN=Writer,OU=TIER-PARTNER-TP,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org"
    modifying entry "CN=Reader,OU=TIER-PARTNER-TP,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org"
    modifying entry "CN=Viewer,OU=TIER-PARTNER-TP,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org"   

Add new Kerberos principal and link it to user123:

    $ kadmin.local -q 'add_principal -x linkdn=cn=user123,OU=ServiceAccount,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org user123'

    # kafka/kafka -> service_name/hostname(broker)
    $ kadmin.local -q 'add_principal -x linkdn=cn=kafka,OU=ServiceAccount,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org kafka/kafka'


**Now users are queryable over ldap:**

    $ ldapsearch -x -H ldaps://ldap.example.org:636 -b dc=example,dc=org -D "cn=admin,dc=example,dc=org" -w admin

Part of Output:

    # extended LDIF
    #
    # LDAPv3
    # base <dc=example,dc=org> with scope subtree
    # filter: (objectclass=*)
    # requesting: ALL
    
    ...
    
    # user1234, ServiceAccount, Kafka, Prod, Infrastructure, example.org
    dn: cn=user1234,ou=ServiceAccount,ou=Kafka,ou=Prod,ou=Infrastructure,dc=exampl
    e,dc=org
    cn: user1234
    objectClass: person
    objectClass: uidObject
    objectClass: inetOrgPerson
    mail: user1234@EXAMPLE.ORG
    uid: user1234
    title: Mr.
    givenName: Bai
    sn: Xia
    userPassword:: bXlwYXNzd29yZA==
    
    # search result
    search: 2
    result: 0 Success
    
    # numResponses: 23
    # numEntries: 22

## phpldapadmin

You can also use phpldapadmin for having a better [view](http://localhost:8080).

Login:

    cn=admin,dc=example,dc=org
Password:

    admin


## config krb5.conf file on client
first steup principal kafka/kafka@EXAMPLE.ORG on server-side, then perfom:

    $ kinit kafka/kafka@EXAMPLE.ORG
    $ klist

## Creating Keytab for Kafka Server
    
    # set this ticket permission to 600
    $ kadmin.local -q "xst -kt /tmp/kafka.service.keytab kafka/kafka@EXAMPLE.ORG"

# copy keytab from kdc to kafka

    $ docker cp kerberos:/tmp/kafka.service.keytab .


# Extra Configuration

## Certificate:
jks keystore, truststore mount under /bitnami/kafka/config/certs directory

## Start Kafka Service
Before Kafka service being initialized, the KDC and LDAP services must be up and ready for use.

Bitnami Kafka has no support for Kerberos configuration and has some special configuration round TLS authentication.
Therefore, we must manipulate its init scripts like libkafka.sh and run.sh to solve this problem.

## Generate Certificates
    
    # create keystore
    $ keytool -genkey -keyalg RSA -keystore kafka.server.keystore.jks -validity 365 -storepass $SRVPASS -keypass $SRVPASS -dname "CN=kafka" -storetype pkcs12
    
    # signing request
    $ keytool -keystore kafka.server.keystore.jks -certreq -file cert-file -storepass $SRVPASS -keypass $SRVPASS

    # Sign new certificate for Kafka server (assume we have a CA already, use ca.key and ca.crt from ldap server)
    $ openssl x509 -req -CA ca.crt -CAkey ca.key -in cert-file -out cert-signed -days 365 -CAcreateserial -passin pass:$SRVPASS

    # create truststore
    $ keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca.crt -storepass $SRVPASS -keypass $SRVPASS -noprompt
    
    # import certs
    $ keytool -keystore kafka.server.keystore.jks -alias CARoot -import -file ca.crt -storepass $SRVPASS -keypass $SRVPASS -noprompt
    $ keytool -keystore kafka.server.keystore.jks -alias KafkaRoot -import -file cert-signed -storepass $SRVPASS -keypass $SRVPASS -noprompt


## Current Exception

org.apache.kafka.common.KafkaException: org.apache.kafka.common.config.ConfigException: Invalid value javax.net.ssl.SSLHandshakeException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target for configuration A client SSLEngine created with the provided settings can't connect to a server SSLEngine created with those settings.
kafka_1         | 	at org.apache.kafka.common.network.SaslChannelBuilder.configure(SaslChannelBuilder.java:184)
kafka_1         | 	at org.apache.kafka.common.network.ChannelBuilders.create(ChannelBuilders.java:192)
kafka_1         | 	at org.apache.kafka.common.network.ChannelBuilders.serverChannelBuilder(ChannelBuilders.java:107)
kafka_1         | 	at kafka.network.Processor.<init>(SocketServer.scala:853)
kafka_1         | 	at kafka.network.SocketServer.newProcessor(SocketServer.scala:442)
kafka_1         | 	at kafka.network.SocketServer.$anonfun$addDataPlaneProcessors$1(SocketServer.scala:299)
kafka_1         | 	at scala.collection.immutable.Range.foreach$mVc$sp(Range.scala:158)
kafka_1         | 	at kafka.network.SocketServer.addDataPlaneProcessors(SocketServer.scala:297)
kafka_1         | 	at kafka.network.SocketServer.$anonfun$createDataPlaneAcceptorsAndProcessors$1(SocketServer.scala:262)
kafka_1         | 	at kafka.network.SocketServer.$anonfun$createDataPlaneAcceptorsAndProcessors$1$adapted(SocketServer.scala:259)
kafka_1         | 	at scala.collection.mutable.ResizableArray.foreach(ResizableArray.scala:62)
kafka_1         | 	at scala.collection.mutable.ResizableArray.foreach$(ResizableArray.scala:55)
kafka_1         | 	at scala.collection.mutable.ArrayBuffer.foreach(ArrayBuffer.scala:49)
kafka_1         | 	at kafka.network.SocketServer.createDataPlaneAcceptorsAndProcessors(SocketServer.scala:259)
kafka_1         | 	at kafka.network.SocketServer.startup(SocketServer.scala:131)
kafka_1         | 	at kafka.server.KafkaServer.startup(KafkaServer.scala:285)
kafka_1         | 	at kafka.Kafka$.main(Kafka.scala:109)
kafka_1         | 	at kafka.Kafka.main(Kafka.scala)
kafka_1         | Caused by: org.apache.kafka.common.config.ConfigException: Invalid value javax.net.ssl.SSLHandshakeException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target for configuration A client SSLEngine created with the provided settings can't connect to a server SSLEngine created with those settings.
kafka_1         | 	at org.apache.kafka.common.security.ssl.SslFactory.configure(SslFactory.java:100)
kafka_1         | 	at org.apache.kafka.common.network.SaslChannelBuilder.configure(SaslChannelBuilder.java:180)
kafka_1         | 	... 17 more