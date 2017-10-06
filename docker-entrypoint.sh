#!/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

set -e

if [ "$1" = 'couchdb' ]; then
	
	CONFIG=/usr/local/etc/couchdb/local.d/local.ini

	touch $CONFIG

	# we need to set the permissions here because docker mounts volumes as root
	chown -R couchdb:couchdb \
		/usr/local/var/lib/couchdb \
		/usr/local/var/log/couchdb \
		/usr/local/var/run/couchdb \
		/usr/local/etc/couchdb 

	chmod -R 0770 \
		/usr/local/var/lib/couchdb \
		/usr/local/var/log/couchdb \
		/usr/local/var/run/couchdb \
		/usr/local/etc/couchdb

	chmod 664 /usr/local/etc/couchdb/*.ini;
	chmod 775 /usr/local/etc/couchdb/*.d;

	HTTPD=();
	CORS=();
	ADMINS=();
	COUCH_HTTPD_AUTH=();

	# Create admin
	if [ "$COUCHDB_USER" ] && [ "$COUCHDB_PASSWORD" ]; then
		ADMINS=("${ADMINS[@]}" "$COUCHDB_USER=$COUCHDB_PASSWORD")
	fi

	# array of auth handlers (http://docs.couchdb.org/en/1.6.1/config/http.html#httpd/authentication_handlers)
	if [ "$COUCHDB_AUTH_HANDLERS" ]; then

		#parse string into array
		IFS=',' read -r -a handlers <<< "$COUCHDB_AUTH_HANDLERS"
		authentication_handlers=()

		# Set auth handlers
		for handler in "${handlers[@]}"; do
			trimmed="$(echo -e "${handler}" | tr -d '[:space:]')"

			if [ $trimmed == 'oauth_authentication_handler' ]; then
				auth_type='couch_httpd_oauth'
			else
				auth_type='couch_httpd_auth'
			fi

			authentication_handlers=("${authentication_handlers[@]}" "{$auth_type,$trimmed}")
		done

		auth_handler_string=$(IFS=,;printf "%s" "${authentication_handlers[*]}")

		HTTPD=("${HTTPD[@]}" "authentication_handlers=$auth_handler_string")
	fi

	# CORS
	if [ "$COUCHDB_ENABLE_CORS" == "true" ]; then
		HTTPD=("${HTTPD[@]}" "enable_cors=true")

		CORS=("${CORS[@]}" "origins=$COUCHDB_CORS_ORIGINS")
		CORS=("${CORS[@]}" "credentials=$COUCHDB_CORS_CREDENTIALS")
		CORS=("${CORS[@]}" "methods='$COUCHDB_CORS_METHODS'")
		CORS=("${CORS[@]}" "headers='$COUCHDB_CORS_HEADERS'")
	fi

	if [ "$COUCHDB_PORT" ]; then
		HTTPD=("${HTTPD[@]}" "port=$COUCHDB_PORT")
	fi

	if [ "$COUCHDB_HOST" ]; then
		HTTPD=("${HTTPD[@]}" "bind_address=$COUCHDB_HOST")
	fi

	if [ "$COUCHDB_REQUIRE_VALID_USER" ]; then
		COUCH_HTTPD_AUTH=("${COUCH_HTTPD_AUTH[@]}" "require_valid_user=$COUCHDB_REQUIRE_VALID_USER")
	fi

	if [ "$COUCHDB_SECRET" ]; then
		COUCH_HTTPD_AUTH=("${COUCH_HTTPD_AUTH[@]}" "secret=$COUCHDB_SECRET")
	fi		

	if [ "$COUCHDB_PROXY_USE_SECRET" ]; then
		COUCH_HTTPD_AUTH=("${COUCH_HTTPD_AUTH[@]}" "proxy_use_secret=$COUCHDB_PROXY_USE_SECRET")
	fi			

	# write httpd
	printf "[admins]\n" > $CONFIG
	for record in "${ADMINS[@]}"; do
		printf "%s\n" "$record" >> $CONFIG
	done

	printf "\n[cors]\n" >> $CONFIG
	for record in "${CORS[@]}"; do
		printf "%s\n" "$record" >> $CONFIG
	done

	printf "\n[httpd]\n" >> $CONFIG
	for record in "${HTTPD[@]}"; do
		printf "%s\n" "$record" >> $CONFIG
	done		

	printf "\n[couch_httpd_auth]\n" >> $CONFIG
	for record in "${COUCH_HTTPD_AUTH[@]}"; do
		printf "%s\n" "$record" >> $CONFIG
	done		

	printf 'CONFIG:\n'
	cat "$CONFIG"


	# if we don't find an [admins] section followed by a non-comment, display a warning
	if ! grep -Pzoqr '\[admins\]\n[^;]\w+' /usr/local/etc/couchdb; then
		# The - option suppresses leading tabs but *not* spaces. :)
		cat >&2 <<-'EOWARN'
			****************************************************
			WARNING: CouchDB is running in Admin Party mode.
			         This will allow anyone with access to the
			         CouchDB port to access your database. In
			         Docker's default configuration, this is
			         effectively any other container on the same
			         system.
			         Use "-e COUCHDB_USER=admin -e COUCHDB_PASSWORD=password"
			         to set it in "docker run".
			****************************************************
		EOWARN
	fi

	exec gosu couchdb "$@"
fi

exec "$@"
