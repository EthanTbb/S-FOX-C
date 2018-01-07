
package org.cocos2dx.utils;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.security.PermissionCollection;

import org.cocos2dx.lua.AppActivity;

import android.R.bool;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Handler;
import android.os.Process;
import android.util.Log;

public class MP3Recorder {
    private String filePath;
    private int sampleRate;
    private boolean isRecording = false;
    private boolean isPause = false;
    private boolean isCancel = false;
    private Handler handler;    
    AudioRecord audioRecord = null;
    private int minBufferSize = 0;

    /**
     * 开始录音
     */
    public static final int MSG_REC_STARTED = 1;

    /**
     * 结束录音
     */
    public static final int MSG_REC_STOPPED = 2;

    /**
     * 暂停录音
     */
    public static final int MSG_REC_PAUSE = 3;

    /**
     * 继续录音
     */
    public static final int MSG_REC_RESTORE = 4;

    /**
     * 缓冲区挂了,采样率手机不支持
     */
    public static final int MSG_ERROR_GET_MIN_BUFFERSIZE = -1;

    /**
     * 创建文件时扑街了
     */
    public static final int MSG_ERROR_CREATE_FILE = -2;

    /**
     * 初始化录音器时扑街了
     */
    public static final int MSG_ERROR_REC_START = -3;

    /**
     * 录音的时候出错
     */
    public static final int MSG_ERROR_AUDIO_RECORD = -4;

    /**
     * 编码时挂了
     */
    public static final int MSG_ERROR_AUDIO_ENCODE = -5;

    /**
     * 写文件时挂了
     */
    public static final int MSG_ERROR_WRITE_FILE = -6;

    /**
     * 没法关闭文件流
     */
    public static final int MSG_ERROR_CLOSE_FILE = -7;

    public MP3Recorder(String filePath, int sampleRate) {
        this.filePath = filePath;
        this.sampleRate = sampleRate;
    }
    
    public void init(){
    	
    }

