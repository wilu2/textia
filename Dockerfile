FROM openresty/openresty:alpine-fat
RUN mkdir /usr/project && mkdir /usr/project/nginx
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone
RUN set -eux && sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN  apk update && apk add libuuid
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-http

# OCR解析引擎地址
# ENV OCR_ENGINE="http://ocr-api-sandbox.ccint.com/ai/service/v1/doc_robot_ocr"
# ENV OCR_ENGINE_HOST=
# NLP信息提取引擎地址
# ENV NLP_ENGINE="http://ocr-api-sandbox.ccint.com/ai/service/v1/contract_extraction_customize"
# ENV NLP_ENGINE_HOST=xxx

COPY . /usr/local/openresty/nginx/lua/
COPY ./conf/nginx.conf /etc/nginx/conf.d/default.conf