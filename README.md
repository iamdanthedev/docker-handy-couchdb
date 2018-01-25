# DTD HANDY COUCHDB 1.6.1 IMAGE

### This a more convenient couchdb 1.6.1 image that accepts plenty of env vars which go directly into the couchdb config file ###

Supports the following ENV vars (=defaults):

```bash
COUCHDB_PORT=5984
COUCHDB_HOST=0.0.0.0
COUCHDB_USER=admin
COUCHDB_PASSWORD=admin
COUCHDB_ENABLE_CORS=false
COUCHDB_AUTH_HANDLERS=oauth_authentication_handler,cookie_authentication_handler,default_authentication_handler
COUCHDB_COUCHPERUSER=false
COUCHDB_REQUIRE_VALID_USER=false
COUCHDB_SECRET=secret
COUCHDB_PROXY_USE_SECRET=false
COUCHDB_CORS_ORIGINS=*
COUCHDB_CORS_CREDENTIALS=true
COUCHDB_CORS_METHODS=GET,PUT,POST,HEAD,DELETE
COUCHDB_CORS_HEADERS=accept,authorization,content-type,origin,referer,x-csrf-token
```
