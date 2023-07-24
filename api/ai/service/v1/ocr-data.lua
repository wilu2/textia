local cjson = require "cjson"
local cjson_decode = cjson.decode
local ngx_decode_base64 = ngx.decode_base64

local function get_ocr(file, file_type)
    local url = SYSTEM_CONF.ENV.OCR_ENGINE
    local host = SYSTEM_CONF.ENV.OCR_ENGINE_HOST
    local headers = {}
    if host and #host > 0 then headers["Host"] = host end
    local httpc = require("resty.http").new()
    httpc:set_timeouts(60 * 10 * 1000, 1000 * 60 * 10, 1000 * 60 * 10)
    local res, err = httpc:request_uri(url, {
        method = "POST",
        body = file,
        query = {
            file_name = "file." .. file_type,
            image_scale = 2,
            return_image = "true",
            rotate_image = "true",
            apply_stamp = "true",
            use_semantic_match = nil,
            merge_same_row = "false",
            recognize_edge = "true",
            remove_annot = "true",
            remove_edge = "true",
            remove_footnote = "true",
            remove_watermark = "true",
            remove_stamp = "false"
        },
        headers = headers
    })
    if not res or res.status ~= 200 then
        ngx.log(ngx.ERR, "get_ocr request failed: ", err, " body:", res.body)
        return
    end
    return res.body
end

local function main()
    local file_binary = ngx.req.get_body_data()
    local uri_args = ngx.req.get_uri_args()
    local file_type_support, file_type = nil, nil
    if uri_args.type then
        --从url中获取要抽取的文件的类型
        file_type_support = true
        if uri_args.type == "string" then
            file_type = "txt"
        elseif uri_args.type == "pdf" then
            file_type = "pdf"
        elseif uri_args.type == "word" then
            file_type = "docx"
        elseif uri_args.type == "image" then
            file_type = "jpg"
        end
    else
        --如果url参数中不指定类型，则使用自动判断类型（兼容第一版时，只支持word、pdf、image类型的抽取）
        file_type_support, file_type = lib.check_file_type(file_binary)
    end

    if not file_type_support then
        ngx.say(cjson.encode({code = 40303, message = "File type unsupport"}))
        return
    end
    local ocrBody = get_ocr(file_binary, file_type)
    if not ocrBody then
        ngx.say(cjson.encode({code = 90001, message = "get ocr failed."}))
        return
    end
    local ocr = cjson.decode(ocrBody)
    if ocr.code ~= 200 then
        ngx.say(ocrBody)
        return
    end
    if ocr.result.pages then
        for _, item in ipairs(ocr.result.pages) do
            item.areas = nil
            item.tables = nil
            item.lines = nil
        end
    end
    ngx.say(cjson.encode(ocr))
end

main()
