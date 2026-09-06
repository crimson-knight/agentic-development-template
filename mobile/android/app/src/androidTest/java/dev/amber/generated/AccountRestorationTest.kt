package dev.amber.generated

import android.os.Bundle
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import dev.assetpipeline.androidhost.CrystalBridge
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class AccountRestorationTest {
    @Test fun protectedSessionRestoresInANewProcessAndLogoutRemovesIt() {
        val previous = requireNotNull(InstrumentationRegistry.getArguments().getString("previous_pid")).toInt()
        assertNotEquals(previous, android.os.Process.myPid())
        val scenario = ActivityScenario.launch(MainActivity::class.java)
        try {
            AccountApplicationTest.awaitText("Your account")
            AccountApplicationTest.awaitText(AccountApplicationTest.EXPECTED_NAME)
            AccountApplicationTest.awaitText("Account is up to date.")
            AccountApplicationTest.screenshot("restored-account")
            AccountApplicationTest.click("account-signout")
            AccountApplicationTest.awaitText("Welcome to AgentC")
            AccountApplicationTest.idleServices()
        } finally { scenario.close() }
        InstrumentationRegistry.getInstrumentation().runOnMainSync {
            assertEquals(CrystalBridge.NativeDebugCounts(0, 0), CrystalBridge.debugCounts())
            assertEquals(Pair(0, 0), CrystalBridge.debugPendingServices())
        }
        InstrumentationRegistry.getInstrumentation().sendStatus(0, Bundle().apply {
            putString("account_restored_process", android.os.Process.myPid().toString())
        })
    }
}
