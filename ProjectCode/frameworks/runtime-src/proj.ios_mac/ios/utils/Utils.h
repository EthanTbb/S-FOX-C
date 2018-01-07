//
//  LuaObjectCBridge.h
//  GloryProject
//
//  Created by zhong on 16/8/31.
//
//

#ifndef ry_Utils_h
#define ry_Utils_h
#import <Foundation/Foundation.h>
#include "cocos2d.h"

@interface Utils : NSObject{
    
}

//获取uuid
+(NSString*) getUUID;

//设备ip地址
+(NSString*) getHostAdress;

@end

#endif /* ry_Utils_h */
