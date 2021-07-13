FROM ubuntu

# kerberos
RUN apt-get update -y && apt-get install -y krb5-kdc-ldap krb5-admin-server ldap-utils vim openssh-client

EXPOSE 88 464 749

RUN mkdir -p /etc/openldap/certs

ADD ./certs /etc/openldap/certs
ADD ./ldap /etc/ldap
ADD ./config.sh /config.sh
ADD ./service_account /home

RUN chmod 644 /etc/ldap/ldap.conf && chmod +x /config.sh

ENTRYPOINT ["/config.sh"]
