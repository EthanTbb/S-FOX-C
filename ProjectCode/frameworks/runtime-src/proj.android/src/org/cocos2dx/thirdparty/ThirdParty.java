package org.cocos2dx.thirdparty;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.cocos2dx.thirdparty.ThirdDefine;
import org.cocos2dx.thirdparty.ThirdDefine.ShareParam;
import org.cocos2dx.thirdparty.alipay.PayResult;
import org.cocos2dx.thirdparty.alipay.ZhifubaoPay;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;
import com.amap.api.location.AMapLocationClientOption.AMapLocationMode;
import com.amap.api.location.AMapLocationClientOption.AMapLocationProtocol;
import com.amap.api.maps2d.AMapUtils;
import com.amap.api.maps2d.model.LatLng;
import com.tencent.mm.sdk.constants.Build;
import com.tencent.mm.sdk.modelpay.PayReq;
import com.tencent.mm.sdk.openapi.IWXAPI;
import com.tencent.mm.sdk.openapi.WXAPIFactory;
import com.umeng.socialize.PlatformConfig;
import com.umeng.socialize.ShareAction;
import com.umeng.socialize.UMAuthListener;
import com.umeng.socialize.UMShareAPI;
import com.umeng.socialize.UMShareListener;
import com.umeng.socialize.bean.SHARE_MEDIA;
import com.umeng.socialize.media.UMImage;
import com.umeng.socialize.utils.OauthHelper;

import sdk.pay.PayConstant;
import sdk.pay.PayExceptionType;
import sdk.pay.PayInfo;
import sdk.pay.PayTypeModel;
import sdk.pay.PayUtil;

import foxuc.qp.Glory.jlzl.R;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager.NameNotFoundException;
import android.os.Handler;
import android.os.Message;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

public class ThirdParty 
{	
	public enum PLATFORM
	{
		INVALIDPLAT(-1),
		WECHAT(0),
		WECHAT_CIRCLE(1),
		ALIPAY(2),
		JFT(3),
		AMAP(4),
		IAP(5),
		SMS(6);
		
		private int nNum = -1;
		private PLATFORM(int n)
		{
			nNum = n;
		}
		public int toNumber()
		{
			return this.nNum;
		}
	}
	//登陆监听
	public static interface OnLoginListener
	{
		public void onLoginStart(PLATFORM plat, String msg);
		
		public void onLoginSuccess(PLATFORM plat, String msg);
		
		public void onLoginFail(PLATFORM plat, String msg);
		
		public void onLoginCancel(PLATFORM plat, String msg);
	}
	
	//分享监听
	public static interface OnShareListener
	{		
		public void onComplete(PLATFORM plat, int eCode, String msg);
		
		public void onError(PLATFORM plat, String msg);
		
		public void onCancel(PLATFORM plat);
	}
	
	//支付监听
	public static interface OnPayListener
	{
		public void onPaySuccess(PLATFORM plat, String msg);
		
		public void onPayFail(PLATFORM plat, String msg);
		
		public void onPayNotify(PLATFORM plat, String msg);
		
		public void onGetPayList(boolean bOk, String msg);
	}
	
	// 定位监听
	public static interface OnLocationListener
	{
		public void onLocationResult(boolean bSuccess, int errorCode, String backMsg);
	}
	
	private static ThirdParty m_tInstance = new ThirdParty();
	private Activity m_Context = null;
	//友盟
    private UMShareAPI mShareAPI = null;
    //第三方平台列表
    private List<PLATFORM> m_ThridPlatList = null;
    //友盟第三方平台列表
    private Map<PLATFORM, SHARE_MEDIA> m_UMPartyList = null;
    //支付回调
    private OnPayListener m_OnPayListener = null;
    private PLATFORM m_enPayPlatform = PLATFORM.INVALIDPLAT;
    //支付宝
    private ZhifubaoPay m_AliPay = null;
    //骏付通
    private PayInfo m_PayInfo = null;
    private PayUtil m_PayUtil = null;
    private Handler m_JftHandler = null;    
	
    // 高德
    private AMapLocationClient locationClient = null;
	private AMapLocationClientOption locationOption = new AMapLocationClientOption();
	// 定位监听
    private AMapLocationListener locationListener = null;
    // 定位回调
    private OnLocationListener m_LocationListener = null;
	
	public static ThirdParty getInstance()
	{
		return m_tInstance;
	}
	
