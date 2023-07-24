#!/bin/bash
docker rm -f textin-extraction
docker build -t textin-extraction:v1 -f Dockerfile .
docker run --name textin-extraction -v /usr/code/textin-extraction-service/api:/usr/local/openresty/nginx/lua/api -p 8093:80 -it -d textin-extraction:v1
docker logs -f textin-extraction