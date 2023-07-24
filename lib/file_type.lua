


local M = { _NAME = "filetype" }
local TYPE_MAP = {
    ["^GIF8[7,9]a"]          		    	= "gif",
    ["^%%PDF-"]                             = "pdf",
    ["^\255\216"]                           = "jpeg",
    ["^\137PNG\13\10\26\10"]                = "png",
    ["^BM"]                                 = "bmp",
}

-- This is empty because each option's defaults are handled individually
-- by the modules for the specific file format.  This is here just to avoid
-- creating a new empty table every time.  It should never change.
local DEFAULT_OPTIONS = {}

function M.file_type (filename, options)
    options = options or DEFAULT_OPTIONS

    local filetype = type(filename)
    local file, closefile, origoffset
    if filetype == "string" or filetype == "number" then
        file, err = io.open(filename, "rb")
        if not file then
            return nil, "error opening file '" .. filename .. "': " .. err
        end
        closefile = true
    else
        file, closefile = filename, false
        origoffset = file:seek()
    end

    local header = file:read(2560)
    -- ngx.log(ngx.ERR,header)
    if not header then return nil, "file is empty" end
    local ok, err = file:seek("set")
    if not ok then return nil, "error seeking in file: " .. err end

    for pattern, format in pairs(TYPE_MAP) do
        if header:find(pattern) then
            -- local sizefunc = require("imagesize.format." .. format)
            -- local x, y, id = sizefunc(file, options)
            if closefile then file:close() end
            if origoffset then file:seek("set", origoffset) end
            return format
        end
    end

    if closefile then file:close() end
    if origoffset then file:seek("set", origoffset) end
    return nil, "file format not recognized"
end

local StringFile = {}
StringFile.__index = StringFile

function StringFile:read (bytes)
    assert(type(bytes) == "number",
           "this mock file handle can only read a number of bytes")
    if self._offset >= self._data:len() then return nil end
    local buf = self._data:sub(self._offset + 1, self._offset + bytes)
    self._offset = self._offset + bytes
    return buf
end

function StringFile:seek (whence, offset)
    if not whence and not offset then return self._offset end
    assert(whence == "set", "this mock file handle can only seek with 'set'")
    offset = offset or 0
    self._offset = offset
    return offset
end

local function _line_iter (self)
    if self._offset >= self._data:len() then return nil end
    local _, endp, line = self._data:find("([^\n]*)\n?", self._offset + 1)
    self._offset = endp
    return line
end
function StringFile:lines () return _line_iter, self end

function M.get_file_type (s, options)
    local file = setmetatable({
        _data = s,
        _offset = 0,
    }, StringFile)
    return M.file_type(file, options)
end

return M