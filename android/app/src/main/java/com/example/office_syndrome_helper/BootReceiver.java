package com.example.office_syndrome_helper;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.FlutterEngineCache;

/**
 * Boot Receiver to handle device boot and app updates
 * Re-schedules notifications after system restart
 */
public class BootReceiver extends BroadcastReceiver {
    private static final String TAG = "BootReceiver";
    private static final String CHANNEL = "com.example.office_syndrome_helper/boot";
    
    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        Log.d(TAG, "Received broadcast: " + action);
        
        if (action == null) return;
        
        switch (action) {
            case Intent.ACTION_BOOT_COMPLETED:
                Log.d(TAG, "Device boot completed");
                handleBootCompleted(context);
                break;
                
            case Intent.ACTION_MY_PACKAGE_REPLACED:
            case Intent.ACTION_PACKAGE_REPLACED:
                Log.d(TAG, "Package updated/replaced");
                handlePackageReplaced(context);
                break;
                
            default:
                Log.d(TAG, "Unhandled action: " + action);
                break;
        }
    }
    
    private void handleBootCompleted(Context context) {
        try {
            Log.d(TAG, "Starting Flutter engine for boot handling...");
            
            // Initialize Flutter engine in background
            FlutterEngine flutterEngine = new FlutterEngine(context);
            
            // Start Dart execution
            flutterEngine.getDartExecutor().executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            );
            
            // Cache the engine
            FlutterEngineCache.getInstance().put("boot_engine", flutterEngine);
            
            // Create method channel to communicate with Dart
            new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .invokeMethod("onBootCompleted", null, new MethodChannel.Result() {
                    @Override
                    public void success(Object result) {
                        Log.d(TAG, "Boot handling completed successfully");
                        cleanup();
                    }
                    
                    @Override
                    public void error(String errorCode, String errorMessage, Object errorDetails) {
                        Log.e(TAG, "Boot handling failed: " + errorMessage);
                        cleanup();
                    }
                    
                    @Override
                    public void notImplemented() {
                        Log.e(TAG, "Boot handling method not implemented");
                        cleanup();
                    }
                    
                    private void cleanup() {
                        // Clean up the Flutter engine
                        FlutterEngineCache.getInstance().remove("boot_engine");
                    }
                });
                
        } catch (Exception e) {
            Log.e(TAG, "Error handling boot completed", e);
        }
    }
    
    private void handlePackageReplaced(Context context) {
        try {
            Log.d(TAG, "Starting Flutter engine for package replacement handling...");
            
            // Similar to boot completed but for app updates
            FlutterEngine flutterEngine = new FlutterEngine(context);
            
            flutterEngine.getDartExecutor().executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            );
            
            FlutterEngineCache.getInstance().put("update_engine", flutterEngine);
            
            new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .invokeMethod("onPackageReplaced", null, new MethodChannel.Result() {
                    @Override
                    public void success(Object result) {
                        Log.d(TAG, "Package replacement handling completed successfully");
                        cleanup();
                    }
                    
                    @Override
                    public void error(String errorCode, String errorMessage, Object errorDetails) {
                        Log.e(TAG, "Package replacement handling failed: " + errorMessage);
                        cleanup();
                    }
                    
                    @Override
                    public void notImplemented() {
                        Log.e(TAG, "Package replacement handling method not implemented");
                        cleanup();
                    }
                    
                    private void cleanup() {
                        FlutterEngineCache.getInstance().remove("update_engine");
                    }
                });
                
        } catch (Exception e) {
            Log.e(TAG, "Error handling package replacement", e);
        }
    }
}