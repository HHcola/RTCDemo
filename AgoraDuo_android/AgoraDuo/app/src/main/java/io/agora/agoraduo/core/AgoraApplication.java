package io.agora.agoraduo.core;

import android.app.Application;

import io.agora.AgoraAPI;
import io.agora.AgoraAPIOnlySignal;
import io.agora.agoraduo.agroabase.RtcEngineEventHandler;
import io.agora.agoraduo.agroabase.SignalEngineEventHandler;
import io.agora.agoraduo.agroabase.BaseEngineEventHandlerActivity;
import io.agora.agoraduo.model.Global;
import io.agora.rtc.RtcEngine;

/**
 * Created by admin on 2016/9/28.
 */

public class AgoraApplication extends Application {

    private RtcEngine mRtcEngine;
    private AgoraAPIOnlySignal mSignalEngine;
    private RtcEngineEventHandler mRtcEngineEventHandler;
    private SignalEngineEventHandler mSignalEventHandler;

    @Override
    public void onCreate(){
        super.onCreate();
    }

    public AgoraAPIOnlySignal getSignalEngine(){
        if (mSignalEngine == null){
            //STEP 1: 初始化信令引擎
            mSignalEventHandler = new SignalEngineEventHandler();
            mSignalEngine = AgoraAPI.getInstance(getApplicationContext(), Global.APP_ID);
        }
        mSignalEngine.callbackSet(mSignalEventHandler);
        return mSignalEngine;
    }

    public RtcEngine getRtcEngine(){
        if (mRtcEngine == null) {
            //STEP 1: 初始化RTC引擎
            mRtcEngineEventHandler = new RtcEngineEventHandler();
            mRtcEngine = RtcEngine.create(getApplicationContext(), Global.APP_ID, mRtcEngineEventHandler);
        }
        return mRtcEngine;
    }

    public void setEngineEventHandlerActivity(BaseEngineEventHandlerActivity engineEventHandlerActivity){
        mRtcEngineEventHandler.setActivity(engineEventHandlerActivity);
    }

    public void addSignalEventHandlerActivity(BaseEngineEventHandlerActivity engineEventHandlerActivity){
        mSignalEventHandler.addActivity(engineEventHandlerActivity);
    }

}
