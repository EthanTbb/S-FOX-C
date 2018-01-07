//
//  ThirdParty.h
//  GloryProject
//
//  Created by zhong on 16/9/8.
//
//

#ifndef ThirdParty_h
#define ThirdParty_h

#import <Foundation/Foundation.h>
#import "ThirdDefine.h"
#import "ThirdProtocol.h"
#import "ThirdData.h"

#import "UMSocial.h"
#import "WXApi.h"
#import <JftMergeSDK/JfPay.h>

// 高德定位服务
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <MAMapKit/MAMapKit.h>

// 内购
#include "IAP/IOSiAP_Bridge.h"

@interface ThirdParty: NSObject <UMSocialUIDelegate, WXApiDelegate, JftSDKPayDelegate, AMapLocationManagerDelegate>
{
    //平台
    NSMutableArray* _platformArray;
    //友盟平台
    NSDictionary* _umDict;
    //友盟分享平台
    NSArray* _umSharePlat;
    //分享配置
    ShareConfig *_share;
    //微信配置
    WeChatConfig *_wechat;
    //支付宝配置
    AliPayConfig *_alipay;
    //竣付通配置
    JftPayConfig *_jftpay;
    
    //支付平台
    NSString* _payPlat;
    
    BOOL m_bConfigAmap;
    
    IOSiAP_Bridge m_iosiap;
}
@property (nonatomic, assign) id <ShareDelegate> shareDelegate;
@property (nonatomic, assign) id <PayDelegate> payDelegate;
@property (nonatomic, assign) id <LocationDelegate> locationDelegate;
@property (nonatomic, strong) AMapLocationManager *locationMgr;
@property (nonatomic, copy) AMapLocatingCompletionBlock completionBlock;

+ (ThirdParty*) getInstance;
+ (void) destroy;

//初始化
- (void) defaultInit;

//获取平台
- (NSString*) getPlatform: (int) nidx;

//获取分享默认配置
- (ShareConfig*) getDefaultShareConfig;

//
- (BOOL) openURL:(NSURL *)url;

//
- (void) willEnterForegound;

//配置第三方平台数据
- (void) configThirdParty:(NSString*)plat platConfig:(NSDictionary*)config;

//配置分享数据
- (void) configSocialShare:(NSDictionary*) config;

//第三方登陆
- (void) thirdPartyLogin:(NSString*)plat delegate:(id<LoginDelegate>) delegate;

//分享
- (void) openShare:(id<ShareDelegate>) delegate share:(tagShareParam) param;

//指定平台分享
- (void) targetShare:(id<ShareDelegate>) delegate share:(tagShareParam) param;

//支付
- (void) thirdPartyPay:(NSString*)plat delegate:(id<PayDelegate>)delegate payparam:(NSDictionary*)payparam;

//获取竣付通支付列表
- (void) getPayList:(NSString*)token delegate:(id<PayDelegate>)delegate;

// 判断是否安装
- (BOOL) isPlatformInstalled:(NSString *)plat;

// 请求单次定位
- (void) requestLocation: (id<LocationDelegate>)delegate;

// 根据经纬度计算距离
- (NSString*) metersBetweenLocation: (NSDictionary*)loParam;
@end
#endif /* ThirdParty_h */
