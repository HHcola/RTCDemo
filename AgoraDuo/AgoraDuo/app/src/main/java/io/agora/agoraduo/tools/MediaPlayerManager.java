package io.agora.agoraduo.tools;

import android.content.Context;
import android.media.MediaPlayer;
import android.util.Log;

/**
 * Created by Administrator on 2016/10/5.
 */

public class MediaPlayerManager {
    private static final String TAG = MediaPlayerManager.class.getSimpleName();
    private Context context;
    private MediaPlayer mediaPlayer;
    private int resId;
    public MediaPlayerManager(){

    }

    public MediaPlayerManager init(Context context,int resId){
        this.context = context;
        this.resId = resId;
        mediaPlayer = MediaPlayer.create(context,resId);
        mediaPlayer.setLooping(true);
        mediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
            @Override
            public void onCompletion(MediaPlayer mp) {
            }
        });
        mediaPlayer.setOnErrorListener(new MediaPlayer.OnErrorListener() {
            @Override
            public boolean onError(MediaPlayer mp, int what, int extra) {
                Log.e(TAG, "onError: what = " + what + "extra = " + extra );
                return false;
            }
        });
        return this;
    }

    public void deInit(){
        mediaPlayer.release();
        mediaPlayer = null;
        context = null;
    }

    public boolean isPlaying(){
        return mediaPlayer.isPlaying();
    }

    public void pause(){
        mediaPlayer.pause();
    }

    public void play(){
        Log.e(TAG, "play: ");
        if (mediaPlayer == null){
            mediaPlayer = MediaPlayer.create(context,resId);
            mediaPlayer.setLooping(true);
        }
        if (mediaPlayer.isPlaying()) {
            return;
        }

//        mediaPlayer.seekTo(0);
        mediaPlayer.start();
    }

    public void stop(){
        Log.e(TAG, "stop: ");
//        mediaPlayer.release();
//        mediaPlayer = null;
        if (mediaPlayer.isPlaying())
            mediaPlayer.pause();
//        mediaPlayer.stop();
//        mediaPlayer.seekTo(0);
//        mediaPlayer.prepareAsync();
//        try {
//            mediaPlayer.prepare();
//        } catch (IOException e) {
//            e.printStackTrace();
//        }
    }
}