	public static void destroy()
	{
		if (null != m_tInstance.locationClient)
		{
			m_tInstance.locationClient.onDestroy();
		}
		
		if (null != m_tInstance.m_PayUtil)
		{
			m_tInstance.m_PayUtil.destroy();
		}
	}
	
	public void init(Activity context)
	{
		m_Context = context;
		mShareAPI = UMShareAPI.get(m_Context);
			
		//第三方平台
		m_ThridPlatList = new ArrayList<ThirdParty.PLATFORM>();
		m_ThridPlatList.add(0,ThirdParty.PLATFORM.WECHAT);
		m_ThridPlatList.add(1,ThirdParty.PLATFORM.WECHAT_CIRCLE);
		m_ThridPlatList.add(2,ThirdParty.PLATFORM.ALIPAY);
		m_ThridPlatList.add(3, ThirdParty.PLATFORM.JFT);
		m_ThridPlatList.add(4, ThirdParty.PLATFORM.AMAP);
		m_ThridPlatList.add(5, ThirdParty.PLATFORM.IAP);
		m_ThridPlatList.add(6, ThirdParty.PLATFORM.SMS);
		
		//添加友盟平台
		m_UMPartyList = new HashMap<ThirdParty.PLATFORM, SHARE_MEDIA>();
		m_UMPartyList.put(ThirdParty.PLATFORM.WECHAT, SHARE_MEDIA.WEIXIN);
		m_UMPartyList.put(ThirdParty.PLATFORM.WECHAT_CIRCLE, SHARE_MEDIA.WEIXIN_CIRCLE);
		m_UMPartyList.put(ThirdParty.PLATFORM.ALIPAY, SHARE_MEDIA.ALIPAY);
		m_UMPartyList.put(ThirdParty.PLATFORM.SMS, SHARE_MEDIA.SMS);
		
		//竣付通		
		m_PayInfo = new PayInfo();
	}
	
	public PLATFORM getPlatform(final int nPart)
	{
		//判断友盟平台
		int len = m_ThridPlatList.size();
		if (nPart < 0 || nPart >= len) 
		{
			return ThirdParty.PLATFORM.INVALIDPLAT;
		}
		return m_ThridPlatList.get(nPart);
	}
	
	public PLATFORM getPlatformFrom(SHARE_MEDIA mdia)
	{
		//判断友盟平台
		Set<PLATFORM> ptSet= m_UMPartyList.keySet();
		for (PLATFORM pt: ptSet)
		{
			if (m_UMPartyList.get(pt) == mdia)
			{
				return pt;
			}
		}
		return PLATFORM.INVALIDPLAT;
	}
	
	public void onActivityResult(int requestCode, int resultCode, Intent data)
	{
		if (null != mShareAPI)
		{
			mShareAPI.onActivityResult(requestCode, resultCode, data);
		}
	}
	
	public void onPayResult(boolean bOk, String msg)
	{
		if (null != m_OnPayListener)
		{
			if (bOk)
			{
				m_OnPayListener.onPaySuccess(m_enPayPlatform, msg);
			}
			else 
			{
				m_OnPayListener.onPayFail(m_enPayPlatform, msg);
			}
		}
		m_OnPayListener = null;
	}
	
	public void onPayNotify(String msg)
	{
		if (null != m_OnPayListener)
		{
			m_OnPayListener.onPayNotify(m_enPayPlatform, msg);
		}
	}
	
	public void configThirdParty(PLATFORM plat, String configstr)
	{
		switch (plat) 
		{
		case WECHAT:
			doConfigWeChat(configstr);
			break;
		case ALIPAY:
			doConfigAlipay(configstr);
			break;
		case JFT:
			doConfigJFT(configstr);
			break;
		case AMAP:
			doConfigAMAP(configstr);
			break;
		default:
			break;
		}
	}
	
	public void configSocialShare()
	{
		if (null == mShareAPI)
		{
			return;
		}
	}
	
	public void thirdPartyLogin(PLATFORM plat, OnLoginListener listener)
	{
		//判断友盟
		if (m_UMPartyList.containsKey(plat))
		{
			SHARE_MEDIA mdia = m_UMPartyList.get(plat);			
			if (mdia == SHARE_MEDIA.WEIXIN)
			{
				doWeChatLogin(listener);
			}
		}
	}
	
