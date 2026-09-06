package dev.amber.generated

import android.os.Bundle
import android.content.res.Configuration
import android.os.SystemClock
import android.os.Parcelable
import android.util.SparseArray
import android.view.View
import android.view.accessibility.AccessibilityNodeInfo
import android.view.inputmethod.EditorInfo
import android.widget.EditText
import android.widget.TextView
import androidx.test.core.app.ActivityScenario
import androidx.lifecycle.Lifecycle
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.graphics.ColorUtils
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.UiController
import androidx.test.espresso.ViewAction
import androidx.test.espresso.action.ViewActions.*
import androidx.test.espresso.matcher.ViewMatchers.*
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.Until
import dev.assetpipeline.androidhost.CrystalBridge
import dev.assetpipeline.androidhost.HostSession
import dev.assetpipeline.androidhost.NativeSemantics
import dev.assetpipeline.androidhost.NativeTestIds
import dev.assetpipeline.androidhost.NativeViewState
import org.hamcrest.Matchers.allOf
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.regex.Pattern
import com.google.android.material.color.MaterialColors

@RunWith(AndroidJUnit4::class)
class AccountApplicationTest {
    companion object {
        // This separate debug-test APK uses only the task-owned seeded account.
        const val EMAIL = "native-emulator@example.test"
        const val PASSWORD = "Android-reference-only-2026!"
        const val EXPECTED_NAME = "Android 雪 😀 e\u0301"
        fun device() = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation())
        fun awaitText(text: String) {
            assertTrue("Expected native account state: $text", device().wait(Until.hasObject(By.text(text)), 30_000L))
        }
        fun click(id: String) = onView(NativeTestIds.withTestId(id)).perform(scrollTo(), click())
        fun field(id: String) = onView(allOf(isAssignableFrom(EditText::class.java), isDescendantOfA(NativeTestIds.withTestId(id))))
        // Espresso logs ViewAction descriptions even on success. Keep the real
        // native editing action without embedding password text in that log.
        fun enterPassword(value: String): ViewAction {
            val edit = replaceText(value)
            return object : ViewAction {
                override fun getConstraints() = edit.constraints
                override fun getDescription() = "enter synthetic account password (redacted)"
                override fun perform(controller: UiController, view: View) = edit.perform(controller, view)
            }
        }
        fun editor(activity: MainActivity, id: String) = NativeSemantics.target(requireNotNull(NativeTestIds.find(activity.window.decorView, id))) as EditText
        fun screenshot(name: String) {
            val context = InstrumentationRegistry.getInstrumentation().targetContext
            val directory = requireNotNull(context.getExternalFilesDir("account-proof")).apply { mkdirs() }
            assertTrue("Screenshot capture failed", device().takeScreenshot(File(directory, "$name.png")))
        }
        fun idleServices() {
            val deadline = SystemClock.uptimeMillis() + 20_000L
            var empty = false
            while (!empty && SystemClock.uptimeMillis() < deadline) {
                InstrumentationRegistry.getInstrumentation().runOnMainSync { empty = CrystalBridge.debugPendingServices() == Pair(0, 0) }
                if (!empty) Thread.sleep(20L)
            }
            assertTrue("Native services did not drain", empty)
        }
    }

    private fun ensureSignedOut() {
        assertTrue("Account app did not open", device().wait(Until.hasObject(By.text(
            Pattern.compile("^(Welcome to AgentC|Your account|Account settings)$"))), 30_000L))
        if (!device().hasObject(By.text("Welcome to AgentC"))) {
            click("account-signout")
            awaitText("Welcome to AgentC")
        }
    }

    private fun login() {
        field("account-email").perform(scrollTo(), replaceText(EMAIL))
        field("account-password").perform(scrollTo(), enterPassword(PASSWORD), closeSoftKeyboard())
        click("account-signin")
        awaitText("Your account")
        awaitText("Email: $EMAIL")
    }

    @Test fun realAccountFlowUsesProtectedSessionAndSharedSettingsAcrossRecreation() {
        val previousNightMode = AppCompatDelegate.getDefaultNightMode()
        val scenario = ActivityScenario.launch(MainActivity::class.java)
        try {
            ensureSignedOut()
            for (nightMode in listOf(AppCompatDelegate.MODE_NIGHT_YES, AppCompatDelegate.MODE_NIGHT_NO)) {
                InstrumentationRegistry.getInstrumentation().runOnMainSync { AppCompatDelegate.setDefaultNightMode(nightMode) }
                val deadline = SystemClock.uptimeMillis() + 15_000L
                var matched = false
                while (!matched && SystemClock.uptimeMillis() < deadline) {
                    scenario.onActivity { activity ->
                        matched = (activity.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                            (if (nightMode == AppCompatDelegate.MODE_NIGHT_YES) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO)
                    }
                    if (!matched) Thread.sleep(20L)
                }
                assertTrue("Account appearance did not change", matched)
                awaitText("Welcome to AgentC")
                field("account-email").perform(scrollTo(), replaceText(EMAIL), closeSoftKeyboard())
                scenario.onActivity { activity ->
                    for (id in listOf("account-email", "account-password")) {
                        val edit = editor(activity, id)
                        assertEquals(MaterialColors.getColor(edit, com.google.android.material.R.attr.colorOnSurface), edit.currentTextColor)
                        val background = MaterialColors.getColor(edit, com.google.android.material.R.attr.colorSurfaceVariant)
                        assertTrue("Account editor contrast is insufficient", ColorUtils.calculateContrast(edit.currentTextColor, background) >= 4.5)
                    }
                }
                screenshot(if (nightMode == AppCompatDelegate.MODE_NIGHT_YES) "signin-dark" else "signin-light")
            }
            screenshot("signin")
            field("account-email").perform(scrollTo(), replaceText(EMAIL))
            field("account-password").perform(scrollTo(), enterPassword("wrong-reference-password"), closeSoftKeyboard())
            click("account-signin")
            awaitText("The email or password was not accepted.")
            scenario.onActivity { assertEquals("", editor(it, "account-password").text.toString()) }

            field("account-password").perform(scrollTo(), enterPassword(PASSWORD))
            scenario.onActivity { activity ->
                val password = editor(activity, "account-password")
                assertTrue(password.createAccessibilityNodeInfo().isPassword)
                // The canonical host disables saving for the entire mounted
                // subtree. Test the real hierarchy traversal, not a child flag.
                val previousId = password.id
                password.id = View.generateViewId()
                try {
                    val saved = SparseArray<Parcelable>()
                    activity.window.decorView.saveHierarchyState(saved)
                    assertNull("Password editor leaked into Android saved state", saved.get(password.id))
                } finally { password.id = previousId }
                assertFalse(NativeViewState.capture(activity.window.decorView, "main").toString().contains(PASSWORD))
                assertTrue(password.requestFocus())
            }
            scenario.recreate()
            awaitText("Welcome to AgentC")
            scenario.onActivity { activity ->
                assertEquals("", editor(activity, "account-password").text.toString())
                assertEquals(EMAIL, editor(activity, "account-email").text.toString())
            }
            login()
            scenario.onActivity { activity ->
                assertFalse(CrystalBridge.canNavigateBack())
                val title = requireNotNull(NativeTestIds.find(activity.window.decorView, "account-dashboard-title"))
                assertTrue(title.createAccessibilityNodeInfo().isHeading)
            }
            click("account-open-settings")
            awaitText("Account settings")
            field("account-name").perform(scrollTo(), replaceText("Draft 雪"), closeSoftKeyboard())
            scenario.onActivity { activity ->
                assertTrue(CrystalBridge.canNavigateBack())
                editor(activity, "account-name").apply { requestFocus(); setSelection(1, 3) }
            }
            scenario.moveToState(Lifecycle.State.CREATED)
            InstrumentationRegistry.getInstrumentation().runOnMainSync { assertEquals(HostSession.State.BACKGROUND, CrystalBridge.debugSessionState()) }
            scenario.moveToState(Lifecycle.State.RESUMED)
            scenario.recreate()
            awaitText("Account settings")
            scenario.onActivity { activity ->
                val name = editor(activity, "account-name")
                assertEquals("Draft 雪", name.text.toString())
                assertTrue(name.hasFocus())
                assertEquals(1, name.selectionStart); assertEquals(3, name.selectionEnd)
            }
            field("account-name").perform(scrollTo(), replaceText("a".repeat(65)), closeSoftKeyboard())
            click("account-save-name")
            awaitText("Use at most 64 characters without control characters.")
            field("account-name").perform(scrollTo(), replaceText("Android"))
            scenario.onActivity { activity ->
                val name = editor(activity, "account-name")
                val connection = requireNotNull(name.onCreateInputConnection(EditorInfo()))
                assertTrue(connection.setSelection(name.text.length, name.text.length))
                assertTrue(connection.commitText(" 雪 😀 e\u0301", 1))
                assertEquals(EXPECTED_NAME, name.text.toString())
            }
            field("account-name").perform(closeSoftKeyboard())
            click("account-save-name")
            awaitText("Display name saved.")
            scenario.onActivity { assertEquals(EXPECTED_NAME, editor(it, "account-name").text.toString()) }
            screenshot("settings")
            onView(withContentDescription("Navigate up")).perform(scrollTo()).check { view, error ->
                if (error != null) throw error
                assertTrue(view.performAccessibilityAction(AccessibilityNodeInfo.ACTION_CLICK, null))
            }
            awaitText("Your account")
            awaitText(EXPECTED_NAME)
            screenshot("dashboard")
            click("account-refresh")
            awaitText("Account is up to date.")
            awaitText(EXPECTED_NAME)
            click("account-signout")
            awaitText("Welcome to AgentC")
            scenario.onActivity { assertFalse(CrystalBridge.canNavigateBack()) }
            login()
            awaitText(EXPECTED_NAME)
            idleServices()
        } finally {
            scenario.close()
            InstrumentationRegistry.getInstrumentation().runOnMainSync { AppCompatDelegate.setDefaultNightMode(previousNightMode) }
        }
        idleServices()
        InstrumentationRegistry.getInstrumentation().runOnMainSync {
            assertEquals(CrystalBridge.NativeDebugCounts(0, 0), CrystalBridge.debugCounts())
            assertEquals(HostSession.State.BACKGROUND, CrystalBridge.debugSessionState())
            CrystalBridge.closeSession()
            assertEquals(HostSession.State.STOPPED, CrystalBridge.debugSessionState())
        }
        InstrumentationRegistry.getInstrumentation().sendStatus(0, Bundle().apply {
            putString("account_persisted_process", android.os.Process.myPid().toString())
        })
    }
}
