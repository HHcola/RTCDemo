package io.agora.agoraduo.tools;

import android.content.Context;
import android.media.AudioManager;
import android.media.SoundPool;
import android.util.SparseIntArray;

/**
 * Created by Administrator on 2016/10/5.
 */

public class SoundPoolManager {
    private SoundPool soundPool;
    private Context context;
    private SparseIntArray soundMap;

    private SoundPool.OnLoadCompleteListener defaultOnLoadCompleteListener =
            new SoundPool.OnLoadCompleteListener() {
                @Override
                public void onLoadComplete(SoundPool soundPool, int sampleId, int status) {

                }
            };

    public SoundPoolManager() {
    }

    public SoundPoolManager init(Context context) {
        this.context = context;
        soundPool = new SoundPool(1, AudioManager.STREAM_MUSIC, 1);
        soundMap = new SparseIntArray();
        return this;
    }

    public void deInit() {
        soundPool.release();
        context = null;
    }

    public SoundPoolManager setOnLoadCompleteListener(SoundPool.OnLoadCompleteListener listener) {
        this.defaultOnLoadCompleteListener = listener;
        return this;
    }

    public SoundPoolManager setPlaySource(int rawRId) {
        soundMap.put(1, soundPool.load(context, rawRId, 1));
        return this;
    }

    public void play() {
        soundPool.play(soundMap.get(1), 1f, 1f, 1, -1, 1f);
    }

    public void stop(){
        soundPool.stop(soundMap.get(1));
    }

    public void pause(){
        soundPool.pause(soundMap.get(1));
    }

    public void resume(){
        soundPool.resume(soundMap.get(1));
    }

}
