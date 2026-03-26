package network.discord;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.media.MediaMetadata;
import android.media.session.MediaSession;
import android.media.session.PlaybackState;
import android.os.Build;
import android.util.Log;
import org.haxe.extension.Extension;

import java.io.File;
import java.io.InputStream;
import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class DiscordRPCHelper extends Extension {
    private static final String TAG = "DiscordRPCHelper";
    private static final String CHANNEL_ID = "rpc_media_channel";
    private static final int NOTIFICATION_ID = 927;

    private static MediaSession mediaSession;
    private static NotificationManager notificationManager;
    private static final ExecutorService taskQueue = Executors.newSingleThreadExecutor();

    public static void initialize() {
        if (mainActivity == null || mediaSession != null) return;

        mainActivity.runOnUiThread(() -> {
            try {
                Context context = mainContext;
                notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                createNotificationChannel();

                mediaSession = new MediaSession(context, "MattRPC");
                mediaSession.setCallback(new MediaSession.Callback() {});
                mediaSession.setFlags(MediaSession.FLAG_HANDLES_TRANSPORT_CONTROLS);
                mediaSession.setActive(true);

                if (Build.VERSION.SDK_INT >= 33) {
                    mainActivity.requestPermissions(new String[]{"android.permission.POST_NOTIFICATIONS"}, 101);
                }
                Log.d(TAG, "DiscordRPCHelper initialized successfully.");
            } catch (Exception e) {
                Log.e(TAG, "Error during initialization: " + e.getMessage());
            }
        });
    }

    /**
     * Updates the Media status
     */
    public static void updateStatus(final String title, final String artist, final String imagePath) {
        if (Extension.mainActivity == null) return;

        new Thread(new Runnable() {
            @Override
            public void run() {
                final Context context = Extension.mainContext;
                Bitmap loadedArt = null;

                if (imagePath != null && !imagePath.isEmpty()) {
                    try {
                        File imgFile = new File(imagePath);
                        if (imgFile.exists()) {
                            loadedArt = BitmapFactory.decodeFile(imgFile.getAbsolutePath());
                        } else {
                            AssetManager am = context.getAssets();
                            InputStream istr = null;
                            try {
                                istr = am.open(imagePath);
                            } catch (IOException e1) {
                                try {
                                    istr = am.open("assets/" + imagePath);
                                } catch (IOException e2) {
                                    if (imagePath.startsWith("assets/")) {
                                        istr = am.open(imagePath.substring(7));
                                    }
                                }
                            }
                            if (istr != null) {
                                loadedArt = BitmapFactory.decodeStream(istr);
                                istr.close();
                            }
                        }
                    } catch (Exception e) {
                        Log.e(TAG, "Image could not be loaded: " + imagePath);
                    }
                }

                if (loadedArt == null) {
                    loadedArt = getAppIconAsBitmap(context);
                }

                final Bitmap finalAlbumArt = loadedArt;

                Extension.mainActivity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            if (mediaSession == null) { initialize(); return; }

                            MediaMetadata metadata = new MediaMetadata.Builder()
                                    .putString(MediaMetadata.METADATA_KEY_TITLE, title)
                                    .putString(MediaMetadata.METADATA_KEY_ARTIST, artist)
                                    .putBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART, finalAlbumArt)
                                    .build();
                            mediaSession.setMetadata(metadata);

                            PlaybackState state = new PlaybackState.Builder()
                                    .setActions(PlaybackState.ACTION_PLAY | PlaybackState.ACTION_PAUSE | PlaybackState.ACTION_SKIP_TO_NEXT)
                                    .setState(PlaybackState.STATE_PLAYING, 0, 1.0f)
                                    .build();
                            mediaSession.setPlaybackState(state);

                            showNotification(title, artist, finalAlbumArt);

                        } catch (Exception e) {
                            Log.e(TAG, "UPDATE ERROR: " + e.getMessage());
                        }
                    }
                });
            }
        }).start();
    }

    private static void showNotification(String title, String artist, Bitmap art) {
        Context context = Extension.mainContext;
        Notification.Builder builder;

        if (Build.VERSION.SDK_INT >= 26) {
            builder = new Notification.Builder(context, CHANNEL_ID);
        } else {
            builder = new Notification.Builder(context);
        }
        
        builder.setPriority(Notification.PRIORITY_MIN);

        Notification.MediaStyle style = new Notification.MediaStyle();
        style.setMediaSession(mediaSession.getSessionToken());
        style.setShowActionsInCompactView(0);

        int iconResId = context.getResources().getIdentifier("icon", "drawable", context.getPackageName());
        if (iconResId == 0) iconResId = android.R.drawable.sym_def_app_icon;

        builder.setVisibility(Notification.VISIBILITY_SECRET)
                .setSmallIcon(iconResId)
                .setLargeIcon(art)
                .setContentTitle(title)
                .setContentText(artist)
                .setStyle(style)
                .setOngoing(true);

        notificationManager.notify(NOTIFICATION_ID, builder.build());
    }

    private static void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID, "Background Service", NotificationManager.IMPORTANCE_MIN);
            
            channel.setDescription("Running silently");
            channel.setShowBadge(false);
            channel.setLockscreenVisibility(Notification.VISIBILITY_SECRET);
            
            if (notificationManager != null) {
                notificationManager.createNotificationChannel(channel);
            }
        }
    }

    public static void shutdown() {
        if (Extension.mainActivity == null) return;
        
        Extension.mainActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    if (mediaSession != null) {
                        mediaSession.setActive(false);
                        mediaSession.release();
                        mediaSession = null;
                    }
                    if (notificationManager != null) {
                        notificationManager.cancel(NOTIFICATION_ID);
                    }
                    Log.d(TAG, "MediaSession closed and cleared.");
                } catch (Exception e) {
                    Log.e(TAG, "SHUTDOWN ERROR: " + e.getMessage());
                }
            }
        });
    }

    private static Bitmap getAppIconAsBitmap(Context context) {
        try {
            Drawable drawable = context.getPackageManager().getApplicationIcon(context.getPackageName());
            if (drawable instanceof BitmapDrawable) {
                return ((BitmapDrawable) drawable).getBitmap();
            }
            Bitmap bitmap = Bitmap.createBitmap(drawable.getIntrinsicWidth(), drawable.getIntrinsicHeight(), Bitmap.Config.ARGB_8888);
            Canvas canvas = new Canvas(bitmap);
            drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
            drawable.draw(canvas);
            return bitmap;
        } catch (Exception e) {
            return null;
        }
    }
}