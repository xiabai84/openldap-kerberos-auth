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

    $ kadmin.local -q 'add_principal -x linkdn=cn=user123,OU=ServiceAccount,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org user123'
    
    Authenticating as principal root/admin@EXAMPLE.ORG with password.
    WARNING: no policy specified for user123@EXAMPLE.ORG; defaulting to no policy
    Enter password for principal "user123@EXAMPLE.ORG":
    Re-enter password for principal "user123@EXAMPLE.ORG":
    Principal "user123@EXAMPLE.ORG" created.

    $ ldapsearch -x -H ldaps://ldap.example.org:636 -b OU=ServiceAccount,OU=Kafka,OU=Prod,OU=Infrastructure,DC=example,DC=org -D "cn=admin,dc=example,dc=org" -w admin

**Now Kerberos should be able to query Openldap**

    $ ldapsearch -x -H ldaps://ldap.example.org:636 -b dc=example,dc=org -D "cn=admin,dc=example,dc=org" -w admin

Part of Output:

    # extended LDIF
    #
    # LDAPv3
    # base <dc=example,dc=org> with scope subtree
    # filter: (objectclass=*)
    # requesting: ALL
    #
    
    # example.org
    dn: dc=example,dc=org
    objectClass: top
    objectClass: dcObject
    objectClass: organization
    o: Example Inc.
    dc: example
    
    # krbContainer, example.org
    dn: cn=krbContainer,dc=example,dc=org
    objectClass: krbContainer
    cn: krbContainer
    
    # EXAMPLE.ORG, krbContainer, example.org
    dn: cn=EXAMPLE.ORG,cn=krbContainer,dc=example,dc=org
    cn: EXAMPLE.ORG
    objectClass: top
    objectClass: krbRealmContainer
    objectClass: krbTicketPolicyAux
    krbSubTrees: dc=example,dc=org
    
    # K/M@EXAMPLE.ORG, EXAMPLE.ORG, krbContainer, example.org
    dn: krbPrincipalName=K/M@EXAMPLE.ORG,cn=EXAMPLE.ORG,cn=krbContainer,dc=example
    ,dc=org
    krbLoginFailedCount: 0
    krbMaxTicketLife: 36000
    krbMaxRenewableAge: 604800
    krbTicketFlags: 192
    krbPrincipalName: K/M@EXAMPLE.ORG
    krbPrincipalExpiration: 19700101000000Z
    krbPrincipalKey:: MGagAwIBAaEDAgEBogMCAQGjAwIBAKRQME4wTKAHMAWgAwIBAKFBMD+gAwIB
    EKE4BDYYAFUvyGuZYpdrvavNBw5uhZ6p96GndnOxiN1KizxU4SsBro8aNLk4nyF+tv3iP2qiJigyE
    mE=
    krbLastPwdChange: 19700101000000Z
    krbExtraData:: AAkBAAEAbRHmYA==
    krbExtraData:: AAJtEeZgZGJfY3JlYXRpb25ARVhBTVBMRS5PUkcA
    krbExtraData:: AAcBAAIAAlYAAAAAAAA=
    objectClass: krbPrincipal
    objectClass: krbPrincipalAux
    objectClass: krbTicketPolicyAux
    
    # krbtgt/EXAMPLE.ORG@EXAMPLE.ORG, EXAMPLE.ORG, krbContainer, example.org
    dn: krbPrincipalName=krbtgt/EXAMPLE.ORG@EXAMPLE.ORG,cn=EXAMPLE.ORG,cn=krbConta
    iner,dc=example,dc=org
    krbLoginFailedCount: 0
    krbMaxTicketLife: 36000
    krbMaxRenewableAge: 604800
    krbTicketFlags: 0
    krbPrincipalName: krbtgt/EXAMPLE.ORG@EXAMPLE.ORG
    krbPrincipalExpiration: 19700101000000Z
    krbPrincipalKey:: MIG2oAMCAQGhAwIBAaIDAgEBowMCAQCkgZ8wgZwwVKAHMAWgAwIBAKFJMEeg
    AwIBEqFABD4gAMLptKDcjwMS0HA2VjE8qZVvFjhe4gSgtuPGyEHGnZNr1WgErqbgAV6gshekHcbA6
    fGtvNsF0uwL1Gv1cTBEoAcwBaADAgEAoTkwN6ADAgERoTAELhAAndj7G8rd6cvfhknpqS75bDKPjP
    H4BuELzH0aqmECADTy72fg/Jg3xCrPvhQ=
    krbLastPwdChange: 19700101000000Z
    krbExtraData:: AAJtEeZgZGJfY3JlYXRpb25ARVhBTVBMRS5PUkcA
    krbExtraData:: AAcBAAIAAlYAAAAAAAA=
    objectClass: krbPrincipal
    objectClass: krbPrincipalAux
    objectClass: krbTicketPolicyAux
    
    # kadmin/admin@EXAMPLE.ORG, EXAMPLE.ORG, krbContainer, example.org
    dn: krbPrincipalName=kadmin/admin@EXAMPLE.ORG,cn=EXAMPLE.ORG,cn=krbContainer,d
    c=example,dc=org
    krbLoginFailedCount: 0
    krbMaxTicketLife: 10800
    krbMaxRenewableAge: 604800
    krbTicketFlags: 4
    krbPrincipalName: kadmin/admin@EXAMPLE.ORG
    krbPrincipalExpiration: 19700101000000Z
    krbPrincipalKey:: MIG2oAMCAQGhAwIBAaIDAgEBowMCAQCkgZ8wgZwwVKAHMAWgAwIBAKFJMEeg
    AwIBEqFABD4gAJKSRyuLgCkn3gIqjktHNCPj45M8N2Pd0a5f1kuaUaXzAMIF8ngSKRtYIYUsMBsMI
    qN7vBUkUll9nnBJWzBEoAcwBaADAgEAoTkwN6ADAgERoTAELhAAP8NMs6/ozxmjghquYnZDvyWTmL
    uYtQwcS0siA2WNCL4GN4+TGSbeLn4Och0=
    krbLastPwdChange: 19700101000000Z
    krbExtraData:: AAJtEeZgZGJfY3JlYXRpb25ARVhBTVBMRS5PUkcA
    krbExtraData:: AAcBAAIAAlYAAAAAAAA=
    objectClass: krbPrincipal
    objectClass: krbPrincipalAux
    objectClass: krbTicketPolicyAux
    
    # kadmin/fb236757fe13@EXAMPLE.ORG, EXAMPLE.ORG, krbContainer, example.org
    dn: krbPrincipalName=kadmin/fb236757fe13@EXAMPLE.ORG,cn=EXAMPLE.ORG,cn=krbCont
    ainer,dc=example,dc=org
    krbLoginFailedCount: 0
    krbMaxTicketLife: 10800
    krbMaxRenewableAge: 604800
    krbTicketFlags: 4
    krbPrincipalName: kadmin/fb236757fe13@EXAMPLE.ORG
    krbPrincipalExpiration: 19700101000000Z
    krbPrincipalKey:: MIG2oAMCAQGhAwIBAaIDAgEBowMCAQCkgZ8wgZwwVKAHMAWgAwIBAKFJMEeg
    AwIBEqFABD4gAOMZ8oySwdAOTLy8yXgHwL/8yISRVfhNSPbI18G3CNieQCQdoLQ/nTMlPl7zIVNrK
    N6KQ+9032nbR1ikJDBEoAcwBaADAgEAoTkwN6ADAgERoTAELhAAJ56slEhOUOnX6nSSj9N0T1otUZ
    cDq9JuZ9brCtajUmsxsJRdLAE6iujkeMQ=
    krbLastPwdChange: 19700101000000Z
    krbExtraData:: AAJtEeZgZGJfY3JlYXRpb25ARVhBTVBMRS5PUkcA
    krbExtraData:: AAcBAAIAAlYAAAAAAAA=
    objectClass: krbPrincipal
    objectClass: krbPrincipalAux
    objectClass: krbTicketPolicyAux
    
    # kiprop/fb236757fe13@EXAMPLE.ORG, EXAMPLE.ORG, krbContainer, example.org
    dn: krbPrincipalName=kiprop/fb236757fe13@EXAMPLE.ORG,cn=EXAMPLE.ORG,cn=krbCont
    ainer,dc=example,dc=org
    krbLoginFailedCount: 0
    krbMaxTicketLife: 36000
    krbMaxRenewableAge: 604800
    krbTicketFlags: 0
    krbPrincipalName: kiprop/fb236757fe13@EXAMPLE.ORG
    krbPrincipalExpiration: 19700101000000Z
    krbPrincipalKey:: MIG2oAMCAQGhAwIBAaIDAgEBowMCAQCkgZ8wgZwwVKAHMAWgAwIBAKFJMEeg
    AwIBEqFABD4gAPznGs0EttdY6eDs9vueOXe1cxOWHNIAd5l7hRYAwDh2GVwjdM1HG2g1yi9nuT4F8
    dbkpx+i+B1o0eilBzBEoAcwBaADAgEAoTkwN6ADAgERoTAELhAAtRXvmubvhQGttv/rCS2smPb6Gc
    /IavYhrWYvihPmzWzopKX6zYzZZuGw+mY=
    krbLastPwdChange: 19700101000000Z
    krbExtraData:: AAJtEeZgZGJfY3JlYXRpb25ARVhBTVBMRS5PUkcA
    krbExtraData:: AAcBAAIAAlYAAAAAAAA=
    objectClass: krbPrincipal
    objectClass: krbPrincipalAux
    objectClass: krbTicketPolicyAux
    
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