	public void deleteThirdPartyAuthorization(SHARE_MEDIA mdia)
	{
		mShareAPI.deleteOauth(m_Context, mdia, new UMAuthListener()
		{
			@Override
			public void onCancel(SHARE_MEDIA arg0, int arg1) 
			{
				
			}

			@Override
			public void onComplete(SHARE_MEDIA arg0, int arg1,
					Map<String, String> arg2) 
			{
				
			}

			@Override
			public void onError(SHARE_MEDIA arg0, int arg1, Throwable arg2) 
			{
				
			}
		});
	}
	
	public void openShare(final OnShareListener listener, ShareParam param)
	{
		if (null == m_Context)
		{
			listener.onError(m_enPayPlatform, "init error");
			return;
		}
		final SHARE_MEDIA[] displaylist = new SHARE_MEDIA[]
                {
                    SHARE_MEDIA.WEIXIN, SHARE_MEDIA.WEIXIN_CIRCLE
                };
		ShareAction sAct = newShareAction(param);
		sAct.setDisplayList(displaylist).setListenerList(newShareListener(listener)).open();
	}
	
	public void targetShare(final OnShareListener listener, ShareParam param)
	{
		ThirdParty.PLATFORM plat = ThirdParty.getInstance().getPlatform(param.nTarget);
		if (m_UMPartyList.containsKey(plat))
		{
			UMImage img = UMAsset.getUmImage(m_Context, param.sMedia);		
			if (null == img)
			{
				img = new UMImage(m_Context, R.drawable.icon);
			}
			SHARE_MEDIA mdia = m_UMPartyList.get(plat);	
			ShareAction sAct = newShareAction(param);
			sAct.setPlatform(mdia).setCallback(newShareListener(listener)).share();
		}
		else 
		{
			listener.onError(plat, "do not support target");
		}
	}
	
	public void thirdPartyPay(PLATFORM plat, String payparam, final OnPayListener listener)
	{
		m_enPayPlatform = plat;
		//解析支付参数
		try 
		{
			JSONObject jObject = new JSONObject(payparam);			
			m_OnPayListener = listener;	
			
			//判断平台
			switch (plat) 
			{
			case WECHAT:
				JSONObject infoObject = jObject.getJSONObject("info");
				doWeChatPay(infoObject);
				break;
			case ALIPAY:
			{
				ThirdDefine.PayParam param = new ThirdDefine.PayParam();
				param.sOrderId = jObject.getString("orderid");
				param.fPrice = (float)jObject.getDouble("price");
				param.sProductName = jObject.getString("name");
				doAliPay(param);
			}				
				break;
			case JFT:
			{
				int nPayType = (int)jObject.getInt("paytype");
				doJtfPay(nPayType);
			}				
				break;
			default:
				break;
			}
			
		} 
		catch (JSONException e) 
		{
			e.printStackTrace();
			listener.onPayFail(m_enPayPlatform, "订单数据解析失败");
		}
	}
	
