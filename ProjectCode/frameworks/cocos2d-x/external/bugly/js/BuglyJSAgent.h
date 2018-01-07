//
//  BuglyJSAgent.h
//  Bugly
//
//  Copyright © 2016年 Bugly. All rights reserved.
//
//

#ifndef __BUGLY_JS_AGENT_H__
#define __BUGLY_JS_AGENT_H__

#include "cocos2d.h"
#include "ScriptingCore.h"

class BuglyJSAgent {
public:

    static void registerJSFunctions(JSContext * cx, JS::HandleObject global);
    
    static void registerJSExceptionHandler(JSContext * cx);
    static void reportJSError(JSContext * cx, const char * message, JSErrorReport *report);
    
    /* define js function 'buglySetUserId' */
    static bool setUserId(JSContext * cx, uint32_t argc, jsval * vp);
    
    /* define js function 'buglySetTag' */
    static bool setTag(JSContext * cx, uint32_t argc, jsval * vp);
    
    /* define js function 'buglyAddUserValue' */
    static bool addUserValue(JSContext * cx, uint32_t argc, jsval * vp);
    
    /* define js function 'buglyLog' */
    static bool printLog(JSContext * cx, uint32_t argc, jsval * vp);
};

#endif /* __BUGLY_JS_AGENT_H__ */
