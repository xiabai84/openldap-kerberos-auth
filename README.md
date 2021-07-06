# openldap-kerberos-auth

Kerberos + LDAP is common industry standard for authentication in distributed systems like Kafka and Hadoop.

But the most developers often face the problem of setting up such security infrastructure, because such work normally belongs to 
security team and only be setup once for the whole company. 

This project provides a dockerized openldap and kerberos environment, which is inspired by [osixia/openldap](https://hub.docker.com/r/osixia/openldap/).

## Openldap-Server

[Openldap](https://www.openldap.org/) is used for storing user including technical user information.

You can modify the ldap-structure via web-ui by using phpldapadmin tool.

An LDAP entry could be for example:

    CN=cluster-admin,OU=Kafka,OU=PermGrp,OU=MgtGrp,OU=Infrastrcuture,DC=example,DC=org 


## KDC-Server
If a new user is added in LDAP you must also register it in Kerberos as well, because they are not synchronized with each other.
By registering new user in Kerberos you can perform following command:

Docker Login:

    $ docker exec -ti kerberos bash

Create new Kerberos principal:

    $ kadmin.local -q 'addprinc -x dn=cn=cluster-admin" "Xia,cn=users,dc=ldap,dc=example,dc=org'

## Connection Test
**Kerberos should be able to query Openldap via LDAPS:**

    $ docker exec -ti kerberos bash
    
    $ ldapsearch -x -H ldaps://ldap.example.org:636 -b dc=example,dc=org -D "cn=admin,dc=example,dc=org" -w admin

