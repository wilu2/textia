SYSTEM_CONF = {
    ENV = {
        OCR_ENGINE = os.getenv("OCR_ENGINE"),
        OCR_ENGINE_HOST = os.getenv("OCR_ENGINE_HOST"),
        NLP_ENGINE = os.getenv("NLP_ENGINE"),
        NLP_ENGINE_HOST = os.getenv("NLP_ENGINE_HOST")
    }
}

lib = {}

lib.file_type_helper = require "file_type"

lib.table_is_contain = function(table, ...)
    if not table then
        return false
    end
    local args = {...}
    for j = 1, #args do
        for i = 1, #table do
            if table[i] == args[j] then
                return true
            end
        end
    end
    return false
end

lib.check_file_type = function (file)
    local input_file_type = {"PDF", "IMAGE"}
    local image_type = {"png", "jpeg", "bmp"}
    local pdf_type = {"pdf"}
    local ok, type, err = pcall(lib.file_type_helper.get_file_type,file)
    if not ok then
        return false, nil
    end
    --## 由于office word 文件类型难以判断，所以如果文件类型不是图片，也不是pdf时，默认时word文件
    if not type then return true, "doc" end
    for _, v in ipairs(input_file_type) do
        if (v == "IMAGE" and lib.table_is_contain(image_type, type)) or
            (v == "PDF" and lib.table_is_contain(pdf_type, type)) then
            return true, type
        end
    end
    return false, nil
end

-- 支持跨域
function lib.cors()
    ngx.header['Access-Control-Max-Age'] = '86400' -- https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/Access-Control-Max-Age
    ngx.header['Access-Control-Allow-Origin'] = '*'
    ngx.header['Access-Control-Allow-Headers'] = 'Content-Type,token,No-Cache,Pragma,Cache-Control,X-Requested-With,x-ti-app-id,x-ti-secret-code'
    -- ngx.header['Access-Control-Allow-Methods'] = 'POST,GET,PUT,DELETE,OPTIONS,HEAD'
    if ngx.var.request_method == 'OPTIONS' or ngx.var.request_method == ngx.HTTP_OPTIONS then
        ngx.header['Access-Control-Allow-Methods'] = 'POST,GET,PUT,DELETE,OPTIONS,HEAD'
        ngx.exit(ngx.HTTP_OK)
    end
end
