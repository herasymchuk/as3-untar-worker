package com.trembit.untar {
import flash.utils.ByteArray;

public interface IUntar {
	function set sourcePath(value:String):void;
	function set targetPath(value:String):void;
	function set source(source:ByteArray):void;

	function extract():*;

}
}
