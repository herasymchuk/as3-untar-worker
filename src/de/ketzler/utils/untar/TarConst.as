package de.ketzler.utils.untar {
public class TarConst {
    public static var BLOCK_SIZE:uint = 512;
    public static var BLOCK_SIZE_FACTOR : Number = 1 / 512;
    public static var SAVEDBYTES_AT_ONCE : uint = 4*1024*1024; // 4 MB
    public static const CODE_PAGE : String = "iso-8859-1";
}
}
