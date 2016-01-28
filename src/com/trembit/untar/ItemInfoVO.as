package com.trembit.untar {
import flash.utils.Dictionary;
import flash.utils.getTimer;

public class ItemInfoVO {
    public function ItemInfoVO(source:* = null, targetPath:String = null) {
        this.source = source;
        this.targetPath = targetPath;
        if (source is String) {
            uid = source;
        } else {
            uid = getTimer().toString();
        }
    }
    public var source:*;
    public var targetPath:String;
    public var extracted:Dictionary;
    public var uid:String;
}
}
