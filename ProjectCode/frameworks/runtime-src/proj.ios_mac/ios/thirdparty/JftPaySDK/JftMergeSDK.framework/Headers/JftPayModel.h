//
//  JftPayModel.h
//  SDK_Demo
//
//  Created by dyj on 16/8/19.
//  Copyright © 2016年 dyj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JftPayModel : NSObject
@property (nonatomic, strong ,nonnull) NSString * token;
@property (nonatomic, strong ,nonnull) NSString * key; //**加密向量//
@property (nonatomic, strong ,nonnull) NSString * iv; //**加密密钥//
@property (nonatomic, strong ,nonnull) NSString * serviceType; //**系统标识//
@property (nonatomic, strong ,nonnull) NSString * appId; //**AppId
@property (nonatomic, strong ,nonnull) NSString * payTypeId;
@property (nonatomic, strong ,nullable) UIViewController * controler;

@end
