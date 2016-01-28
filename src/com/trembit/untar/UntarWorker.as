package com.trembit.untar {

import de.ketzler.utils.SimpleUntarMobile;
import de.ketzler.utils.SimpleUntarWeb;

import flash.display.Sprite;
import flash.events.Event;
import flash.net.registerClassAlias;
import flash.system.MessageChannel;
import flash.system.Worker;
import flash.utils.Dictionary;

public class UntarWorker extends Sprite {

    public function UntarWorker() {
        if(!Worker.current.isPrimordial)
        {
            registerClassAlias("flash.utils.Dictionary", Dictionary);
            //registerClassAlias("com.trembit.untar.ItemInfoVO", ItemInfoVO);

            mainToWorkerSourceChannel = Worker.current.getSharedProperty("mainToWorkerSourceChannel");
            workerToMainResultChannel = Worker.current.getSharedProperty("workerToMainResultChannel");
            isWeb = Worker.current.getSharedProperty("isWeb");

            mainToWorkerSourceChannel.addEventListener(Event.CHANNEL_MESSAGE, onSource);
        }
    }

    private var isWeb:Boolean;
    private var mainToWorkerSourceChannel:MessageChannel;
    private var workerToMainResultChannel:MessageChannel;

    private function onSource(event:Event):void {
        //var item:ItemInfoVO = mainToWorkerSourceChannel.receive() as ItemInfoVO;
        var item:Object = mainToWorkerSourceChannel.receive();
        if (item) {
            var untar:IUntar = isWeb ? new SimpleUntarWeb() : new SimpleUntarMobile();
            if (isWeb) {
                untar.source = item.source;
            } else {
                untar.sourcePath = item.source;
                untar.targetPath = item.targetPath;
            }
            try {
                item.extracted = untar.extract();
                workerToMainResultChannel.send(item);
            } catch (e:Error) {
                workerToMainResultChannel.send(null);
            }
        }
    }
}
}