	public void getPayList(String token, final OnPayListener listener)
	{
		if (null == listener)
		{
			return;
		}		
		if (false == ThirdDefine.bConfigJFT)
		{
			listener.onGetPayList(false, "竣付通配置异常");
			return;
		}
		m_OnPayListener = listener;
		if (true)
		{
			m_JftHandler = new Handler()
			{
				@Override
				public void handleMessage(Message msg) 
				{
					switch (msg.what) 
					{
					case PayConstant.INIT_RESULT:
					{						
						if (m_PayInfo.getPayTypeModels().size() > 0) 
						{
							Log.v("获取通道成功", "竣付通支付");
							JSONArray jArray = new JSONArray();
							@SuppressWarnings("unchecked")
							ArrayList<PayTypeModel> arrayList  =  (ArrayList<PayTypeModel>) m_PayInfo.getPayTypeModels();
							for (int idx = 0; idx < arrayList.size(); ++idx)
							{
								jArray.put(arrayList.get(idx).getTypeid());
							}
							String jsonStr = jArray.toString();
							listener.onGetPayList(true, jsonStr);
	                    } 
						else 
	                    {
	                        Log.v("未获取到支付通道", "竣付通支付");
	                        listener.onGetPayList(false, "未获取到支付通道");
	                    }
					}
						break;
					case PayConstant.SHOW_TOAST:
					{
						String content = (String) msg.obj;
	                    if (null != content) 
	                    {
	                        Toast.makeText(m_Context, content, Toast.LENGTH_SHORT).show();
	                    }
	                    else 
	                    {
	                        int arg1 = msg.arg1;
	                        PayExceptionType type = PayExceptionType.values()[arg1];
	                        String str;
	                        switch (type) 
	                        {
	                            case DATA_EXCEPTION: 
	                            {
	                                str = m_Context.getString(R.string.data_exception);
	                                break;
	                            }
	                            case ENCRYPT_EXCEPTION: 
	                            {
	                                str = m_Context.getString(R.string.encrypt_exception);
	                                break;
	                            }
	                            case GET_PAY_METHOD_FAILED: 
	                            {
	                                str = m_Context.getString(R.string.get_pay_method_failed);
	                                break;
	                            }
	                            case DECRYPT_EXCEPTION: 
	                            {
	                                str = m_Context.getString(R.string.decrypt_exception);
	                                break;
	                            }
	                            case RETURN_ERROR_DATA: 
	                            {
	                                str = m_Context.getString(R.string.return_error_data);
	                                break;
	                            }
	                            case PAY_SYSTEM_ID_EMPTY: 
	                            {
	                                str = m_Context.getString(R.string.pay_system_id_empty);
	                                break;
	                            }
	                            case SERVER_CONNECTION_EXCEPTION: 
	                            {
	                                str = m_Context.getString(R.string.server_connection_exception);
	                                break;
	                            }
	                            default: 
	                            {
	                                str = "";
	                                break;
	                            }
	                        }
	                        Log.v( "捕获异常",str);
	                        listener.onPayNotify(PLATFORM.JFT, str);//(false, "未获取到支付通道");
	                    }
					}
						break;
					default:
						break;
					}
				}			
			};			
		}	
		if (null != m_PayUtil)
		{
			m_PayUtil.destroy();
		}
		m_PayInfo.setJuntoken(token);
		m_PayInfo.setAppId(ThirdDefine.JFTAppID);
	    m_PayInfo.setKeyAES(ThirdDefine.JFTKey);
	    m_PayInfo.setVectorAES(ThirdDefine.JFTVector);
	    m_PayInfo.setPaySystemId("jft");

	    m_PayUtil = new PayUtil(m_Context, m_JftHandler, m_PayInfo);
		m_PayUtil.getPayType();
	}
	
	public boolean isPlatformInstalled(PLATFORM plat)
	{
		String packageName = "";
		if (plat == ThirdParty.PLATFORM.WECHAT)
		{
			packageName = "com.tencent.mm";
		}
		else if (plat == ThirdParty.PLATFORM.ALIPAY) 
		{
			packageName = "com.eg.android.AlipayGphone";
		}
		else 
		{
			return false;
		}
		android.content.pm.ApplicationInfo info = null;
        try 
        {
            info = m_Context.getPackageManager().getApplicationInfo(packageName, 0);
            return info != null;
        } 
        catch (NameNotFoundException e) 
        {
            return false;
        }
	}
	
	// 请求单次定位
	public void requestLocation(OnLocationListener listener)
	{
		m_LocationListener = listener;
		if (null != locationClient && null != locationListener)
		{
			locationClient.stopLocation();
			// 设置定位监听
			locationClient.setLocationListener(locationListener);
			// 定位请求
			locationClient.startLocation();
		}
		else
		{
			listener.onLocationResult(false, -1, "定位服务初始化失败!");
		}
	}
	
	// 停止定位
	public void stopLocation()
	{
		locationClient.stopLocation();
	}
	
	// 距离计算
	public String metersBetweenLocation(String loParam)
	{
		String msg = "0";
		try 
		{
			JSONObject jObject = new JSONObject(loParam);
			double myLatitude = jObject.getDouble("myLatitude");
			double myLongitude = jObject.getDouble("myLongitude");
			
			double otherLatitude = jObject.getDouble("otherLatitude");
			double otherLongitude = jObject.getDouble("otherLongitude");
			
			LatLng my2d = new LatLng(myLatitude, myLongitude);
			LatLng or2d = new LatLng(otherLatitude, otherLongitude);
			msg = String.valueOf(AMapUtils.calculateLineDistance(my2d, or2d));
		} 
		catch (JSONException e) 
		{
			e.printStackTrace();
		}
		return msg;
	}
	
