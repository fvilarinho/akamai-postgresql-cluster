#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$DOMAIN" ]; then
    echo "The domain to be used in the certificate issuance is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$EMAIL" ]; then
    echo "The email to be used in the certificate issuance is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$TOKEN" ]; then
    echo "The token for the certificate issuance is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$CERTIFICATE_ISSUANCE_PROPAGATION_DELAY" ]; then
    echo "The propagation delay for the certificate issuance is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Issue the certificate using Certbot. The validation will be in the Linode DNS.
function issueTheCertificate() {
  echo "Check if the certificate already exists..."

  if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] || [ ! -f "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ]; then
    echo "Issuing the certificate..."

    CERTIFICATE_ISSUANCE_CREDENTIALS_FILENAME=/tmp/.certificateIssuance.credentials

    echo "dns_linode_key = $TOKEN" > "$CERTIFICATE_ISSUANCE_CREDENTIALS_FILENAME"

    $CERTBOT_CMD certonly \
                 --dns-linode \
                 --dns-linode-credentials "$CERTIFICATE_ISSUANCE_CREDENTIALS_FILENAME" \
                 --dns-linode-propagation-seconds "$CERTIFICATE_ISSUANCE_PROPAGATION_DELAY" \
                 --domain "$DOMAIN" \
                 --domain "*.$DOMAIN" \
                 --email "$EMAIL"

    rm -f "$CERTIFICATE_ISSUANCE_CREDENTIALS_FILENAME"

    if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] || [ ! -f "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ]; then
      echo "Certificate couldn't not be issued! Please check the details in the logs in the system!"

      exit 1
    fi
  fi

  echo "The certificate was validated successfully!"
}

# Main function.
function main() {
  checkDependencies
  issueTheCertificate
}

main