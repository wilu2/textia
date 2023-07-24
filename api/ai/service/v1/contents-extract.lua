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

local function contents_extract(ocr, keys)
    local url = SYSTEM_CONF.ENV.NLP_ENGINE
    local host = SYSTEM_CONF.ENV.NLP_ENGINE_HOST
    local headers = {}
    if host and #host > 0 then headers["Host"] = host end
    local httpc = require("resty.http").new()
    httpc:set_timeouts(60 * 10 * 1000, 1000 * 60 * 10, 1000 * 60 * 10)
    local res, err = httpc:request_uri(url, {
        method = "POST",
        body = cjson.encode({
            data = {ocr_data = ocr},
            questions = table.concat(keys, "&")
        }),
        headers = headers
    })
    if not res or res.status ~= 200 then
        ngx.log(ngx.ERR, "contents_extract request failed: ", err, " body:",
                res.body)
        return
    end
    return res.body
end

local function main()
    local body = ngx.req.get_body_data()
    if not body then
        ngx.say(cjson.encode({code = 40303, message = "File type unsupport"}))
        return
    end
    local data = cjson_decode(ngx.req.get_body_data())
    local file_type_support, file_type, file_binary = nil, nil, nil
    if data.type then
        --如果指定了type，则直接使用type去做类型判断
        file_type_support = true
        file_binary = ngx_decode_base64(data.file)
        if data.type == "string" then
            file_type = "txt"
            file_binary = data.file
        elseif data.type == "pdf" then
            file_type = "pdf"
        elseif data.type == "word" then
            file_type = "docx"
        elseif data.type == "image" then
            file_type = "jpg"
        end
    else
        -- 没有type时，使用自动判断类型（兼容第一版时，只支持word、pdf、image类型的抽取）
        file_binary = ngx_decode_base64(data.file)
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

    for _, item in ipairs(ocr.result.pages) do item.angle = 0 end

    local extract_body = contents_extract(ocr.result.pages, data.keys)
    if not extract_body then
        ngx.say(cjson.encode({code = 90001, message = "extract failed."}))
        return
    end
    local extract = cjson.decode(extract_body)

    if extract.code == 500 and extract.message == "All of pages have no contents." then
        cjson.encode_empty_table_as_object(false)
        extract = {
            code = 200,
            message = "success",
            result = {
                item_list = {},
                pages = {}
            }
        }
        ngx.say(cjson.encode(extract))
        return
    end

    if extract.code == 200 and ocr.result.pages then
        for _, item in ipairs(ocr.result.pages) do
            item.areas = nil
            item.tables = nil
            item.lines = nil
        end
        extract.result.pages = ocr.result.pages
    end
    ngx.say(cjson.encode(extract))
end

main()
