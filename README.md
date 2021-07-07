# openldap-kerberos-auth

Kerberos + LDAP is common industry standard for authentication in distributed systems like Kafka and Hadoop.

But the most developers often face the problem of setting up such security infrastructure, because such work normally belongs to 
security team and only be setup once for the whole company. 

This project provides a dockerized openldap and kerberos environment, which is inspired by [osixia/openldap](https://hub.docker.com/r/osixia/openldap/).

## Openldap-Server

[Openldap](https://www.openldap.org/) is used for storing user including technical user information.

You can modify the ldap-structure via web-ui by using phpldapadmin tool.

An LDAP entry could be for example:

    CN=SYS-ADMIN,OU=Kafka,OU=PermGrp,OU=MgtGrp,OU=Infrastrcuture,DC=example,DC=org

By default via docker-compose, kerberos container's IP will not be in certificate cn. That means, the container CA isn't knowned by your host.

You can use a quick and dirty solution to overcome this issue by setting **LDAP_TLS_VERIFY_CLIENT: "never"** in docker-compose.yml. 


## KDC-Server
If a new user is added in LDAP you must also register it in Kerberos as well, because they are not synchronized with each other.
By registering new user in Kerberos you can perform following command:

Docker Login:

    $ docker exec -ti kerberos bash

Test ldaps connection(password admin):

    export REALM="EXAMPLE.ORG"
    export LDAP_URL="ldaps://ldap.example.org"
    kdb5_ldap_util -r $REALM -H $LDAP_URL -D "cn=admin,dc=example,dc=org" -W view

## phpldapadmin

You can also use phpldapadmin for having a better [view](http://localhost:8080). 

Login:

    cn=admin,dc=example,dc=org
Password:
    
    admin

## Creating user and principal

Create test user:

    # grab the script from test/add_user.ldif. 
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

    $ kadmin.local -q 'add_principal -x linkdn=cn=user123,OU=ServiceAccount,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org'
    
    Authenticating as principal root/admin@EXAMPLE.ORG with password.
    WARNING: no policy specified for user123@EXAMPLE.ORG; defaulting to no policy
    Enter password for principal "user123@EXAMPLE.ORG":
    Re-enter password for principal "user123@EXAMPLE.ORG":
    Principal "user123@EXAMPLE.ORG" created.

    $ ldapsearch -x -H ldaps://ldap.example.org:636 -b OU=ServiceAccount,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org -D "cn=admin,dc=example,dc=org" -w admin

**Now Kerberos should be able to query Openldap**

    $ ldapsearch -x -H ldaps://ldap.example.org:636 -b dc=example,dc=org -D "cn=admin,dc=example,dc=org" -w admin

Output:

    dn: krbPrincipalName=kadmin/history@EXAMPLE.ORG,cn=EXAMPLE.ORG,cn=krbContainer,dc=example,dc=org
    krbLoginFailedCount: 0
    krbMaxTicketLife: 36000
    krbMaxRenewableAge: 604800
    krbTicketFlags: 0
    krbPrincipalName: kadmin/history@EXAMPLE.ORG
    krbPrincipalExpiration: 19700101000000Z
    krbPrincipalKey:: MGagAwIBAaEDAgEBogMCAQGjAwIBAKRQME4wTKAHMAWgAwIBAKFBMD+gAwIB
    EKE4BDYYAH16cf9AqSnc0VtJ+28lR1tuXKO8aNQeHze/orLCWx1XgKoB7NXgClb1flEJS7HeFAf2v
    RE=
    krbLastPwdChange: 19700101000000Z
    krbExtraData:: AALlfuRgZGJfY3JlYXRpb25ARVhBTVBMRS5PUkcA
    krbExtraData:: AAcBAAIAAlUAAAAAAAA=
    objectClass: krbPrincipal
    objectClass: krbPrincipalAux
    objectClass: krbTicketPolicyAux
    
    # Service, example.org
    dn: ou=Service,dc=example,dc=org
    objectClass: organizationalUnit
    ou: Service
    
    # Kafka, Service, example.org
    dn: ou=Kafka,ou=Service,dc=example,dc=org
    objectClass: organizationalUnit
    ou: Kafka
    
    # User, Kafka, Service, example.org
    dn: ou=User,ou=Kafka,ou=Service,dc=example,dc=org
    objectClass: organizationalUnit
    ou: User
    
    # user123, User, Kafka, Service, example.org
    dn: cn=user123,ou=User,ou=Kafka,ou=Service,dc=example,dc=org
    cn: user123
    objectClass: person
    objectClass: uidObject
    objectClass: inetOrgPerson
    mail: user123@EXAMPLE.ORG
    uid: user123
    title: Mr.
    givenName: Bai
    sn: Xia
    
    # user123@EXAMPLE.ORG, EXAMPLE.ORG, krbContainer, example.org
    dn: krbPrincipalName=user123@EXAMPLE.ORG,cn=EXAMPLE.ORG,cn=krbContainer,dc=exa
    mple,dc=org
    krbLoginFailedCount: 0
    krbPrincipalName: user123@EXAMPLE.ORG
    krbPrincipalKey:: MIG2oAMCAQGhAwIBAaIDAgEBowMCAQGkgZ8wgZwwVKAHMAWgAwIBAKFJMEeg
    AwIBEqFABD4gAGDizHqUNkB9cw9A372y1dsJbcXtO7Z0V80KPFp8rM9XisIj+xRqbP7E+W78hy9wg
    i3+Q7lFKYQ6Q5ZR0zBEoAcwBaADAgEAoTkwN6ADAgERoTAELhAAZM+kEB/0S5M53vVQZ8uhVkTYMK
    VcpCihNl3I0j7RlzLUfX9nAJzc48pG7AM=
    krbLastPwdChange: 20210706160519Z
    krbExtraData:: AAI/f+Rgcm9vdC9hZG1pbkBFWEFNUExFLk9SRwA=
    krbExtraData:: AAgBAA==
    krbObjectReferences: cn=user123,ou=User,ou=Kafka,ou=Service,dc=example,dc=org
    objectClass: krbPrincipal
    objectClass: krbPrincipalAux
    objectClass: krbTicketPolicyAux
    
    # search result
    search: 2
    result: 0 Success
    
    # numResponses: 16
    # numEntries: 15
