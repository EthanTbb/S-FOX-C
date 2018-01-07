/****************************************************************************
 Copyright (c) 2010-2013 cocos2d-x.org
 Copyright (c) 2013-2014 Chukong Technologies Inc.

 http://www.cocos2d-x.org

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/
#import "thirdparty/ThirdProtocol.h"
#import <ContactsUI/ContactsUI.h>
#import <Contacts/Contacts.h>
@class RootViewController;

@interface AppController : NSObject <UIApplicationDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate, LoginDelegate, ShareDelegate, PayDelegate, LocationDelegate, CNContactPickerDelegate>
{
    UIWindow *window;
@public
    RootViewController *viewController;
}
- (void) initAppController;

//选择图片回调
@property (readwrite) int PickCallFunC;
- (int) getPickCallFunC;
//登陆回调
@property int LoginCallFunC;
//支付回调
@property int PayCallFunC;
//分享回调
@property int ShareCallFunC;
// 定位回调
@property int LocationCallFunC;
// 通讯录回调
@property int ContactCallFunC;
@end

