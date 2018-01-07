#ifndef __APP_DELEGATE_H__
#define __APP_DELEGATE_H__

#include "cocos2d.h"

 typedef int Lua_CallBack;
/**
@brief    The cocos2d Application.

The reason for implement as private inheritance is to hide some interface call by Director.
*/
class  AppDelegate : private cocos2d::Application, public cocos2d::Node
{

static	AppDelegate*	m_instance;

	Node*				m_pClientKernel;
    // Lua_CallBack*       m_SocketEventListener;

    Lua_CallBack        m_BackgroundCallBack;
public:
	Node*			    m_ImageToByte;
    std::unordered_map<std::string, cocos2d::Texture2D*> m_cachedBmpTex;
public:
    AppDelegate();
    virtual ~AppDelegate();

    virtual void initGLContextAttrs();

    /**
    @brief    Implement Director and Scene init code here.
    @return true    Initialize success, app continue.
    @return false   Initialize failed, app terminate.
    */
    virtual bool applicationDidFinishLaunching();

    /**
    @brief  The function be called when the application enter background
    @param  the pointer of the application
    */
    virtual void applicationDidEnterBackground();

    /**
    @brief  The function be called when the application enter foreground
    @param  the pointer of the application
    */
    virtual void applicationWillEnterForeground();
	
	void GlobalUpdate(float dt);

	static AppDelegate* getAppInstance(){return m_instance;}

	Node* getClientKernel(){return m_pClientKernel;}

    // void setSocketEventListener(Node* node){m_SocketEventListener = node;}
    // Node* getSocketEventListener(){return m_SocketEventListener;}

    void setBackgroundListener(Lua_CallBack callback){m_BackgroundCallBack = callback;}
    Lua_CallBack getBackgroundListener(){return m_BackgroundCallBack;}
};

#endif  // __APP_DELEGATE_H__

