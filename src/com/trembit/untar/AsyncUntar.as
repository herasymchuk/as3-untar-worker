package com.trembit.untar {
import flash.display.Loader;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.net.URLRequest;
import flash.net.registerClassAlias;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.system.MessageChannel;
import flash.system.Worker;
import flash.system.WorkerDomain;
import flash.utils.Dictionary;
import flash.utils.getTimer;

public class AsyncUntar extends EventDispatcher {

    protected var worker:Worker;
    private var isWeb:Boolean;
    private var workerToMainResultChannel:MessageChannel;
    private var mainToWorkerSourceChannel:MessageChannel;
    private var processingItems:Dictionary = new Dictionary();
    //private var items:Vector.<ItemInfoVO> = new <ItemInfoVO>[];
    private var items:Vector.<Object> = new <Object>[];
    private var loading:Boolean;
    private var pendingExtract:Boolean;

    public function AsyncUntar(workerSWFPath:String, isWeb:Boolean = false) {
        super();
        this.isWeb = isWeb;

        registerClassAlias("flash.utils.Dictionary", Dictionary);
        //registerClassAlias("com.trembit.untar.ItemInfoVO", ItemInfoVO);

        var _urlRequest:URLRequest = new URLRequest(workerSWFPath);
        var loader:Loader = new Loader();
        var lc:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
        loader.load(_urlRequest, isWeb ? null : lc);
        loading = true;
    }

    public function addItem(item:ItemInfoVO, completeHandler:Function):void {
        //According to bug in iOS we don't allowed to use custom class both in main and worker class
        //So we can't use ItemInfoVO, we use Object class instead
        //This is known issue that is mentioned in the AIR 20 Release notes:
        //[iOS] Crash if Class used in Main and Background worker is a CustomClass (4068748)
        //https://forums.adobe.com/thread/2028681?start=0&tstart=0
        processingItems[item.uid] = completeHandler;
        items.push(item);
    }

    public function extract():void {
        if(loading) {
            pendingExtract = true;
        } else {
            while (items.length) {
                mainToWorkerSourceChannel.send(items.shift());
            }
        }
    }

    private function errorHandler(event:IOErrorEvent):void {
        dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, event.toString()));
    }

    private function completeHandler(e:Event):void {
        worker = WorkerDomain.current.createWorker(e.target.bytes, true);

        workerToMainResultChannel = worker.createMessageChannel(Worker.current);
        workerToMainResultChannel.addEventListener(Event.CHANNEL_MESSAGE, onResult);

        mainToWorkerSourceChannel = Worker.current.createMessageChannel(worker);

        worker.setSharedProperty("workerToMainResultChannel", workerToMainResultChannel);
        worker.setSharedProperty("mainToWorkerSourceChannel", mainToWorkerSourceChannel);
        worker.setSharedProperty("isWeb", isWeb);
        worker.start();
        loading = false;
        if(pendingExtract) {
            pendingExtract = false;
            extract();
        }
    }

    private function onResult(event:Event):void {
        //var result:ItemInfoVO = workerToMainResultChannel.receive() as ItemInfoVO;
        var result:Object = workerToMainResultChannel.receive();
        if (result) {
            var completeHandler:Function = processingItems[result.uid] as Function;
            if (null != completeHandler) {
                completeHandler(result.extracted);
                delete processingItems[result.uid];
            }
            dispatchEvent(new Event(Event.COMPLETE));
        } else {
            dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
        }
    }
}
}
