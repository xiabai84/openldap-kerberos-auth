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
    $ kadmin.local -q 'add_principal -x linkdn=cn=kafka,OU=ServiceAccount,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org kafka/kafka-broker1'


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
