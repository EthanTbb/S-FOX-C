//
//  BuglyJSAgent.cpp
//  Bugly
//
//  Created by Yeelik on 16/4/25.
//
//

#include "BuglyJSAgent.h"

#include "cocos2d.h"
#include "ScriptingCore.h"

#include "jsb_helper.h"
#include "jsapi.h"
#include "jsfriendapi.h"
#include "cocos2d_specifics.hpp"

#include <string.h>

#include "CrashReport.h"

#ifndef CATEGORY_JS_EXCEPTION
#define CATEGORY_JS_EXCEPTION 5
#endif

void BuglyJSAgent::registerJSFunctions(JSContext * cx, JS::HandleObject global){
    CCLOG("-> %s", __PRETTY_FUNCTION__);
    
    // register js function with c++ function
    JS_DefineFunction(cx, global, "buglySetUserId", BuglyJSAgent::setUserId,1, JSPROP_READONLY | JSPROP_PERMANENT);
    JS_DefineFunction(cx, global, "buglySetTag", BuglyJSAgent::setTag,1, JSPROP_READONLY | JSPROP_PERMANENT);
    JS_DefineFunction(cx, global, "buglyAddUserValue", BuglyJSAgent::addUserValue,2, JSPROP_READONLY | JSPROP_PERMANENT);
    JS_DefineFunction(cx, global, "buglyLog", BuglyJSAgent::printLog, 3, JSPROP_READONLY | JSPROP_PERMANENT);
}

void BuglyJSAgent::registerJSExceptionHandler(JSContext * cx){
    CCLOG("-> %s", __PRETTY_FUNCTION__);
    
    JS_SetErrorReporter(cx, BuglyJSAgent::reportJSError);
}

void BuglyJSAgent::reportJSError(JSContext * cx, const char *message, JSErrorReport *report){
    CCLOG("-> %s", __PRETTY_FUNCTION__);
    
    const char* format = "%s:%u:%s\n";
    const char* filename = report->filename ? report->filename : "<no filename=\"filename\">";

    size_t bufLen = strlen(format) + strlen(filename) + strlen(message) + 16;
    char* traceback = (char*)malloc(bufLen);
    memset(traceback, 0, bufLen);
    sprintf(traceback, format, filename, (unsigned int)report->lineno, message);

    // TODO report exception
    CrashReport::reportException(CATEGORY_JS_EXCEPTION, "JSError", message, traceback);
    
    free(traceback);
}

bool BuglyJSAgent::setUserId(JSContext *cx, uint32_t argc, jsval *vp){
    CCLOG("-> %s", __PRETTY_FUNCTION__);
    
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    if (argc > 0) {
        std::string userId;
        jsval_to_std_string(cx, args.get(0), &userId);
        // TODO
        CrashReport::setUserId(userId.c_str());
    }
    args.rval().setUndefined();
    
    return true;
}

bool BuglyJSAgent::setTag(JSContext *cx, uint32_t argc, jsval *vp){
    CCLOG("-> %s", __PRETTY_FUNCTION__);
    
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    if (argc > 0) {
        int tag = 0;
        JS::ToInt32(cx, args.get(0), &tag);
        // TODO
        CrashReport::setTag(tag);
    }
    args.rval().setUndefined();
    
    return true;
}

bool BuglyJSAgent::addUserValue(JSContext *cx, uint32_t argc, jsval *vp) {
    CCLOG("-> %s", __PRETTY_FUNCTION__);
    
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    if (argc > 1) {
        std::string key, value;
        jsval_to_std_string(cx, args.get(0), &key);
        jsval_to_std_string(cx, args.get(1), &value);
        
        // TODO
        CrashReport::addUserValue(key.c_str(), value.c_str());
    }
    args.rval().setUndefined();
    
    return true;
}

bool BuglyJSAgent::printLog(JSContext *cx, uint32_t argc, jsval *vp){
    CCLOG("-> %s", __PRETTY_FUNCTION__);
    
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    if (argc > 2) {
        int level = 0;
        JS::ToInt32(cx, args.get(0), &level);
        
        std::string tag, msg;
        jsval_to_std_string(cx, args.get(1), &tag);
        jsval_to_std_string(cx, args.get(2), &msg);
        
        // TODO
        CrashReport::CRLogLevel pLevel = CrashReport::CRLogLevel::Off;
        switch (level) {
            case -1:
                pLevel = CrashReport::CRLogLevel::Off;
                break;
            case 0:
                pLevel = CrashReport::CRLogLevel::Verbose;
                break;
            case 1:
                pLevel = CrashReport::CRLogLevel::Debug;
                break;
            case 2:
                pLevel = CrashReport::CRLogLevel::Info;
                break;
            case 3:
                pLevel = CrashReport::CRLogLevel::Warning;
                break;
            case 4:
                pLevel = CrashReport::CRLogLevel::Error;
                break;
                
            default:
                break;
        }

        CrashReport::log(pLevel, tag.c_str(), msg.c_str());
    }
    args.rval().setUndefined();
    
    return true;
}