	private void doConfigWeChat(String configstr)
	{
		try 
		{
			JSONObject jObject = new JSONObject(configstr);
			ThirdDefine.WeixinAppID = jObject.getString("AppID");
	    	ThirdDefine.WeixinAppSecret = jObject.getString("AppSecret");
	    	ThirdDefine.WeixinPartnerid = jObject.getString("PartnerID");
	    	ThirdDefine.WeixinPayKey = jObject.getString("PayKey");
	    	ThirdDefine.bConfigWeChat = true;
			
	    	PlatformConfig.setWeixin(ThirdDefine.WeixinAppID, ThirdDefine.WeixinAppSecret);
		} 
		catch (JSONException e) 
		{
			e.printStackTrace();
		}
	}
	
	private void doConfigAlipay(String configstr)
	{
		try 
		{
			JSONObject jObject = new JSONObject(configstr);
	    	
	    	ThirdDefine.ZFBPARTNER = jObject.getString("PartnerID");
	    	ThirdDefine.ZFBSELLER = jObject.getString("SellerID");
	    	ThirdDefine.ZFBNOTIFY_URL = jObject.getString("NotifyURL");
	    	ThirdDefine.ZFBRSA_PRIVATE = jObject.getString("RsaKey");
	    	ThirdDefine.bConfigAlipay = true;
	    	
	    	PlatformConfig.setAlipay(ThirdDefine.ZFBPARTNER);
		} 
		catch (JSONException e) 
		{
			e.printStackTrace();
		}
	}
	
	private void doConfigJFT(String configstr)
	{
		try 
		{
			JSONObject jObject = new JSONObject(configstr);
	    	
			String appid = jObject.getString("JftAppID");
	    	String key = jObject.getString("JftAesKey");
	    	String vec = jObject.getString("JftAesVec");

			ThirdDefine.JFTKey = key;
			ThirdDefine.JFTVector = vec;
			ThirdDefine.JFTAppID = appid;			
	        ThirdDefine.bConfigJFT = true;
		} 
		catch (JSONException e) 
		{
			e.printStackTrace();
		}		
	}
	
	private void doConfigAMAP(String configstr) 
	{
		locationOption = new AMapLocationClientOption();
		locationOption.setLocationMode(AMapLocationMode.Hight_Accuracy);//可选，设置定位模式，可选的模式有高精度、仅设备、仅网络。默认为高精度模式
		locationOption.setGpsFirst(false);//可选，设置是否gps优先，只在高精度模式下有效。默认关闭
		locationOption.setHttpTimeOut(30000);//可选，设置网络请求超时时间。默认为30秒。在仅设备模式下无效
		locationOption.setInterval(2000);//可选，设置定位间隔。默认为2秒
		locationOption.setNeedAddress(false);//可选，设置是否返回逆地理地址信息。默认是true
		locationOption.setOnceLocation(true);//可选，设置是否单次定位。默认是false
		locationOption.setOnceLocationLatest(false);//可选，设置是否等待wifi刷新，默认为false.如果设置为true,会自动变为单次定位，持续定位时不要使用
		AMapLocationClientOption.setLocationProtocol(AMapLocationProtocol.HTTP);//可选， 设置网络请求的协议。可选HTTP或者HTTPS。默认为HTTP
		locationOption.setSensorEnable(false);//可选，设置是否使用传感器。默认是false
		
		// 定位监听
		locationListener = new AMapLocationListener() 
		{
			@Override
			public void onLocationChanged(AMapLocation loc) 
			{
				boolean bRes = false;
				int errorCode = AMapLocation.ERROR_CODE_UNKNOWN;
				String backMsg = "";
				if (null != loc) 
				{
					//解析定位结果
					if (0 == loc.getErrorCode())
					{
						JSONObject jObject = new JSONObject();
						try 
						{
							bRes = true;
							jObject.put("berror", false);
							jObject.put("latitude", loc.getLatitude());
							jObject.put("longitude", loc.getLongitude());
							jObject.put("accuracy", loc.getAccuracy());
							backMsg = jObject.toString();
						} 
						catch (JSONException e) 
						{
							backMsg = "定位数据解析异常!" + loc.getErrorInfo();
							e.printStackTrace();
						}
					}
					else 
					{
						JSONObject jObject = new JSONObject();
						try 
						{
							bRes = true;
							jObject.put("berror", true);
							jObject.put("msg", errorCode + ",定位失败! " + loc.getErrorInfo());
							backMsg = jObject.toString();
						} 
						catch (JSONException e) 
						{
							backMsg = "定位数据解析异常!" + loc.getErrorInfo();
							e.printStackTrace();
						}
						locationClient.stopLocation();
					}
				} 
				else 
				{
					backMsg = "定位数据异常!";
				}
				
				if ( null != m_LocationListener ) 
				{
					m_LocationListener.onLocationResult(bRes, errorCode, backMsg);
				}
				locationClient.stopLocation();
			}
		};
		
		// 初始化client
		locationClient = new AMapLocationClient(m_Context.getApplicationContext());
		// 设置定位参数
		locationClient.setLocationOption(locationOption);
	}
	
