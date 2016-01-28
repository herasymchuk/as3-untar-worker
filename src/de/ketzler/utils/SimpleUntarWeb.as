/*
 Copyright (c) 2012, Christoph Ketzler
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


package de.ketzler.utils {
import com.trembit.untar.IUntar;

import de.ketzler.utils.untar.UntarFileInfo;
import de.ketzler.utils.untar.UntarHeaderBlock;

import flash.events.EventDispatcher;
import flash.events.IEventDispatcher;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

public class SimpleUntarWeb extends EventDispatcher implements IUntar {

	public static var BLOCK_SIZE:uint = 512;
	public static const CODE_PAGE:String = "iso-8859-1";

	private var _source:ByteArray;
	private var allFiles:Vector.<UntarFileInfo> = new Vector.<UntarFileInfo>();
	private var allDirectories:Vector.<UntarFileInfo> = new Vector.<UntarFileInfo>();
	private var tempFileInfo:UntarFileInfo;
	private var availBytes:uint;
	private var walkerPosition:uint;
	private var tempBA:ByteArray;
	private var _extractedData:Dictionary; //ByteArray

	public function SimpleUntarWeb(target:IEventDispatcher = null) {
		super(target);
	}

	public function get source():ByteArray {
		return _source;
	}

	public function set source(source:ByteArray):void {
		_source = source;
		if (_source) {
			getAllFilenames();
		}
	}

	public function extract():* {
		_extractedData = new Dictionary();
		createFiles();
		return _extractedData;
	}

	private function createFiles():void {
		for (var i:int = 0; i < allFiles.length; i++) {
			tempFileInfo = allFiles[i];

			availBytes = tempFileInfo.size;
			walkerPosition = tempFileInfo.startPosition;

			// last one
			tempBA = new ByteArray();
			_source.position = walkerPosition;
			_source.readBytes(tempBA, 0, availBytes);

			_extractedData[allFiles[i].filename] = tempBA;
		}
	}

	private function getAllFilenames():void {
		allFiles = new Vector.<UntarFileInfo>();
		allDirectories = new Vector.<UntarFileInfo>();
		var currentPosition:int = 0;
		var hasNewBlock:Boolean = true;
		var savedLongFileName:String = '';
		while (hasNewBlock) {
			var bytes:ByteArray = new ByteArray();
			_source.position = currentPosition;
			_source.readBytes(bytes, 0, BLOCK_SIZE);

			var header:UntarHeaderBlock = new UntarHeaderBlock();
			header.byteArray = bytes;
			tempFileInfo = new UntarFileInfo();
			// wir haben einen header und machen nun eine FileInfo
			switch (header.type) {
				case UntarHeaderBlock.TYPE_NULL:
					hasNewBlock = false;
					break;

				case UntarHeaderBlock.TYPE_LONGFILENAME:
					_source.position = currentPosition + BLOCK_SIZE;
					savedLongFileName = _source.readMultiByte(header.size, CODE_PAGE);
					break;

				case UntarHeaderBlock.TYPE_FILE:
					tempFileInfo.startPosition = currentPosition + BLOCK_SIZE;
					tempFileInfo.size = header.size;
					if (savedLongFileName != '') {
						tempFileInfo.filename = savedLongFileName;
					} else {
						tempFileInfo.filename = header.filename;
					}
					allFiles.push(tempFileInfo);
					savedLongFileName = '';
					break;

				case UntarHeaderBlock.TYPE_DIR:
					if (savedLongFileName != '') {
						tempFileInfo.filename = savedLongFileName;
					} else {
						tempFileInfo.filename = header.filename;
					}
					allDirectories.push(tempFileInfo);
					savedLongFileName = '';
					break;
			}

			currentPosition = currentPosition + (header.size_blocks * BLOCK_SIZE) + BLOCK_SIZE;

			if ((_source.bytesAvailable - tempFileInfo.size) < 512) {
				hasNewBlock = false;
			}
		}
	}

	public function set sourcePath(value:String):void {
		throw new Error("Unsupported method");
	}

	public function set targetPath(value:String):void {
		throw new Error("Unsupported method");
	}
}
}
