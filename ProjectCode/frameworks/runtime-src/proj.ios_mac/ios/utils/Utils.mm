//
//  LuaObjectCBridge.m
//  GloryProject
//
//  Created by zhong on 16/8/31.
//
//
#import "Utils.h"

//iOS中获取网卡mac信息
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

using namespace cocos2d;

@implementation Utils

+(NSString*) getUUID
{
    NSString *macaddress = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    return [NSString stringWithFormat:@"%@%@",macaddress,bundleIdentifier];
}

+(NSString*) getHostAdress
{
    //return @"192.168.1.1";
    NSString *address = @"192.168.1.1";
    struct ifaddrs *interfaces = nil;
    struct ifaddrs *temp_addr = nil;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (0 == success)
    {
        temp_addr = interfaces;
        while (nil != temp_addr)
        {
            if ( AF_INET == temp_addr->ifa_addr->sa_family )
            {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in*)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
}
@end