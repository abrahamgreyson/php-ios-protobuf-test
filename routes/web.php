<?php

use App\Protos\Event;
use App\Protos\Event\Common;
use App\Protos\Event\Payload;
use App\Protos\Event\Payload\Goods;
use App\Protos\Event\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Str;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/json', function () {
    return view('welcome');
});

Route::post('protobuf', function (Request $request) {
    $binary = match(true) {
        $request->hasFile('binary') => $request->file('binary')->getContent(),
        (bool) $request->getContent() => $request->getContent(),
        default => null
    };

    $eventProto = (new Event());
    $eventProto->mergeFromString($binary);
    return ($eventProto->serializeToJsonString());
})->withoutMiddleware('web');

Route::get('protobuf', function () {
    // Create a User object
    $userProto = (new User())
        ->setUserId(Str::uuid()->toString())
        ->setWebId(Str::uuid()->toString())
        ->setSsid(Str::uuid()->toString());
    $commonProto = (new Common())
        ->setAbVersion(['v2.3.4'])
        ->setAppVersion('v0.1.1')
        ->setClientIp('8.8.4.4')
        ->setDeviceBrand('Dami')
        ->setDeviceModel('D10.1.2.222')
        ->setLanguage('zh-TW')
        ->setLocCityId('1133')
        ->setLocCountryId('99')
        ->setLocProvinceId('11')
        ->setModuleName('hayaa')
        ->setNetworkCarrier('Skinny')
        ->setNetworkType('wifi')
        ->setOsName('DUI')
        ->setOsVersion('18.8')
        ->setPlatform('dos')
        ->setReferer('page/goods/index/')
        ->setResolution('4096 * 1222');
    $goodsProto = (new Goods())
        ->setId('12121211212');
    $payloadProto = (new Payload())
        ->setGoods([$goodsProto])
        ->setOrderId('998877665544');
    $eventProto = (new Event())
        ->setTime(now()->timestamp)
        ->setUser($userProto)
        ->setServerTime(now()->timestamp)
        ->setEventName(Str::random())
        ->setCommon($commonProto)
        ->setPayload($payloadProto);

    // 复制成列表
    // Serialize the User object to a binary string
    $userSerialized = $eventProto->serializeToString();

    // Set response headers for Protobuf
    return response($userSerialized)
        ->header('Content-Type', 'application/protobuf');
});
