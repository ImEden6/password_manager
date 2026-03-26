package com.passwordmanager.password_manager

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // This flag blurs the app in the recent apps switcher and blocks screenshots
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}

