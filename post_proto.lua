---
--- Created by AbrahamGreyson.
--- DateTime: 2024/5/6 下午3:26
---

-- 读取 protobuf 文件内容，用作请求的 body
local file = io.open("dummy_event.protobuf", "rb")
assert(file, "Failed to open protobuf file.")
local payload = file:read("*all")
file:close()

-- 设置请求方法、头部、和 body
wrk.method = "POST"
wrk.headers["Content-Type"] = "application/octet-stream"
wrk.body = payload

local counter = 1
local threads = {}

-- 定义一个函数来将字节转换为人类友好的格式
function format_bytes(bytes)
    local units = {"B", "KB", "MB", "GB", "TB"}
    for i, unit in ipairs(units) do
        if bytes < 1024 then
            return string.format("%.2f %s", bytes, unit)
        end
        bytes = bytes / 1024
    end
end

function setup(thread)
    -- 给每个线程设置一个 id 参数
    thread:set("id", counter)
    -- 将线程添加到 table 中
    table.insert(threads, thread)
    counter = counter + 1
end

function init(args)
    -- 初始化两个参数，每个线程都有独立的 requests、responses 参数
    requests  = 0
    responses = 0
    bytes_sent = 0

    -- 打印线程被创建的消息，打印完后，线程正式启动运行
    --local msg = "thread %d created"
    --print(msg:format(id))
end

function request()
    -- 每发起一次请求 +1
    requests = requests + 1
    -- 增加发送的数据量
    bytes_sent = bytes_sent + #wrk.body
    return wrk.request()
end

function response(status, headers, body)
    -- 每得到一次请求的响应 +1
    responses = responses + 1
end

function done(summary, latency, requests)
    -- 初始化总的 bytes_sent 值为 0
    local total_bytes_sent = 0
    -- 循环线程 table
    for index, thread in ipairs(threads) do
        local id        = thread:get("id")
        local requests  = thread:get("requests")
        local responses = thread:get("responses")
        local bytes_sent = thread:get("bytes_sent")
        local msg = "thread %d made %d requests and got %d responses, sent %s data"
        -- 打印每个线程发起了多少个请求，得到了多少次响应，发送了多少数据
        print(msg:format(id, requests, responses, format_bytes(bytes_sent)))
        -- 将每个线程的 bytes_sent 加入到总的 bytes_sent 中
        total_bytes_sent = total_bytes_sent + bytes_sent
    end
    print("Total data sent: " .. format_bytes(total_bytes_sent))
end
