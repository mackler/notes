#!/bin/sh
# By photz: https://github.com/PostgREST/postgrest/issues/1130#issuecomment-400220291

if [ $# -lt 1 ]; then
    1>&2 echo "usage: $0 <auth0-subdomain>"
    exit 1
fi

wget --quiet -O - https://$1.auth0.com/.well-known/jwks.json     | jq "{
    alg: .keys[0].alg,
    kty: .keys[0].kty,
    use: .keys[0].use,
    n: .keys[0].n,
    kid: .keys[0].kid,
    e: .keys[0].e
}"
