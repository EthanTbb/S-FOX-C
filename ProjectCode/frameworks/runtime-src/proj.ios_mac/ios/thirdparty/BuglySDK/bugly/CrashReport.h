/******************************************************
 Copyright (C) 2016 Tencent Bugly, Inc.
 
 https://bugly.qq.com/v2
 
 
 Version: 1.3.1
 
 ******************************************************/

#ifndef CRASHREPORT_H
#define CRASHREPORT_H

#ifndef CATEGORY_LUA_EXCEPTION
#define CATEGORY_LUA_EXCEPTION 6
#endif

#ifndef CATEGORY_JS_EXCEPTION
#define CATEGORY_JS_EXCEPTION 5
#endif

class CrashReport
{
public:
    
    /**
     *    @brief 初始化
     *
     *    @param appId 注册应用时，Bugly分配的AppID
     */
    static void initCrashReport(const char* appId);
    
    /**
     *    @brief 初始化
     *
     *    @param appId 注册应用时，Bugly分配的AppID
     *    @param debug 是否开启Debug信息打印，默认关闭，开启则会打印SDK的调试信息
     */
	static void initCrashReport(const char* appId, bool debug);
    
    /**
     *    @brief 设置应用的用户唯一标识
     *
     *    @param userId
     */
    static void setUserId(const char* userId);
    
    /**
     *    @brief 上报自定义错误
     *
     *    @param category  错误的分类，5表示Lua错误，6表示JS错误
     *    @param type      错误类型的名称
     *    @param msg       错误原因
     *    @param traceback 错误堆栈
     */
	static void reportException(int category, const char* type, const char* msg, const char* traceback);
    
    static void reportException(int category, const char* type, const char* msg, const char* traceback, bool quit);
    
    /**
     *    @brief 设置自定义标签，标签需预先在Bugly平台定义
     *
     *    @param tag
     */
	static void setTag(int tag);
	
    /**
     *    @brief 设置自定义Key-Value
     *
     *    @param key
     *    @param value
     */
    static void addUserValue(const char* key, const char* value);

    /**
     *    @brief 删除指定的Key-Value
     *
     *    @param key
     */
	static void removeUserValue(const char* key);

    /**
     * 日志级别
     */
    enum CRLogLevel{ Error=4,Warning=3,Info=2,Debug=1,Verbose=0,Off=-1 };
    
    /**
     *    @brief 自定义日志
     *
     *    @param level 日志级别 {@link CRLogLevel}
     *    @param tag   日志标签
     *    @param fmt   日志内容
     *    @param ...   动态参数
     */
    static void log(CrashReport::CRLogLevel level, const char* tag, const char * fmt, ...);

    /**
     *    @brief 初始化
     *
     *    @param appId 注册应用时，Bugly分配的AppID
     *    @param debug 是否开启Debug信息打印，默认关闭，开启则会打印SDK的调试信息
     *    @param level 是否开启崩溃时自定义日志的上报，默认值为 {@link CRLogLevel:Off}，即关闭。设置为其他的值，即会在崩溃时上报自定义日志。如设置为CRLogLevel:Warning，则会上报CRLogLevel:Warning、CRLogLevel:Error的日志
     */
    static void initCrashReport(const char* appId, bool debug, CrashReport::CRLogLevel level);
    
    /**
     *    @brief 设置渠道
     *
     *    @param channel 渠道标识
     */
    static void setAppChannel(const char* channel);
    
    /**
     *    @brief 设置应用版本
     *
     *    @param version 应用版本信息
     */
    static void setAppVersion(const char* version);
    
    /**
     *    @brief 设置CrashReporter的渠道类别，默认值为0，表示官方版本，2表示MSDK内置版本，3表示IM SDK内置版本
     *
     *    @param type
     */
    static void setCrashReporterType(int type);
    
    CrashReport();
private:
    static bool initialized;
    static int crashReporterType;
};

#endif
