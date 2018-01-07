package org.cocos2dx.thirdparty;

//第三方平台配置信息
public class ThirdDefine {
	//微信配置
	public static final int  Weixin_Config = 0;
	//分享配置
	public static final int Weixin_shareConfig = 1;
	//微信分享
	public static final int Weixin_Share = 2;
	//微信支付
	public static final int Weixin_Pay = 3;
	//微信登录
	public static final int Weixin_login = 4;
	//支付宝ID配置
	public static final int ZFB_Config = 5;
	//支付宝支付
	public static final int ZFB_Pay = 6;
	
	//微信配置
	public static boolean  bConfigWeChat  = false;
	//appid
	public static String  WeixinAppID  = "";
	//secret
	public static String WeixinAppSecret = "";	
	//商户id
	public static String WeixinPartnerid = "";	
	//支付密钥
	public static String WeixinPayKey = "";
	
	//分享链接
	public static String  ShareURL = "http://jd.foxuc.net";
	//分享标题
	public static String   ShareTitle = "经典大厅";
	//分享内容
	public static String   ShareContent = "经典大厅http://jd.foxuc.net";
	
	//支付宝
	public static boolean bConfigAlipay = false;
	//合作身份者id，以2088开头的16位纯数字
    public static String ZFBPARTNER = "";
    //收款支付宝账号
    public static String ZFBSELLER = "";
    //商户私钥，自助生成，pkcs8格式
    public static String ZFBRSA_PRIVATE = "";
    //验证地址
    public static String ZFBNOTIFY_URL = "";
    
    //竣付通数据
    public static boolean bConfigJFT = false;
    public static String JFTKey = "";
    public static String JFTVector = "";
    public static String JFTAppID = "";
    
    //权限请求定义
    public static final int THIRD_PER_REQUEST = 10001;
    
    //支付结构
    public static class PayParam
    {
    	public String sOrderId;
    	public String sProductName;
    	public float fPrice;
    	public int nCount;
    }
    
    //自定义分享结构
    public static class ShareParam
    {
    	public int nTarget 			= 0;			// 分享平台
    	public String sTitle 		= "";			// 分享标题
    	public String sContent 		= "";			// 分享内容
    	public String sTargetURL 	= "";			// 分享链接
    	public String sMedia 		= "";			// 分享资源
    	public boolean bImageOnly   = false;		// 纯图分享
    }
}
