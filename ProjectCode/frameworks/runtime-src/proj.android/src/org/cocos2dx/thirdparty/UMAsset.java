package org.cocos2dx.thirdparty;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;

import android.app.Activity;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.text.TextUtils;
import android.util.Log;

import com.umeng.socialize.media.UMImage;

public class UMAsset {
	//获取umimage
	public static UMImage getUmImage(Activity context, String url)
	{
		if (TextUtils.isEmpty(url)) 
		{
			return null;
		}
		if(url.startsWith("http"))
		{
			return new UMImage(context, url);
		}
		else if(url.startsWith("assets"))
		{
			return new UMImage(context, getImageFromAssetsFile(context, url));
		}
		else if(url.startsWith("res"))
		{
			int pic = context. getResources().getIdentifier(url, "drawable", context.getPackageName());
			return new UMImage(context, pic);
		}
		else if(url.startsWith("/sdcard"))
		{
			return new UMImage(context, new File(url));
		}
		else 
		{
			// 本地图片
            File imgFile = new File(url);
            if (!imgFile.exists()) 
            {
                Log.e("UMSHARE", "### 要分享的本地图片不存在");
            } 
            else 
            {
                return new UMImage(context, imgFile);
            }
		}
		return null;
	}
	
	private static Bitmap getImageFromAssetsFile(Activity context, String fileName)  
	{  
		Bitmap image = null;
		AssetManager am = context.getResources().getAssets();
		try
		{
			InputStream is = am.open(fileName.replace("assets/", ""));
			image = BitmapFactory.decodeStream(is); 
			is.close();  
		}
		catch (IOException e)
		{
			e.printStackTrace();
		}
		return image;	  
	  } 
}
