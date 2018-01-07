LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := mc_kernel_static
LOCAL_SRC_FILES := ../../prebuilt/android/$(TARGET_ARCH_ABI)/mc_kernel.a
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := bugly_native_prebuilt
LOCAL_SRC_FILES := ../../prebuilt/android/$(TARGET_ARCH_ABI)/libBugly.so
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := libmp3lame
LOCAL_SRC_FILES := ../../prebuilt/android/armeabi/libmp3lame.so
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE := cocos2dlua_shared

LOCAL_MODULE_FILENAME := libqpry_lua

LOCAL_SRC_FILES := \
../../Classes/AppDelegate.cpp \
../../Classes/ide-support/SimpleConfigParser.cpp \
../../Classes/ide-support/RuntimeLuaImpl.cpp \
../../Classes/ide-support/lua_debugger.c \
../../Classes/ClientKernel.cpp \
../../Classes/cjson/strbuf.c \
../../Classes/cjson/fpconv.c \
../../Classes/cjson/lua_cjson.c \
../../Classes/cjson/lua_extensions.c \
../../Classes/LuaAssert/CMD_Data.cpp \
../../Classes/LuaAssert/LuaAssert.cpp \
../../Classes/LuaAssert/ry_MD5.cpp \
../../Classes/LuaAssert/ImageToByte.cpp \
../../Classes/LuaAssert/ClientSocket.cpp \
../../Classes/LuaAssert/DownAsset.cpp \
../../Classes/LuaAssert/UnZipAsset.cpp \
../../Classes/LuaAssert/CurlAsset.cpp \
../../Classes/LuaAssert/LogAsset.cpp \
../../Classes/LuaAssert/CircleBy.cpp \
../../Classes/LuaAssert/QR_Encode.cpp \
../../Classes/LuaAssert/QrNode.cpp \
../../Classes/LuaAssert/AESEncrypt.cpp \
../../Classes/LuaAssert/AudioRecorder/AudioRecorder.cpp \
luambclient/main.cpp \

LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../prebuilt \
					$(LOCAL_PATH)/../../prebuilt/android \
					$(LOCAL_PATH)/../../Classes \
					$(LOCAL_PATH)/../../Classes/cjson \
					$(LOCAL_PATH)/../../Classes/GlobalDefine \
					$(LOCAL_PATH)/../../Classes/ide-support \
					$(LOCAL_PATH)/../../Classes/LuaAssert \

# _COCOS_HEADER_ANDROID_BEGIN
# _COCOS_HEADER_ANDROID_END

LOCAL_STATIC_LIBRARIES := cocos2d_lua_static
LOCAL_STATIC_LIBRARIES += cocos2d_simulator_static
LOCAL_STATIC_LIBRARIES += bugly_crashreport_cocos_static
LOCAL_STATIC_LIBRARIES += bugly_agent_cocos_static_lua
LOCAL_WHOLE_STATIC_LIBRARIES += mc_kernel_static
LOCAL_WHOLE_STATIC_LIBRARIES += android_support

# _COCOS_LIB_ANDROID_BEGIN
# _COCOS_LIB_ANDROID_END

include $(BUILD_SHARED_LIBRARY)

$(call import-module,curl/prebuilt/android)
$(call import-module,scripting/lua-bindings/proj.android)
$(call import-module,tools/simulator/libsimulator/proj.android)
$(call import-module,android/support)
$(call import-module,external/bugly)
$(call import-module,external/bugly/lua)

# _COCOS_LIB_IMPORT_ANDROID_BEGIN
# _COCOS_LIB_IMPORT_ANDROID_END