	private void doWeChatLogin(final OnLoginListener listener)
	{
		if (false == mShareAPI.isInstall(m_Context, SHARE_MEDIA.WEIXIN))
		{
			listener.onLoginFail(PLATFORM.WECHAT, "微信客户端未安装,无法授权登陆");
			return;
		}
		
		if (null == m_Context || false == ThirdDefine.bConfigWeChat)
		{
			listener.onLoginFail(PLATFORM.WECHAT, "");
			return;
		}
		
		//如果已经授权，则拉取用户数据，否则请求授权
		if (OauthHelper.isAuthenticated(m_Context, SHARE_MEDIA.WEIXIN))
		{
			getPlatFormInfo(SHARE_MEDIA.WEIXIN, listener);
		}
		else
		{
			mShareAPI.doOauthVerify(m_Context, SHARE_MEDIA.WEIXIN, new UMAuthListener() 
			{
				@Override
				public void onCancel(SHARE_MEDIA arg0, int arg1) 
				{
					listener.onLoginCancel(PLATFORM.WECHAT, "");
				}

				@Override
				public void onComplete(SHARE_MEDIA arg0, int arg1,
						Map<String, String> arg2) 
				{
					//parseAuthorData(listener, PLATFORM.WECHAT, arg1, arg2);
					getPlatFormInfo(SHARE_MEDIA.WEIXIN, listener);
				}

				@Override
				public void onError(SHARE_MEDIA arg0, int arg1, Throwable arg2) 
				{
					listener.onLoginFail(PLATFORM.WECHAT, "");
				}
			});
		}
	}
	
	private void doWeChatPay(final JSONObject info)
	{
		if (null == m_Context || false == ThirdDefine.bConfigWeChat)
		{
			onPayResult(false, "初始化失败");
			return;
		}
		
		IWXAPI msgApi = WXAPIFactory.createWXAPI(m_Context, ThirdDefine.WeixinAppID);
		msgApi.registerApp(ThirdDefine.WeixinAppID);
		if (msgApi.getWXAppSupportAPI() >= Build.PAY_SUPPORTED_SDK_INT)
		{			
    		try 
    		{
    			PayReq request = new PayReq();
        		request.appId = info.getString("appid");
        		request.partnerId = info.getString("partnerid");
				request.prepayId= info.getString("prepayid");
				request.packageValue = info.getString("package");
	    		request.nonceStr= info.getString("noncestr");
	    		request.timeStamp= info.getString("timestamp");
	    		request.sign=  info.getString("sign");
	    		msgApi.sendReq(request);
			} 
    		catch (JSONException e) 
			{
				e.printStackTrace();
				onPayResult(false, "订单数据解析异常");
			}    		
		}
		else
		{
			onPayResult(false, "未安装微信或微信版本过低");
		}
	}
	
	private void doAliPay(ThirdDefine.PayParam param)
	{
		if(null == m_Context || false == ThirdDefine.bConfigAlipay)
		{
			onPayResult(true, "初始化失败");
			return;
		}
		if (null == m_AliPay)
		{
			m_AliPay = new ZhifubaoPay(new Handler(){

				@Override
				public void handleMessage(Message msg) 
				{
					if (msg.what == ThirdDefine.ZFB_Pay)
					{
						PayResult payResult = new PayResult((String) msg.obj);

						String resultStatus = payResult.getResultStatus();
						// 判断resultStatus 为“9000”则代表支付成功，具体状态码代表含义可参考接口文档
						if (TextUtils.equals(resultStatus, "9000")) 
						{
							onPayResult(true, payResult.getResult());
						} 
						else 
						{
							// 判断resultStatus 为非"9000"则代表可能支付失败
							// "8000"代表支付结果因为支付渠道原因或者系统原因还在等待支付结果确认，最终交易是否成功以服务端异步通知为准（小概率状态）
							if (TextUtils.equals(resultStatus, "8000")) 
							{
								onPayNotify("支付结果确认中");
							} 
							else 
							{
								// 其他值就可以判断为支付失败，包括用户主动取消支付，或者系统返回的错误
								onPayResult(false, payResult.getResult());
							}
						}
					}
				}
				
			}, m_Context);
		}
		m_AliPay.setOrderNo(param.sOrderId);
		m_AliPay.pay(param.fPrice, param.sProductName);
	}
	
