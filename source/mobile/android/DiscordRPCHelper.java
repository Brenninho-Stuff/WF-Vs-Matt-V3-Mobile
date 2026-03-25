package network.discord;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.MediaMetadata;
import android.media.session.MediaSession;
import android.media.session.PlaybackState;
import android.os.Build;
import android.util.Log;

import org.haxe.extension.Extension;

import java.io.File;
import java.io.InputStream;
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
                Log.d(TAG, "DiscordRPCHelper Inicializado com sucesso.");
            } catch (Exception e) {
                Log.e(TAG, "Erro na inicialização: " + e.getMessage());
            }
        });
    }

    /**
     * Updates the Media status
     */
    public static void updateStatus(final String title, final String artist, final String imagePath) {
        taskQueue.execute(() -> {
            try {
                if (mediaSession == null) initialize();

                Bitmap art = loadOptimizedBitmap(imagePath);
                
                boolean isPaused = (title != null && title.toLowerCase().contains("paused")) || 
                                   (artist != null && artist.toLowerCase().contains("paused"));

                updateMediaSession(title, artist, art, isPaused);
                showNotification(title, artist, art);
            } catch (Exception e) {
                Log.e(TAG, "Falha ao atualizar status: " + e.getMessage());
            }
        });
    }

    private static void updateMediaSession(String title, String artist, Bitmap art, boolean isPaused) {
        if (mediaSession == null) return;

        MediaMetadata metadata = new MediaMetadata.Builder()
                .putString(MediaMetadata.METADATA_KEY_TITLE, title)
                .putString(MediaMetadata.METADATA_KEY_ARTIST, artist)
                .putBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART, art)
                .build();

        mediaSession.setMetadata(metadata);

        int state = isPaused ? PlaybackState.STATE_PAUSED : PlaybackState.STATE_PLAYING;
        PlaybackState playbackState = new PlaybackState.Builder()
                .setState(state, PlaybackState.PLAYBACK_POSITION_UNKNOWN, 1.0f)
                .setActions(PlaybackState.ACTION_PLAY | PlaybackState.ACTION_PAUSE)
                .build();

        mediaSession.setPlaybackState(playbackState);
    }

    private static void showNotification(String title, String artist, Bitmap art) {
        if (notificationManager == null) return;

        Notification.Builder builder = (Build.VERSION.SDK_INT >= 26) 
            ? new Notification.Builder(mainContext, CHANNEL_ID) 
            : new Notification.Builder(mainContext);

        int iconResId = mainContext.getResources().getIdentifier("icon", "drawable", mainContext.getPackageName());
        if (iconResId == 0) iconResId = android.R.drawable.ic_menu_compass;

        Notification.MediaStyle style = new Notification.MediaStyle()
                .setMediaSession(mediaSession.getSessionToken())
                .setShowActionsInCompactView(0);

        builder.setSmallIcon(iconResId)
                .setLargeIcon(art)
                .setContentTitle(title)
                .setContentText(artist)
                .setStyle(style)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .setOngoing(true);

        notificationManager.notify(NOTIFICATION_ID, builder.build());
    }

    private static Bitmap loadOptimizedBitmap(String path) {
        try {
            Bitmap rawBitmap = null;
            if (path == null || path.isEmpty()) return null;

            File file = new File(path);
            if (file.exists()) {
                rawBitmap = BitmapFactory.decodeFile(path);
            } else {
                AssetManager assets = mainContext.getAssets();
                String formattedPath = path.replace("assets/", "");
                InputStream is = assets.open(formattedPath);
                rawBitmap = BitmapFactory.decodeStream(is);
                is.close();
            }

            if (rawBitmap != null) {
                return Bitmap.createScaledBitmap(rawBitmap, 256, 256, true);
            }
        } catch (Exception e) {
            Log.e(TAG, "Erro ao processar imagem: " + path);
        }
        return null;
    }

    private static void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID, "Jogo em Execução", NotificationManager.IMPORTANCE_LOW);
            channel.setSound(null, null);
            channel.enableVibration(false);
            notificationManager.createNotificationChannel(channel);
        }
    }

    public static void shutdown() {
        mainActivity.runOnUiThread(() -> {
            try {
                if (mediaSession != null) {
                    mediaSession.setActive(false);
                    mediaSession.release();
                    mediaSession = null;
                }
                if (notificationManager != null) {
                    notificationManager.cancel(NOTIFICATION_ID);
                }
            } catch (Exception e) {
                Log.e(TAG, "Erro ao encerrar: " + e.getMessage());
            }
        });
    }
}