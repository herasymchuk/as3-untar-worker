package com.trembit.untar {
import flash.errors.IOError;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import org.flexunit.asserts.assertFalse;
import org.flexunit.asserts.assertNotNull;
import org.flexunit.asserts.assertTrue;
import org.flexunit.asserts.fail;
import org.flexunit.async.Async;

public class AsyncUntarTest extends EventDispatcher {

    private static const TIMEOUT:int = 5000;

    private static const WORKER_CLASS_NAME:String = "UntarWorker.swf";

    [Test(async)]
    public function AsyncUntarMobileTest():void {
        var untar:AsyncUntar = new AsyncUntar(WORKER_CLASS_NAME);
        var source:File = File.documentsDirectory.resolvePath("example.tar");
        assertNotNull(source, "Source file doesn't exist!");
        var destination:File = File.documentsDirectory.resolvePath("example");
        if (!destination.exists) {
            destination.createDirectory();
        }
        untar.addItem(new ItemInfoVO(source.nativePath, destination.nativePath), function (...res):void {
            var files:Array = destination.getDirectoryListing();
            assertTrue(files && files.length > 0);
            dispatchEvent(new Event(Event.COMPLETE));
        });

        untar.addEventListener(ErrorEvent.ERROR, onError);

        untar.extract();

        Async.proceedOnEvent(this, this, Event.COMPLETE, TIMEOUT);
    }

    [Test(async)]
    public function AsyncUntarWebTest():void {
        var untar:AsyncUntar = new AsyncUntar(WORKER_CLASS_NAME, true);
        var source:File = File.documentsDirectory.resolvePath("example.tar");
        untar.addItem(new ItemInfoVO(readBytesFromFile(source)), function (res:Dictionary):void {
            assertNotNull(res);
            var empty:Boolean = true;
            for (var name:String in res) {
                empty = false;
            }
            assertFalse(empty);
            dispatchEvent(new Event(Event.COMPLETE));
        });

        untar.addEventListener(ErrorEvent.ERROR, onError);

        untar.extract();

        Async.proceedOnEvent(this, this, Event.COMPLETE, TIMEOUT);
    }

    public function readBytesFromFile(file:File):ByteArray {
        var bytes:ByteArray;
        if (file.exists) {
            try {
                bytes = new ByteArray();
                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.READ);
                stream.readBytes(bytes);
            } catch (e:IOError) {
                bytes = null;
            } catch (e:SecurityError) {
                bytes = null;
            } finally {
                stream.close();
            }
        }
        return bytes;
    }

    private function onError(event:ErrorEvent):void {
        fail(event.toString());
    }
}
}