	private void doJtfPay(int nPayType)
	{
		if (null != m_PayUtil)
		{
			m_PayUtil.getPayParam(nPayType);
		}	
		onPayResult(true, "");
	}
	
	private void getPlatFormInfo(final SHARE_MEDIA mdia, final OnLoginListener listener)
	{
		final PLATFORM plat = getPlatformFrom(mdia);
		mShareAPI.getPlatformInfo(m_Context, mdia, new UMAuthListener() 
		{
			
			@Override
			public void onError(SHARE_MEDIA arg0, int arg1, Throwable arg2) 
			{
				listener.onLoginFail(plat, arg2.getMessage());
			}
			
			@Override
			public void onComplete(SHARE_MEDIA arg0, int arg1, Map<String, String> arg2) 
			{
				parseAuthorData(listener, plat, arg1, arg2);				
			}
			
			@Override
			public void onCancel(SHARE_MEDIA arg0, int arg1) 
			{
				listener.onLoginFail(plat, ""+arg1);
			}
		});		
	}
	
	private void parseAuthorData(final OnLoginListener listener, PLATFORM plat, int arg1, Map<String, String> arg2)
	{	    	
    	if(/*arg1 == 0 && */arg2 != null)
		{
    		//登陆成功                            	
        	JSONObject jObject = new JSONObject(arg2);
        	try 
        	{
    			jObject.put("valid", true);
    			jObject.put("um_code", arg1);
    			listener.onLoginSuccess(plat, jObject.toString());
    		} 
        	catch (JSONException e) 
    		{
    			listener.onLoginFail(plat, "");
    			e.printStackTrace();
    		} 
        }
		else
		{
			JSONObject jObject = new JSONObject();
			try 
			{
				jObject.put("valid", false);
				jObject.put("errorcode", arg1);
				listener.onLoginFail(plat, jObject.toString());
			} 
			catch (JSONException e) 
			{
				listener.onLoginFail(plat, "登陆发生错误："+arg1);
				e.printStackTrace();
			}				
        }
	}
	
	private ShareAction newShareAction( ShareParam param )
	{
		UMImage img = UMAsset.getUmImage(m_Context, param.sMedia);		
		if (null == img)
		{
			img = new UMImage(m_Context, R.drawable.icon);
		}
		
		ShareAction sAct = new ShareAction(m_Context);
		if ("" != param.sContent && false == param.bImageOnly)
		{
			sAct.withText(param.sContent);
		}
		if ("" != param.sTitle && false == param.bImageOnly)
		{
			sAct.withTitle(param.sTitle);
		}
		if ("" != param.sTargetURL && false == param.bImageOnly)
		{
			sAct.withTargetUrl(param.sTargetURL);
		}	
		sAct.withMedia(img);
		return sAct;
	}
	
	private UMShareListener newShareListener(final OnShareListener listener)
	{
		return new UMShareListener() 
		{
			@Override
			public void onResult(SHARE_MEDIA arg0) 
			{
				PLATFORM pt = getPlatformFrom(arg0);
				if (pt != PLATFORM.INVALIDPLAT)
				{
					listener.onComplete(pt, 200, "");
				}
				else 
				{
					listener.onError(pt, "invalid platform " + pt.toString());
				}
			}

			@Override
			public void onError(SHARE_MEDIA arg0, Throwable arg1) 
			{
				PLATFORM pt = getPlatformFrom(arg0);
				listener.onError(pt, "invalid platform " + arg1.getMessage());
			}

			@Override
			public void onCancel(SHARE_MEDIA arg0) 
			{
				PLATFORM pt = getPlatformFrom(arg0);
				listener.onCancel(pt);
			}			
		};
	}
}
