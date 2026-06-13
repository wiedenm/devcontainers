Note that `docker-compose.yaml` and `application-test.properties` are only needed for "Docker-outside-of-Docker" mode,
where we need to make sure that the catalog and its backing services are attached to the same network. For
"Docker-in-Docker" mode (what's currently configured), we can use the catalog's usual configuration and compose file.
