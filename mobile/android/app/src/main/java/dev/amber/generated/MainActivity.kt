package dev.amber.generated

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import android.widget.FrameLayout
import android.widget.ScrollView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import dev.assetpipeline.androidhost.CrystalBridge
import dev.assetpipeline.androidhost.NativeNavigation
import dev.assetpipeline.androidhost.NativeScreenHost
import dev.assetpipeline.androidhost.NativeSemantics

class MainActivity : AppCompatActivity() {
    private lateinit var mount: FrameLayout
    private val handler = Handler(Looper.getMainLooper())
    private var visible = false
    private lateinit var navigation: NativeNavigation
    private lateinit var screenHost: NativeScreenHost
    private var pendingUserAction = false
    private val refresh: Runnable = object : Runnable {
        override fun run() {
            if (visible && !isFinishing && !isDestroyed) {
                if (render(pendingUserAction)) pendingUserAction = false
                else handler.postDelayed(this, 32L)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val scroll = ScrollView(this).apply { isFillViewport = true }
        mount = FrameLayout(this)
        scroll.addView(mount, FrameLayout.LayoutParams(-1, -2))
        setContentView(scroll)
        ViewCompat.setOnApplyWindowInsetsListener(scroll) { view, insets ->
            val safe = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.ime())
            view.setPadding(safe.left, safe.top, safe.right, safe.bottom)
            insets
        }
        ViewCompat.requestApplyInsets(scroll)
        CrystalBridge.initialize("asset_pipeline_app", applicationContext)
        CrystalBridge.attachHost(this)
        navigation = NativeNavigation(this)
        screenHost = NativeScreenHost(this, mount, scroll, savedInstanceState)
        CrystalBridge.callbackObserver = {
            pendingUserAction = pendingUserAction || CrystalBridge.refreshCause == CrystalBridge.RefreshCause.ACTION
            handler.removeCallbacks(refresh)
            handler.postDelayed(refresh, 250L)
        }
    }

    override fun onStart() {
        super.onStart()
        CrystalBridge.foregroundHost(this)
        visible = true
        render(true)
    }

    override fun onStop() {
        visible = false
        handler.removeCallbacks(refresh)
        CrystalBridge.backgroundHost(this)
        super.onStop()
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (visible && ::mount.isInitialized && event.hasNoModifiers() && NativeSemantics.dispatchShortcut(mount, event, unmodifiedOnly = true)) return true
        return super.dispatchKeyEvent(event)
    }

    override fun dispatchKeyShortcutEvent(event: KeyEvent): Boolean {
        if (visible && ::mount.isInitialized && NativeSemantics.dispatchShortcut(mount, event)) return true
        return super.dispatchKeyShortcutEvent(event)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        screenHost.saveState(outState)
        super.onSaveInstanceState(outState)
    }

    private fun render(userAction: Boolean = false): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (!screenHost.render("main", userAction)) return false
        navigation.synchronize()
        return true
    }

    override fun onDestroy() {
        handler.removeCallbacks(refresh)
        screenHost.close()
        mount.removeAllViews()
        CrystalBridge.detachHost(this)
        super.onDestroy()
    }
}
