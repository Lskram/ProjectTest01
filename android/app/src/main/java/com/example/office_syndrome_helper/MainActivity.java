package com.example.office_syndrome_helper;

import android.os.Bundle;
import android.content.Intent;
import android.util.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

/**
 * MainActivity for Office Syndrome Helper
 * Handles Flutter-Android communication and boot receiver callbacks
 */
public class MainActivity extends FlutterActivity {
    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "com.example.office_syndrome_helper/boot";
    private static final String NOTIFICATION_CHANNEL = "com.example.office_syndrome_helper/notification";
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(TAG, "MainActivity created");
        
        // Handle notification tap intent
        handleNotificationIntent(getIntent());
    }
    
    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        Log.d(TAG, "New intent received");
        handleNotificationIntent(intent);
    }
    
    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        // Boot receiver method channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "onBootCompleted":
                        Log.d(TAG, "Handling boot completed from Flutter");
                        handleBootCompleted();
                        result.success(true);
                        break;
                        
                    case "onPackageReplaced":
                        Log.d(TAG, "Handling package replaced from Flutter");
                        handlePackageReplaced();
                        result.success(true);
                        break;
                        
                    default:
                        result.notImplemented();
                        break;
                }
            });
        
        // Notification method channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), NOTIFICATION_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "handleNotificationAction":
                        String action = call.argument("action");
                        String sessionId = call.argument("sessionId");
                        Log.d(TAG, "Handling notification action: " + action + " for session: " + sessionId);
                        handleNotificationAction(action, sessionId);
                        result.success(true);
                        break;
                        
                    case "openAppSettings":
                        Log.d(TAG, "Opening app settings");
                        openAppSettings();
                        result.success(true);
                        break;
                        
                    default:
                        result.notImplemented();
                        break;
                }
            });
    }
    
    /**
     * Handle notification intent when app is opened from notification
     */
    private void handleNotificationIntent(Intent intent) {
        if (intent == null) return;
        
        String action = intent.getAction();
        String sessionId = intent.getStringExtra("sessionId");
        
        if (action != null && sessionId != null) {
            Log.d(TAG, "Notification intent: " + action + ", sessionId: " + sessionId);
            
            // Send to Flutter via method channel
            if (getFlutterEngine() != null) {
                new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), NOTIFICATION_CHANNEL)
                    .invokeMethod("onNotificationTapped", Map.of(
                        "action", action,
                        "sessionId", sessionId
                    ));
            }
        }
    }
    
    /**
     * Handle boot completed event
     */
    private void handleBootCompleted() {
        try {
            Log.d(TAG, "Processing boot completed");
            
            // Notify Flutter that boot was completed
            if (getFlutterEngine() != null) {
                new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                    .invokeMethod("onBootCompleted", null);
            }
            
        } catch (Exception e) {
            Log.e(TAG, "Error handling boot completed", e);
        }
    }
    
    /**
     * Handle package replacement event
     */
    private void handlePackageReplaced() {
        try {
            Log.d(TAG, "Processing package replacement");
            
            // Notify Flutter that app was updated
            if (getFlutterEngine() != null) {
                new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                    .invokeMethod("onPackageReplaced", null);
            }
            
        } catch (Exception e) {
            Log.e(TAG, "Error handling package replacement", e);
        }
    }
    
    /**
     * Handle notification actions (snooze, skip, start)
     */
    private void handleNotificationAction(String action, String sessionId) {
        try {
            Log.d(TAG, "Processing notification action: " + action);
            
            // Forward to Flutter
            if (getFlutterEngine() != null) {
                new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), NOTIFICATION_CHANNEL)
                    .invokeMethod("handleNotificationAction", Map.of(
                        "action", action,
                        "sessionId", sessionId
                    ));
            }
            
        } catch (Exception e) {
            Log.e(TAG, "Error handling notification action", e);
        }
    }
    
    /**
     * Open app settings for permissions
     */
    private void openAppSettings() {
        try {
            Intent intent = new Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            intent.setData(android.net.Uri.parse("package:" + getPackageName()));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
            
        } catch (Exception e) {
            Log.e(TAG, "Error opening app settings", e);
            
            // Fallback to general settings
            try {
                Intent fallbackIntent = new Intent(android.provider.Settings.ACTION_SETTINGS);
                fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(fallbackIntent);
            } catch (Exception fallbackException) {
                Log.e(TAG, "Error opening fallback settings", fallbackException);
            }
        }
    }
    
    @Override
    protected void onDestroy() {
        Log.d(TAG, "MainActivity destroyed");
        super.onDestroy();
    }
}