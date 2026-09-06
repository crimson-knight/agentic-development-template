import java.util.Properties
import java.io.File

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}
val assetPipeline = rootProject.file("../../lib/asset_pipeline")
val nativeAssetRoot = rootProject.file("../..")
val generatedImages = layout.buildDirectory.dir("generated/assetPipelineImages")
val compileImages by tasks.registering(Exec::class) {
    group = "build"
    description = "Compile the explicit application image catalog into Android resources."
    commandLine("crystal", "run", assetPipeline.resolve("scripts/compile_android_assets.cr").absolutePath,
        "--", nativeAssetRoot.absolutePath, "config/android_assets.yml", generatedImages.get().asFile.absolutePath)
    outputs.dir(generatedImages)
    outputs.upToDateWhen { false }
}
val toolchain = Properties().apply {
    assetPipeline.resolve("config/android_toolchain.env").inputStream().use { load(it) }
}
val app = Properties().apply {
    rootProject.file("android-app.properties").inputStream().use { load(it) }
}
val buildCrystal by tasks.registering(Exec::class) {
    group = "build"
    description = "Build the application's Crystal runtime for every selected Android ABI."
    workingDir = rootProject.projectDir
    commandLine("bash", rootProject.file("build_crystal_lib.sh").absolutePath)
}
// Explicit localhost proof trust, generated into debug-only inputs. No app or
// release source contains a certificate, key or permissive trust-manager code.
val accountTestCa = providers.gradleProperty("agentcTestCa").orNull
val accountDebugTls = layout.buildDirectory.dir("generated/accountDebugTls")
val prepareAccountDebugTls by tasks.registering {
    onlyIf { accountTestCa != null }
    outputs.upToDateWhen { false }
    doLast {
        require(System.getenv("AGENTC_ANDROID_API_ORIGIN")?.matches(Regex("https://localhost:[0-9]{1,5}")) == true) {
            "Account test trust requires an explicit localhost HTTPS proof origin"
        }
        val certificate = File(requireNotNull(accountTestCa)).readText()
        require(certificate.toByteArray().size <= 32768 && certificate.contains("BEGIN CERTIFICATE") &&
            !certificate.contains("PRIVATE KEY")) { "Supply a public task CA certificate, never a private key" }
        val output = accountDebugTls.get().asFile
        output.resolve("res/raw").mkdirs()
        output.resolve("res/xml").mkdirs()
        output.resolve("res/raw/agentc_test_ca.pem").writeText(certificate)
        output.resolve("res/xml/agentc_test_network_security.xml").writeText("""
            <network-security-config>
              <base-config cleartextTrafficPermitted="false"><trust-anchors><certificates src="system" /></trust-anchors></base-config>
              <domain-config cleartextTrafficPermitted="false"><domain includeSubdomains="false">localhost</domain>
                <trust-anchors><certificates src="@raw/agentc_test_ca" /></trust-anchors>
              </domain-config>
            </network-security-config>
        """.trimIndent())
        output.resolve("AndroidManifest.xml").writeText("""
            <manifest xmlns:android="http://schemas.android.com/apk/res/android">
              <application android:networkSecurityConfig="@xml/agentc_test_network_security" />
            </manifest>
        """.trimIndent())
    }
}
android {
    namespace = "dev.amber.generated"
    compileSdk = app.getProperty("compileSdk").toInt()
    buildToolsVersion = toolchain.getProperty("ANDROID_BUILD_TOOLS_VERSION")
    ndkVersion = toolchain.getProperty("ANDROID_NDK_VERSION")
    defaultConfig {
        applicationId = app.getProperty("applicationId")
        minSdk = app.getProperty("minSdk").toInt()
        targetSdk = app.getProperty("targetSdk").toInt()
        versionCode = app.getProperty("versionCode").toInt()
        versionName = app.getProperty("versionName")
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        ndk { abiFilters += app.getProperty("abis").split(',') }
    }
    buildTypes {
        release {
            isMinifyEnabled = false
            ndk.debugSymbolLevel = "FULL"
            // Supply release signing outside source control before distribution.
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.toVersion(toolchain.getProperty("ANDROID_JAVA_VERSION"))
        targetCompatibility = JavaVersion.toVersion(toolchain.getProperty("ANDROID_JAVA_VERSION"))
    }
    kotlinOptions { jvmTarget = toolchain.getProperty("ANDROID_JAVA_VERSION") }
    sourceSets.getByName("main").java.srcDir(assetPipeline.resolve("android/runtime/src/main/java"))
    sourceSets.getByName("main").res.srcDir(assetPipeline.resolve("android/runtime/src/main/res"))
    sourceSets.getByName("main").res.srcDir(generatedImages.map { it.dir("res") })
    sourceSets.getByName("test").java.srcDir(assetPipeline.resolve("android/runtime/src/test/java"))
    sourceSets.getByName("androidTest").java.srcDir(assetPipeline.resolve("android/runtime/src/androidTest/java"))
    if (accountTestCa != null) {
        sourceSets.getByName("debug").res.srcDir(accountDebugTls.map { it.dir("res") })
        sourceSets.getByName("debug").manifest.srcFile(accountDebugTls.map { it.file("AndroidManifest.xml") })
    }
}
tasks.matching { it.name == "preBuild" }.configureEach { dependsOn(buildCrystal, compileImages) }
tasks.matching { it.name == "preDebugBuild" }.configureEach { dependsOn(prepareAccountDebugTls) }
dependencies {
    testImplementation("junit:junit:4.13.2")
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test:core:1.6.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
    androidTestImplementation("androidx.test.uiautomator:uiautomator:2.3.0")
}
apply(from = assetPipeline.resolve("android/runtime/dependencies.gradle.kts"))
