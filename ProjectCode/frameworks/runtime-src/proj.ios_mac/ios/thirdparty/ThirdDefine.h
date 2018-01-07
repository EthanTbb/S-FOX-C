//
//  ThirdDefine.h
//  GloryProject
//
//  Created by zhong on 16/9/8.
//
//

#ifndef ThirdDefine_h
#define ThirdDefine_h
#import <Foundation/Foundation.h>

/*enum PLATFORM
{
    INVALIDPLAT = -1,
    WECHAT = 0,
    WECHAT_CIRCLE,
    ALIPAY,
    JFT,
};*/

NSString *const INVALIDPLAT = @"third_INVALIDPLAT";

// 微信
NSString *const WECHAT = @"third_WECHAT";

// 朋友圈
NSString *const WECHAT_CIRCLE = @"third_WECHAT_CIRCLE";

// 支付宝
NSString *const ALIPAY = @"third_ALIPAY";

// 骏付通
NSString *const JFT = @"third_JFT";

// 高德地图
NSString *const AMAP = @"thrid_AMAP";

// IAP
NSString *const IOSIAP = @"ios_IAP";

// SMS
NSString *const SMS = @"ios_SMS";

//分享参数
struct tagShareParam
{
    //分享平台
    int nTarget;
    //分享标题
    NSString *sTitle;
    //分享内容
    NSString *sContent;
    //分享链接
    NSString *sTargetURL;
    //分享资源
    NSString *sMedia;
    //纯图模式
    BOOL bImageOnly;
};

//支付参数
struct tagPayParam
{
    //
    NSString *sOrderId;
    //
    NSString *sProductName;
    //
    float fPrice;
    //
    int nCount;
};
#endif /* ThirdDefine_h */
