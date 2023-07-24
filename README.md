# textin-extraction-service

## Textin-nlp-信息抽取服务

根据现有引擎接口
* 解析引擎 https://gitlab.intsig.net/dochub/openapi/-/blob/contract-ie/ContractIE/1.0.0.openapi.document.yaml
* 抽取引擎 https://gitlab.intsig.net/dochub/openapi/-/blob/contract-ie/ContractIE/1.0.0.openapi.yaml

进行服务整合，Textin后端将上述两个引擎整合为一个服务，并将该服务上线到机器人市场
## 入参
* 1个文件
* 抽取的key
* 文件类型（word、pdf、image、string）
## 出参：
* 文件的每页图片
* 抽取结果
* 整合服务的内部处理逻辑

## 处理流程
* 将接受到的文件送到解析引擎，获取图片与OCR信息
* 将OCR信息送入到抽取引擎，获取抽取结果


## 可能存在的问题
* 解析引擎的解析速度
* 解析引擎的结果需要缓存到内存，可能对服务器的内存要求较高