#!/bin/sh

# Extract and move code into place, staging
if [ -d "/etc/puppetlabs/code-staging/environments/${DISTELLI_ENV}" ]; then
  sudo rm -rf /etc/puppetlabs/code-staging/environments/$DISTELLI_ENV
  sudo mv $DISTELLI_RELVERSION /etc/puppetlabs/code-staging/environments/$DISTELLI_ENV
else
  sudo mv $DISTELLI_RELVERSION /etc/puppetlabs/code-staging/environments/$DISTELLI_ENV
fi

# Commit code in staging to live
[ "$1" = '-v' ] && verbose='true' || verbose=
certname=$(sudo puppet config print certname --section agent)

curl_wrapper()
{
  [ "$verbose" = 'true' ] && echo "command: curl $@"
  output=$(sudo curl "$@")
  exitcode=$?
  if [ "$verbose" = 'true' ]; then
    echo "output: $output"
    echo "exitcode: $exitcode"
    echo
  fi
}

# Perform two calls to file-sync. First, commit the code from code-staging.
# Second, force a sync/deploy to the code directory. The second step is
# performed explicitly so that we are guaranteed the deploy is finished
# before we take any action that depends on that task being done.
curl_wrapper -ks --request POST --header "Content-Type: application/json" \
  --cert "/etc/puppetlabs/puppet/ssl/certs/${certname}.pem" \
  --key "/etc/puppetlabs/puppet/ssl/private_keys/${certname}.pem" \
  --cacert "/etc/puppetlabs/puppet/ssl/certs/ca.pem" \
  --data '{"commit-all": true}' \
  'https://localhost:8140/file-sync/v1/commit'

curl_wrapper -ks --request POST --header "Content-Type: application/json" \
  --cert "/etc/puppetlabs/puppet/ssl/certs/${certname}.pem" \
  --key "/etc/puppetlabs/puppet/ssl/private_keys/${certname}.pem" \
  --cacert "/etc/puppetlabs/puppet/ssl/certs/ca.pem" \
  'https://localhost:8140/file-sync/v1/force-sync'

# Perform a call to the puppetserver to flush the environment cache. This
# ensures the newly deployed code is loaded.
curl_wrapper -ks --request DELETE --header "Content-Type: application/json" \
  --cert "/etc/puppetlabs/puppet/ssl/certs/${certname}.pem" \
  --key "/etc/puppetlabs/puppet/ssl/private_keys/${certname}.pem" \
  --cacert "/etc/puppetlabs/puppet/ssl/certs/ca.pem" \
  'https://localhost:8140/puppet-admin-api/v1/environment-cache'