    /**
     * 开片
     */
    public void start( final AppActivity context ) {
        if (isRecording) {
            return;
        }
        
        new Thread(){
            @Override
            public void run() {
            	Log.e("MP3Record", "run record");
            	Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO);
            	
            	// 根据定义好的几个配置，来获取合适的缓冲大小
            	minBufferSize = AudioRecord.getMinBufferSize(sampleRate,
                        AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT);
            	if (minBufferSize < 0) {
                    return;
                }
            	audioRecord = new AudioRecord(MediaRecorder.AudioSource.MIC,
                        sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT,
                        minBufferSize * 2);

                // 5秒的缓冲
                short[] buffer = new short[sampleRate * (16 / 8) * 1 * 5];
                byte[] mp3buffer = new byte[(int)(7200 + buffer.length * 2 * 1.25)];

                FileOutputStream output = null;
                try {
                    output = new FileOutputStream(new File(filePath));
                } catch (FileNotFoundException e) {
                    return;
                }
                MP3Recorder.init(sampleRate, 1, sampleRate,8);
                isRecording = true; // 录音状态
                isPause = false; // 录音状态
                isCancel = false;
                boolean bRecordValid = true;
                try {                	
                    try {
                        audioRecord.startRecording(); // 开启录音获取音频数据
                    } catch (IllegalStateException e) {
                    	Log.e("MP3Record", "audioRecord.startRecording IllegalStateException");
                    	context.toLuaGlobalFunC("g_NativeRecord", "record error");
                    	//audioRecord.stop();
                        audioRecord.release();
                        audioRecord = null;
                        MP3Recorder.close();
                        try {
                            output.close();
                        } catch (IOException e1) {
                        	
                        }
                        return;
                    }

                    try {
                        int readSize = 0;
                        boolean pause = false;
                        while (isRecording) {
                            /*--暂停--*/
                            if (isPause) {
                                if (!pause) {
                                    pause = true;
                                }
                                continue;
                            }
                            if (pause) {
                                pause = false;
                            }
                            if (audioRecord.getRecordingState() == AudioRecord.RECORDSTATE_STOPPED){
                            	bRecordValid = false;
                            	break;
                            }
                            /*--End--*/
                            /*--实时录音写数据--*/
                            readSize = audioRecord.read(buffer, 0, minBufferSize);
                            if (readSize <= 0) {
                            	bRecordValid = false;
                            	Log.e("MP3Record", "audioRecord.read < 0, valid ==> " + bRecordValid);
                            	context.toLuaGlobalFunC("g_NativeRecord", "record error");                            	
                                break;
                            } else if(bRecordValid){
                                int encResult = MP3Recorder.encode(buffer, buffer, readSize,
                                        mp3buffer);
                                if (encResult < 0) {
                                	bRecordValid = false;
                                    break;
                                }
                                if (encResult != 0) {
                                    try {
                                        output.write(mp3buffer, 0, encResult);
                                    } catch (IOException e) {
                                    	bRecordValid = false;
                                    	Log.e("MP3Record", "output.write IOException");
                                    	context.toLuaGlobalFunC("g_NativeRecord", "record error");
                                        break;
                                    }
                                }
                            }
                            /*--End--*/
                        }
                        /*--录音完--*/
                        int flushResult = 0;
                        if (false == isCancel && true == bRecordValid){
                        	flushResult = MP3Recorder.flush(mp3buffer);
                        }
                        if (flushResult > 0) {
                            try {
                                output.write(mp3buffer, 0, flushResult);
                            } catch (IOException e) {
                            	Log.e("MP3Record", "output.write IOException 2");
                            	context.toLuaGlobalFunC("g_NativeRecord", "record error");
                            }
                        }
                        try {
                            output.close();
                        } catch (IOException e) {
                        	
                        }
                        /*--End--*/
                    } finally {
                    	if (null != audioRecord){
                    		if (audioRecord.getRecordingState() == AudioRecord.RECORDSTATE_RECORDING){
                    			audioRecord.stop();
                    		}                    		
                            audioRecord.release();
                            audioRecord = null;
                    	}                        
                        MP3Recorder.close();
                    }
                } finally {                    
                    if (null != audioRecord){
                    	audioRecord.release();
                        audioRecord = null;
                    }   
                    MP3Recorder.close();
                    isRecording = false;
                    isCancel = false;
                    try {
                        output.close();
                    } catch (IOException e) {
                    	
                    }
                }
            }
        }.start();
    }

    public void stop() {
    	System.out.println("record stop");
        isRecording = false;
        if (null != audioRecord && audioRecord.getRecordingState() == AudioRecord.RECORDSTATE_RECORDING){
        	audioRecord.stop();
        }
    }
    
    public void cancel(){
    	isRecording = false;
    	isCancel = true;
    	if (null != audioRecord && audioRecord.getRecordingState() == AudioRecord.RECORDSTATE_RECORDING){
        	audioRecord.stop();
        }
    }

    public void pause() {
        isPause = true;
    }

    public void restore() {
        isPause = false;
    }

    public boolean isRecording() {
        return isRecording;
    }

    public boolean isPaus() {
        if (!isRecording) {
            return false;
        }
        return isPause;
    }

    /**
     * 录音状态管理
     * 
     * @see RecMicToMp3#MSG_REC_STARTED
     * @see RecMicToMp3#MSG_REC_STOPPED
     * @see RecMicToMp3#MSG_REC_PAUSE
     * @see RecMicToMp3#MSG_REC_RESTORE
     * @see RecMicToMp3#MSG_ERROR_GET_MIN_BUFFERSIZE
     * @see RecMicToMp3#MSG_ERROR_CREATE_FILE
     * @see RecMicToMp3#MSG_ERROR_REC_START
     * @see RecMicToMp3#MSG_ERROR_AUDIO_RECORD
     * @see RecMicToMp3#MSG_ERROR_AUDIO_ENCODE
     * @see RecMicToMp3#MSG_ERROR_WRITE_FILE
     * @see RecMicToMp3#MSG_ERROR_CLOSE_FILE
     */
    public void setHandle(Handler handler) {
        this.handler = handler;
    }

    /*--以下为Native部分--*/
    static {
        System.loadLibrary("mp3lame");
    }

    /**
     * 初始化录制参数
     */
    public static void init(int inSamplerate, int outChannel, int outSamplerate, int outBitrate) {
        init(inSamplerate, outChannel, outSamplerate, outBitrate, 9);
    }

    /**
     * 初始化录制参数
     * quality:0=很好很慢 9=很差很快
     */
    public native static void init(int inSamplerate, int outChannel, int outSamplerate,
            int outBitrate, int quality);

    /**
     * 音频数据编码(PCM左进,PCM右进,MP3输出)
     */
    public native static int encode(short[] buffer_l, short[] buffer_r, int samples, byte[] mp3buf);

    /**
     * 刷净缓冲区
     */
    public native static int flush(byte[] mp3buf);

    /**
     * 结束编码
     */
    public native static void close();
}
