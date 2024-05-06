---
--- Created by abrahamgreyson.
--- DateTime: 2024/5/6 下午3:26
---

-- wrk script, post method with content-type header and json string body

wrk.method = "POST"
wrk.headers["Content-Type"] = "application/json"
-- multiple line
wrk.body = [[
{
	"eventName": "W3Gt8UJYtzEwS4Mn",
	"time": "1714568118",
	"serverTime": "1714568118",
	"user": {
		"userId": "9df85b22-cf7a-4a6c-bc17-a0c69d738728",
		"webId": "180eb18b-5a34-4ad1-a8a5-79ed5d1da3ea",
		"ssid": "99395ee9-0a5f-4aa0-b48a-38cbac323e01"
	},
	"common": {
		"appVersion": "v0.1.1",
		"deviceModel": "D10.1.2.222",
		"language": "zh-TW",
		"resolution": "4096 * 1222",
		"platform": "dos",
		"locCountryId": "99",
		"locProvinceId": "11",
		"locCityId": "1133",
		"clientIp": "8.8.4.4",
		"osVersion": "18.8",
		"networkCarrier": "Skinny",
		"deviceBrand": "Dami",
		"osName": "DUI",
		"networkType": "wifi",
		"abVersion": [
			"v2.3.4"
		],
		"referer": "page/goods/index/",
		"moduleName": "hayaa"
	},
	"payload": {
		"goods": [
			{
				"id": "12121211212"
			}
		],
		"orderId": "998877665544"
	},
	"key": "value"
}
]];


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

