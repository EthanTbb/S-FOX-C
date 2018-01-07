//
//  ThirdData.cpp
//  GloryProject
//
//  Created by zhong on 16/9/9.
//
//

#import "ThirdData.h"

@implementation ShareConfig

@synthesize Configed = _Configed;
@synthesize AppKey = _AppKey;
@synthesize ShareUrl = _ShareUrl;
@synthesize ShareTitle = _ShareTitle;
@synthesize ShareContent = _ShareContent;
@synthesize ShareMediaPath = _ShareMediaPath;

@end

@implementation WeChatConfig

@synthesize Configed = _Configed;
@synthesize WeChatAppID = _WeChatAppID;
@synthesize WeChatAppSecret = _WeChatAppSecret;
@synthesize WeChatPartnerID = _WeChatPartnerID;
@synthesize WeChatPayKey = _WeChatPayKey;
@synthesize WeChatURL = _WeChatURL;

@end

@implementation AliPayConfig

@synthesize Configed = _Configed;
@synthesize AlipayPartnerID = _AlipayPartnerID;
@synthesize AlipaySeller = _AlipaySeller;
@synthesize AlipayPrivate = _AlipayPrivate;
@synthesize AlipayNotifyUrl = _AlipayNotifyUrl;
@synthesize AliPaySchemes = _AliPaySchemes;

@end

@implementation JftPayConfig

@synthesize Configed = _Configed;
@synthesize JftPayKey = _JftPayKey;
@synthesize JftPayPartnerID = _JftPayPartnerID;
@synthesize JftAppID = _JftAppID;
@synthesize JftPayAesKey = _JftPayAesKey;
@synthesize JftPayAesVec = _JftPayAesVec;

@end