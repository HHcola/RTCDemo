package io.agora.agoraduo.core.mvp;

/**
 * Created by admin on 2016/9/28.
 */

public interface Presenter<V extends MvpView> {

    void attachView(V mvpView);

    void detachView();
}
