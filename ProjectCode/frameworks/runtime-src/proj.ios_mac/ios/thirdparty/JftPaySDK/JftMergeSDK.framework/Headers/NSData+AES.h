//
//  NSData+AES.h
//  AESTest
//
//  Created by dyj on 16/5/7.
//  Copyright © 2016年 Tangshan Jun-ho Technology Co.Ltd. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>

@interface NSData (AES)
- (NSData *)AES128Operation:(CCOperation)operation key:(NSString *)key iv:(NSString *)iv;

- (NSData *)AES256Operation:(CCOperation)operation key:(NSString *)key iv:(NSString *)iv;

- (NSData *)AES128EncryptWithKey:(NSString *)key iv:(NSString *)iv;
- (NSData *)AES128DecryptWithKey:(NSString *)key iv:(NSString *)iv;

- (NSData *)AES256EncryptWithKey:(NSString *)key iv:(NSString *)iv;
- (NSData *)AES256DecryptWithKey:(NSString *)key iv:(NSString *)iv;
//-----------------
// API (utilities)
//-----------------
+ (NSString*)hexStringForData:(NSData*)data;

+ (NSData*)dataForHexString:(NSString*)hexString;
@end
