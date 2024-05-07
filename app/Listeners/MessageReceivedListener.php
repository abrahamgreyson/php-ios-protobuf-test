<?php

namespace App\Listeners;

use App\Events\SendMessageEvent;
use App\Protos\Event;
use Laravel\Reverb\Events\MessageReceived;
use Laravel\Reverb\Loggers\Log;

use function base64_decode;
use function broadcast;

class MessageReceivedListener
{
    public function __construct()
    {
    }

    public function handle(MessageReceived $event): void
    {
        $message = json_decode($event->message);
        if ($message->event !== 'pusher:subscribe') {
            return;
        }
        $payload = $message->payload;
//        Log::info('Message received: ' . $payload);
        $event = new Event();
        $event->mergeFromString(base64_decode($payload));
        $json = json_decode($event->serializeToJsonString());
        broadcast(new SendMessageEvent($json))->toOthers();
    }
}
