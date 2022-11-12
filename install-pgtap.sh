#!/bin/bash
docker compose exec db bash -c 'cat <<"EOF" | bash
PGTAP_RELEASE=1.2.0
PGTAP_RELEASE_HASH=6fbeb031fe57fe02dfcee73623653c83b2eaf4d24fbbfe7074e847cfd291fe0d

apt update && apt install -y curl unzip make patch
cpan TAP::Parser::SourceHandler::pgTAP

cd /tmp
curl -sLO https://github.com/theory/pgtap/releases/download/v${PGTAP_RELEASE}/pgTAP-${PGTAP_RELEASE}.zip
echo "${PGTAP_RELEASE_HASH} *pgTAP-${PGTAP_RELEASE}.zip" | sha256sum -c -
unzip pgTAP-${PGTAP_RELEASE}.zip

cd pgTAP-${PGTAP_RELEASE}/
make
make install
make installcheck PGUSER=postgres

psql -U postgres <<"EOS"
\x
CREATE SCHEMA IF NOT EXISTS postlife;
CREATE EXTENSION IF NOT EXISTS pgtap SCHEMA postlife;
EOS
EOF
'
