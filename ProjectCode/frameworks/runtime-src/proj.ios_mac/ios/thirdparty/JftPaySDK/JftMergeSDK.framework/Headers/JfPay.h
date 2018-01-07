//
//  JftSDK.h
//  Jft_SDK
//
//  Created by dyj on 16/2/26.
//  Copyright © 2016年 HLZ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class JftPayModel;
@protocol JftSDKPayDelegate <NSObject>

@optional
- (void)getPayTypeListSuccess:(NSArray *)list;//获取支付列表成功
- (void)getPayTypeListFailure:(NSString *)message;//获取支付列表失败
- (void)jftPaySuccess;//支付成功
- (void)jftPayFailure:(NSString *)message;//支付失败
- (void)jftPayResult:(NSString *)result;//支付结果
- (void)thirdAppOpenSucceed;//应用打开成功
- (void)thirdAppOpenFailure;//应用打开失败

//pcsoama
- (void)openWebSuccessed;
- (void)openWebFailer:(NSString *)failer;
@end
@interface JfPay : NSObject
/**
 *  获取支付列表
 *  @param token      商家App从自己服务器获得带订单token
 *  @param key        加密Key,预留参数
 *  @param iv         加密向量,预留参数
 *  @param delegate   指定代理对象
 */
+ (void) getPayTypeList:(NSString *)token key:(NSString *)key iv:(NSString *)iv serviceType:(NSString *)type appId:(NSString *)appId delegate:(id<JftSDKPayDelegate>)delegate;
/**
 *  调取支付方法
 *
 *  @param token      商家App从自己服务器获得带订单token
 *  @param payTypeId  支付方式id
 *  @param key        加密Key,预留参数
 *  @param iv         加密向量,预留参数
 *  @param delegate   指定代理对象
 */

/**
 *  返回应用后的回调
 */
+ (void) paySDKWillEnterForeground; // 获取支付结果使用。
/**
 *  Log 输出开关 (默认关闭)
 *
 *  @param flag 是否开启
 */
+ (void)setLogEnable:(BOOL)flag;
/**
 * Paymodel 支付配置参数的
 * delegate 指定代理
 */

+ (void)payByJftPayModel:(JftPayModel *)payModel delegate:(id<JftSDKPayDelegate>)delegate;

@end
