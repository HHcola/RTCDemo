package io.agora.agoraduo.ui;

import android.graphics.Color;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;

import io.agora.agoraduo.R;
import io.agora.agoraduo.utils.StatusBarCompat;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

//        StatusBarCompat.compat(this, Color.TRANSPARENT);
    }
}
