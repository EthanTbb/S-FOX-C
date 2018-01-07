/****************************************************************************
Copyright (c) 2008-2010 Ricardo Quesada
Copyright (c) 2010-2012 cocos2d-x.org
Copyright (c) 2011      Zynga Inc.
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
package org.cocos2dx.lua;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;

import org.cocos2dx.lib.Cocos2dxActivity;
import org.cocos2dx.lib.Cocos2dxLuaJavaBridge;
import org.cocos2dx.utils.ConstDefine;
import org.cocos2dx.utils.MP3Recorder;
import org.cocos2dx.thirdparty.ThirdDefine;
import org.cocos2dx.thirdparty.ThirdParty;
import org.cocos2dx.thirdparty.ThirdDefine.ShareParam;
import org.cocos2dx.thirdparty.ThirdParty.PLATFORM;
import org.cocos2dx.utils.Utils;
import org.json.JSONException;
import org.json.JSONObject;

import foxuc.qp.Glory.jlzl.R;

import android.R.integer;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ContentResolver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.provider.ContactsContract;
import android.provider.MediaStore;
import android.util.Log;
import android.view.WindowManager;

public class AppActivity extends Cocos2dxActivity{

	static AppActivity	instance;
	
    static String hostIPAdress = "0.0.0.0";
    
    private Handler m_hHandler = null;
    //lua toast函数
    static final String g_LuaToastFun = "g_NativeToast";
    //登陆监听
    private ThirdParty.OnLoginListener m_LoginListener = null;
    //分享监听
    private ThirdParty.OnShareListener m_ShareListener = null;
    //支付监听
    private ThirdParty.OnPayListener m_PayListener = null;
    //定位监听
    private ThirdParty.OnLocationListener m_LocationListener = null;
    
    /** Lua函数引用 **/
	// 选择图片回调
	private int m_nPickImgCallFunC = -1;
	// 支付回调
	private int m_nThirdPayCallFunC = -1;
	// 登陆回调
	private int m_nThirdLoginFunC = -1;
	// 分享回调
	private int m_nShareFunC = -1;
	// 支付列表回调
	private int m_nPayListFunC = -1;
	// 定位回调
	private int m_nLocationFunC = -1;
	// 通讯录回调
	private int m_nContactFunC = -1;
	
	// 音频保存的路径
	private static MP3Recorder recorder = null;
	
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);     
        com.umeng.socialize.utils.Log.LOG = true;
        
        if(nativeIsLandScape()) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
        } else {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT);
        }
        
        //2.Set the format of window
        
        // Check the wifi is opened when the native is debug.
        if(nativeIsDebug())
        {
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON, WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            if(!isNetworkConnected())
            {
                AlertDialog.Builder builder=new AlertDialog.Builder(this);
                builder.setTitle(R.string.common_title);
                builder.setMessage(R.string.wifi_tips);
                builder.setPositiveButton(R.string.common_sure, null);

                builder.setNegativeButton(R.string.common_cancel, new DialogInterface.OnClickListener() {
                    
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                    	finish();
                    	System.exit(0);
                    }
                });
                builder.setCancelable(true);
                builder.show();
            }
            hostIPAdress = getHostIpAddress();
        }
		instance = this;
		
        ThirdParty.getInstance().init(AppActivity.this);
        initHandler();
        initLoginListener();
        initShareListener();
        initPayListener();
        initLocationListener();
    }
    
    @Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		if (RESULT_OK == resultCode) 
		{
			switch (requestCode) 
			{
				case ConstDefine.RES_PICKIMG_END:
				{
					photoClip((Uri)data.getData());
				}
					break;
				case ConstDefine.RES_CLIPEIMG_END:
				{
					photoClipEnd(data.getExtras());
				}
					break;
				case ConstDefine.RES_PICKIMG_END_NOCLIP:
				{
					photoPickEnd((Uri)data.getData());
				}
					break;
				case ConstDefine.RES_PICKCONTACK_END:
				{
					contactPickEnd((Uri)data.getData());
				}
					break;
				default:
					break;
			}
		}
		super.onActivityResult(requestCode, resultCode, data);
		ThirdParty.getInstance().onActivityResult(requestCode, resultCode, data);
	}   
    
	@Override
	protected void onDestroy() 
	{
		ThirdParty.destroy();
		super.onDestroy();
	}

	private boolean isNetworkConnected() {
        return Utils.isNetworkConnected(this); 
    } 
     
    public String getHostIpAddress() 
    {
       return Utils.getHostIpAddress(this);
    }
    
    public static String getLocalIpAddress() {
        return hostIPAdress;
    }
    
    public void sendMessage(int what)
    {
    	Message msgMessage = Message.obtain();
    	msgMessage.what = what;
    	
    	m_hHandler.sendMessage(msgMessage);
    }
    
    public void sendMessageWithObj(int what, Object obj)
    {
    	Message msgMessage = Message.obtain();
    	msgMessage.what = what;
    	msgMessage.obj = obj;
    	
    	m_hHandler.sendMessage(msgMessage);
    }
    
    public void sendMessageWith(Message msg)
    {
    	m_hHandler.sendMessage(msg);
    }
    
    private void initHandler()
    {
    	m_hHandler = new Handler()
    	{
			@Override
			public void handleMessage(Message msg) 
			{
				switch (msg.what) 
				{
					case ConstDefine.MSG_START_PICKIMG:
					{
						Intent intent = new Intent(Intent.ACTION_PICK, null);
				        intent.setDataAndType(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image/*");  
		                startActivityForResult(intent, ConstDefine.RES_PICKIMG_END);
					}
						break;
					case ConstDefine.MSG_PICKIMG_END:
					{
						final String path = (String)msg.obj;
						toLuaFunC(instance.m_nPickImgCallFunC, path);
					}
						break;
					case ConstDefine.MSG_START_PICKIMG_NOCLIP:
					{
						Intent intent = new Intent(Intent.ACTION_PICK, null);
				        intent.setDataAndType(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image/*");  
		                startActivityForResult(intent, ConstDefine.RES_PICKIMG_END_NOCLIP);
					}
						break;
					case ConstDefine.MSG_CONFIG_PARTY:
					{
						String configMsg = (String)msg.obj;
						if(null != configMsg && "" != configMsg)
						{
							ThirdParty.PLATFORM plat = ThirdParty.getInstance().getPlatform(msg.arg1);
							if (plat != ThirdParty.PLATFORM.INVALIDPLAT)
							{
								ThirdParty.getInstance().configThirdParty(plat, configMsg);
							}
						}
						else 
						{
							toLuaToast("配置信息异常");							
						}						
					}
						break;
					case ConstDefine.MSG_SHARE_CONFIG:
					{
						ThirdParty.getInstance().configSocialShare();
					}
						break;
					case ConstDefine.MSG_THIRD_PAY:
					{
						String payparam = (String)msg.obj;						
						ThirdParty.PLATFORM plat = ThirdParty.getInstance().getPlatform(msg.arg1);
						if (plat != ThirdParty.PLATFORM.INVALIDPLAT)
						{
							ThirdParty.getInstance().thirdPartyPay(plat, payparam, m_PayListener);
						}
					}
						break;
					case ConstDefine.MSG_THIRD_LOGIN:
					{
						ThirdParty.PLATFORM plat = ThirdParty.getInstance().getPlatform(msg.arg1);
						if (plat != ThirdParty.PLATFORM.INVALIDPLAT)
						{
							ThirdParty.getInstance().thirdPartyLogin(plat, m_LoginListener);
						}						
					}
						break;
					case ConstDefine.MSG_SOCIAL_SHARE:
					{						
						ShareParam param = new ShareParam();
						param.sTitle = ThirdDefine.ShareTitle;
						param.sContent = ThirdDefine.ShareContent;
						param.sTargetURL = ThirdDefine.ShareURL; 
						param.sMedia = "";
						ThirdParty.getInstance().openShare(m_ShareListener, param);
					}
						break;
					case ConstDefine.MSG_SOCIAL_CUSCHARE:
					{
						ShareParam param = (ShareParam)msg.obj;
						ThirdParty.getInstance().openShare(m_ShareListener, param);
					}
						break;
					case ConstDefine.MSG_SOCIAL_TARGETSHARE:
					{
						ShareParam param = (ShareParam)msg.obj;
						ThirdParty.getInstance().targetShare(m_ShareListener, param);
					}
						break;
					case ConstDefine.MSG_JFT_PAYLIST:
					{
						String token = (String)msg.obj;
						ThirdParty.getInstance().getPayList(token, m_PayListener);
					}
						break;
					case ConstDefine.MSG_LOCATION_REQ:
					{
						ThirdParty.getInstance().requestLocation(m_LocationListener);
					}
						break;
					case ConstDefine.MSG_CONTACT_REQ:
					{
						Intent intent = new Intent(Intent.ACTION_PICK, ContactsContract.Contacts.CONTENT_URI);
		                startActivityForResult(intent, ConstDefine.RES_PICKCONTACK_END);
					}
						break;
					case ConstDefine.MSG_OPEN_BROWSER:
					{
				        String url = (String)msg.obj;
				        if (url != "")
				        {
				        	Intent intent = new Intent();
					        intent.setAction("android.intent.action.VIEW");
					        Uri content_url = Uri.parse(url);
					        intent.setData(content_url);
					        startActivity(intent);
				        }
					}
						break;
					case ConstDefine.MSG_COPY_CLIPBOARD:
					{
						String str = (String)msg.obj;
						ClipboardManager myClipboard = (ClipboardManager)getSystemService(Context.CLIPBOARD_SERVICE);
				    	myClipboard.setText(str);
					}
						break;
					default:
						break;
				}
			}    		
    	};
    }
    
    //图片裁剪
    private void photoClip(Uri uri)
    {
    	Log.v("photo", "clip start");
    	Intent intent = new Intent("com.android.camera.action.CROP");
        intent.setDataAndType(uri, "image/*");
        intent.putExtra("crop", "true");
        intent.putExtra("aspectX", 1);
        intent.putExtra("aspectY", 1);
        intent.putExtra("outputX", 96);
        intent.putExtra("outputY", 96);
        intent.putExtra("return-data", true);
        startActivityForResult(intent, ConstDefine.RES_CLIPEIMG_END);
    }
    
    private void photoClipEnd(Bundle extras)
    {
    	Log.v("photo", "clip end");
    	if (null != extras)
    	{
    		Bitmap mBitmap = extras.getParcelable("data");
            try 
        	{
            	String imgName = "/@ci_" + this.getPackageName() + ".png";
            	String savePath = this.getFilesDir().getPath();
        		String path = savePath + imgName;
        		
    			File myCaptureFile = new File(savePath, imgName);
    			BufferedOutputStream bos = new BufferedOutputStream(
                                                 new FileOutputStream(myCaptureFile));
    			mBitmap.compress(Bitmap.CompressFormat.PNG, 100, bos);
    			bos.flush();
    			bos.close();
    			
    			sendMessageWithObj(ConstDefine.MSG_PICKIMG_END, path);
    		} 
        	catch (Exception e) 
        	{
    			e.printStackTrace();
    			Log.e("Head", "保存头像错误");
    		}
    	}
    }
    
    //图片选择
    private void photoPickEnd(Uri uri)
    {
    	String[] proj = {MediaStore.Images.Media.DATA};
        Cursor cursor = managedQuery(uri, proj, null, null, null); 
        int column_index = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
        cursor.moveToFirst();
        String path = cursor.getString(column_index);        
    	Log.i("path", path);
    	
		toLuaFunC(m_nPickImgCallFunC, path);
		m_nPickImgCallFunC = -1;
    }
    
    // 通讯录选择
    private void contactPickEnd(Uri uri)
    {
    	String phoneNick = "";
    	String phoneNum = "";
    	//得到ContentResolver对象
    	ContentResolver cr = getContentResolver();
    	//取得电话本中开始一项的光标
    	Cursor cursor=cr.query(uri,null,null,null,null);
    	if(cursor!=null)
    	{
	    	cursor.moveToFirst();
	    	//取得联系人姓名
	    	int nameFieldColumnIndex = cursor.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME);
	    	phoneNick = cursor.getString(nameFieldColumnIndex);
	    	//取得电话号码
	    	String ContactId = cursor.getString(cursor.getColumnIndex(ContactsContract.Contacts._ID));
	    	Cursor phone = cr.query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI, null,
	    	ContactsContract.CommonDataKinds.Phone.CONTACT_ID + "=" + ContactId, null, null);
	    	try 
	    	{
	    		if(phone != null && phone.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER) > 0)
		    	{
		    		phone.moveToFirst();
		    		phoneNum = phone.getString(phone.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER));
		    	}
			} 
	    	catch (Exception e) 
			{
				e.printStackTrace();
			}	    	
	    	phone.close();
	    	cursor.close();
    	}
    	JSONObject backJson = new JSONObject();
    	String backMsg = "";
    	try 
		{
			backJson.put("contactName", phoneNick);
			backJson.put("contactNumber", phoneNum);
			backMsg = backJson.toString();
		} 
		catch (JSONException e) 
		{
			e.printStackTrace();
		}
    	Log.i("Contact", backMsg);
    	toLuaFunC(m_nContactFunC, backMsg);
    	m_nContactFunC = -1;
    }
    
    private void initLoginListener()
    {
    	m_LoginListener = new ThirdParty.OnLoginListener() 
    	{		
    		@Override
			public void onLoginStart(PLATFORM plat, String msg) 
			{
				toLuaToast("登陆开始" + msg);
			}
    		
    		@Override
			public void onLoginCancel(PLATFORM plat, String msg) 
			{
    			toLuaToast("登陆取消 ==> " + msg);
    			toLuaFunC(m_nThirdLoginFunC, "");
    			m_nThirdLoginFunC = -1;
			}
    		
			@Override
			public void onLoginSuccess(PLATFORM plat, String msg) 
			{
				//toLuaToast("登陆成功");
				toLuaFunC(m_nThirdLoginFunC, msg);
				m_nThirdLoginFunC = -1;
			}
			
			@Override
			public void onLoginFail(PLATFORM plat, String msg) 
			{
				toLuaToast("登陆失败 ==> " + msg);
				toLuaFunC(m_nThirdLoginFunC, "");
				m_nThirdLoginFunC = -1;
			}
		};
    }
    
    private void initShareListener()
    {
    	m_ShareListener = new ThirdParty.OnShareListener() 
    	{				
			@Override
			public void onComplete(PLATFORM plat, int eCode,String msg) 
			{
				toLuaFunC(m_nShareFunC, "true");
				m_nShareFunC = -1;
			}

			@Override
			public void onError(PLATFORM plat, String msg) 
			{
				toLuaToast("分享错误 ==> " + msg);
				toLuaFunC(m_nShareFunC, "false");
				m_nShareFunC = -1;
			}

			@Override
			public void onCancel(PLATFORM plat) 
			{
				toLuaToast("分享取消 ==> " + plat);
				toLuaFunC(m_nShareFunC, "false");
				m_nShareFunC = -1;
			}
		};
    }
    
    private void initPayListener()
    {
    	m_PayListener = new ThirdParty.OnPayListener() 
    	{
			
			@Override
			public void onPaySuccess(PLATFORM plat, String msg) 
			{
				if ("" != msg)
				{
					toLuaToast("支付成功");
				}				
				toLuaFunC(m_nThirdPayCallFunC, "true");
				m_nThirdLoginFunC = -1;
			}
			
			@Override
			public void onPayFail(PLATFORM plat, String msg) 
			{
				toLuaToast("支付失败 ==> " + msg);
				toLuaFunC(m_nThirdPayCallFunC, "false");
				m_nThirdLoginFunC = -1;
			}

			@Override
			public void onPayNotify(PLATFORM plat, String msg) 
			{
				toLuaToast(msg);
			}

			@Override
			public void onGetPayList(boolean bOk, String msg) 
			{
				String str = msg;
				if (false == bOk)
				{
					str = "";
					toLuaToast(msg);
				}
				toLuaFunC(m_nPayListFunC, str);
				m_nPayListFunC = -1;				
			}
		};
    }
    
    private void initLocationListener()
    {		
		/**
		 * 定位监听
		 */
    	m_LocationListener = new ThirdParty.OnLocationListener() 
    	{			
			@Override
			public void onLocationResult(boolean bSuccess, int errorCode, String backMsg) 
			{
				String msg = backMsg;
				if (false == bSuccess)
				{
					msg = "";
					toLuaToast(errorCode + ";" + backMsg);
				}
				toLuaFunC(m_nLocationFunC, msg);
				m_nLocationFunC = -1;
			}
		};
    }
    
    //Java to C++
    private static native boolean nativeIsLandScape();
    private static native boolean nativeIsDebug();
    public void toLuaFunC(final int funC, final String msg)
    {
    	if (-1 != funC && null != instance)
		{
    		instance.runOnGLThread(new Runnable() 
			{				
				@Override
				public void run() 
				{
					Cocos2dxLuaJavaBridge.callLuaFunctionWithString(funC,
							msg);
	                Cocos2dxLuaJavaBridge.releaseLuaFunction(funC);
				}
			});
		}
    }
    
    public void toLuaGlobalFunC(final String funName, final String msg)
    {
    	instance.runOnGLThread(new Runnable() 
		{				
			@Override
			public void run() 
			{
				Cocos2dxLuaJavaBridge.callLuaGlobalFunctionWithString(funName, msg);
			}
		});
    }
    
    private void toLuaToast(String msg)
    {
    	toLuaGlobalFunC(g_LuaToastFun, msg);
    }
    
    //Lua/C++ to Java
    //////////////////////////////////////////////////////////////////////////////////////
	/** UUID **/
	public static String getUUID() 
	{
		return Utils.getUUID(instance);
	}
	
	/** ipadress **/
	public static String getHostAdress()
	{
		return Utils.getHostIpAddress(instance);
	}
	
	public static String getSDCardDocPath()
	{
		Log.i("tag", Utils.getSDCardDocPath(instance));
		return Utils.getSDCardDocPath(instance);
	}
	
	//选取头像
	public static void pickImg(final int luaFunc, final boolean needChip)
	{
		instance.m_nPickImgCallFunC = luaFunc;
		if (needChip)
		{
			instance.sendMessage(ConstDefine.MSG_START_PICKIMG);
		}
		else 
		{
			instance.sendMessage(ConstDefine.MSG_START_PICKIMG_NOCLIP);
		}		
	}
    
    //分享配置
    public static void socialShareConfig(String title, String content, String Url)
    {
    	//默认分享icon
    	ThirdDefine.ShareTitle = title;
    	ThirdDefine.ShareContent = content;
    	ThirdDefine.ShareURL = Url;
    	instance.sendMessage(ConstDefine.MSG_SHARE_CONFIG);
    }
    
    //第三方平台配置
    public static void thirdPartyConfig(final int thridparty, final String configstr)
    {
    	Message msgMessage = Message.obtain();
    	msgMessage.what = ConstDefine.MSG_CONFIG_PARTY;
    	msgMessage.arg1 = thridparty;    	
    	msgMessage.obj = configstr;
    	
    	instance.sendMessageWith(msgMessage);
    }
    
    //第三方支付
    public static void thirdPartyPay(final int thridparty, final String payparam, final int luaFunc)
    {    	
    	Message msgMessage = Message.obtain();
    	msgMessage.what = ConstDefine.MSG_THIRD_PAY;
    	msgMessage.arg1 = thridparty;    	
    	msgMessage.obj = payparam;
    	
    	instance.m_nThirdPayCallFunC = luaFunc;    	
    	instance.sendMessageWith(msgMessage);
    }
    
    //第三方登录
    public static void thirdLogin(final int thridparty,final int luaFunc)
	{
    	Message msgMessage = Message.obtain();
    	msgMessage.what = ConstDefine.MSG_THIRD_LOGIN;
    	msgMessage.arg1 = thridparty;
    	
    	instance.m_nThirdLoginFunC = luaFunc;    	
    	instance.sendMessageWith(msgMessage);
	}
    
    //分享
    public static void startShare(final int luaFunc)
    {
    	instance.m_nShareFunC = luaFunc;
    	instance.sendMessage(ConstDefine.MSG_SOCIAL_SHARE);
    }
    
    //自定义分享
    public static void customShare(String title, String content, String url, String mediaPath, String imageOnly,final int luaFunc)
    {    	
    	ThirdDefine.ShareParam param = new ThirdDefine.ShareParam();
    	param.sTitle = title;
    	param.sContent = content;
    	param.sTargetURL = url;
    	param.sMedia = mediaPath;
    	if (imageOnly.equals("true"))
    	{
    		param.bImageOnly = true;
    	}
    	
    	instance.m_nShareFunC = luaFunc;
    	instance.sendMessageWithObj(ConstDefine.MSG_SOCIAL_CUSCHARE, param);
    }
    
    // 分享到指定平台
    public static void shareToTarget(final int target, String title, String content, String url, String mediaPath, String imageOnly,final int luaFunc)
    {
    	ThirdDefine.ShareParam param = new ThirdDefine.ShareParam();
    	param.nTarget = target;
    	param.sTitle = title;
    	param.sContent = content;
    	param.sTargetURL = url;
    	param.sMedia = mediaPath;
    	if (imageOnly.equals("true"))
    	{
    		param.bImageOnly = true;
    	}
    	
    	instance.m_nShareFunC = luaFunc;
    	instance.sendMessageWithObj(ConstDefine.MSG_SOCIAL_TARGETSHARE, param);
    }
    
    //install apk
    public static void installClient(String apkPath)
    {    	
    	if(!"".equals(apkPath))
    	{
    		File apkFile = new File(apkPath);
    		if (null != apkFile && apkFile.exists()) 
    		{
    			Intent installIntent = new Intent(Intent.ACTION_VIEW);
    			installIntent.setDataAndType(Uri.fromFile(apkFile), "application/vnd.android.package-archive");
    			instance.startActivity(installIntent);
			}
    	}
    }
    
    //获取竣付通支付列表
    public static void getPayList(String token, int luaFunc)
    {
    	instance.m_nPayListFunC = luaFunc;
    	Message msgMessage = Message.obtain();
    	msgMessage.what = ConstDefine.MSG_JFT_PAYLIST;
    	msgMessage.obj = token;
    	instance.sendMessageWith(msgMessage);
    }
    
    //获取第三方应用是否安装
    public static boolean isPlatformInstalled(final int thridparty)
    {
    	ThirdParty.PLATFORM plat = ThirdParty.getInstance().getPlatform(thridparty);
    	return ThirdParty.getInstance().isPlatformInstalled(plat);
    }
    
    //保存图片到系统相册
    public static boolean saveImgToSystemGallery(final String path, final String filename)
    {
    	boolean bRes = false;
    	// 文件插入系统图库
    	try 
    	{
            MediaStore.Images.Media.insertImage(instance.getContentResolver(), path, filename, null);
            // 最后通知图库更新
        	instance.sendBroadcast(new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, Uri.parse("file://" + path)));
        	bRes = true;
        } 
    	catch (FileNotFoundException e) 
        {
            e.printStackTrace();
        }
    	return bRes;
    }
    
    // 判断是否有录音权限
    public static boolean isHaveRecordPermission()
    {
    	PackageManager pManager = instance.getPackageManager();
    	Log.i("Permission", "pstate ==> " + pManager.checkPermission("android.permission.RECORD_AUDIO", instance.getPackageName()));
    	return PackageManager.PERMISSION_GRANTED == pManager.checkPermission("android.permission.RECORD_AUDIO", instance.getPackageName());
    }
    
    public static void startRecord(String fileName)
    {
    	if(recorder == null)
    	{
    		recorder = new MP3Recorder(fileName, 8000);
    		recorder.init();
    	}
    		
    	recorder.start(instance);
    }    
    
    public static void stopRecord()
    {
    	if(recorder != null)
    	{
    		recorder.stop();
    	}	
    }
    
    public static void cancelRecord()
    {
    	if(recorder != null)
    	{
    		recorder.cancel();
    	}
    }
    
    // 请求单次定位
    public static void requestLocation(int luaFunc)
    {
    	instance.m_nLocationFunC = luaFunc;
    	Message msgMessage = Message.obtain();
    	msgMessage.what = ConstDefine.MSG_LOCATION_REQ;
    	instance.sendMessageWith(msgMessage);
    }
    
    // 计算距离
    public static String metersBetweenLocation(String loParam)
    {
    	return ThirdParty.getInstance().metersBetweenLocation(loParam);
    }
    
    // 请求通讯录
    public static void requestContact(int luaFunc)
    {
    	instance.m_nContactFunC = luaFunc;
    	Message msgMessage = Message.obtain();
    	msgMessage.what = ConstDefine.MSG_CONTACT_REQ;
    	instance.sendMessageWith(msgMessage);
    }
    
    // 启动浏览器
    public static void openBrowser( String url )
    {
    	Message msgMessage = Message.obtain();
    	msgMessage.what = ConstDefine.MSG_OPEN_BROWSER;
    	msgMessage.obj = url;
    	instance.sendMessageWith(msgMessage);
    }
    
    // 复制到剪贴板
    public static boolean copyToClipboard( String msg )
    {
    	Message msgMessage = Message.obtain();
    	msgMessage.what = ConstDefine.MSG_COPY_CLIPBOARD;
    	msgMessage.obj = msg;
    	instance.sendMessageWith(msgMessage);
    	return true;
    }
}
