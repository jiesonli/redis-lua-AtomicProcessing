--字符串分割函数
--传入字符串和分隔符，返回分割后的table
local fun = {}
local reg = '(%d+)' --这里用数字举个例子，用于匹配传递过来的是什么类型的数据
function fun.split(delimiter,str)
    if str == nil or str == '' or delimiter == nil then
        return nil
    end
    
    local afterSplitResult = {}
    --匹配传递进来的后缀key,
    for match in string.gmatch(str,reg..delimiter.."*") do
        table.insert(afterSplitResult, match)
    end
    return afterSplitResult
end

local mainPrefix = {'mid_'} --主数据的前缀，就是传递进来分割后组合获取的数据
--用于后面根据查询主数据后，根据其余字段获取其余数据一起返回，这个脚本就是为了实现这点
local subPrefix = {{field = 'v_spu_id',prefix = 'spu_id_'},{field = 'brand_id',prefix = 'brand_id_'}}
local result = {}
local maxKeyLen = 10 --表示一次性可以查询多少个key
local splitData = fun.split('_',KEYS[1]) --传递过来的key

if #splitData > 10 then
    return nil --自己定义返回数据
end

if splitData ~= nil then
    for indexKey,value in ipairs(splitData) do
        local key = mainPrefix[1]..value --组合主数据的key
        local tmp = {}
        if redis.call("EXISTS", key) == 1 then
            local start = redis.call('get',key)
            table.insert(tmp,start)
            start = cjson.decode(start)
            for i = 1,#subPrefix do 
                local data = start[subPrefix[i].field]      --要查询的字段的数据
                local fieldKey  = subPrefix[i].prefix..data --组合查询的字段的key
                if redis.call("EXISTS", fieldKey) == 1 then
                    local fieldData = redis.call('get',fieldKey)
                    table.insert(tmp,fieldData)
                else
                    table.insert(tmp,'[]')
                end
            end
            table.insert(result,tmp)
        else
            table.insert(result,'[]')
        end
    end
    return result
else 
    return nil
end
