pluginManagement {
    val toolchain = java.util.Properties().apply {
        val file = file("../../lib/asset_pipeline/config/android_toolchain.env")
        check(file.isFile) { "Install the Android-capable AssetPipeline shard first (shards install)." }
        file.inputStream().use { load(it) }
    }
    plugins {
        id("com.android.application") version toolchain.getProperty("ANDROID_AGP_VERSION")
        id("org.jetbrains.kotlin.android") version toolchain.getProperty("ANDROID_KOTLIN_VERSION")
    }
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}

val toolchain = java.util.Properties().apply {
    file("../../lib/asset_pipeline/config/android_toolchain.env").inputStream().use { load(it) }
}
check(gradle.gradleVersion == toolchain.getProperty("ANDROID_GRADLE_VERSION")) {
    "The wrapper must match the installed AssetPipeline Android toolchain. Regenerate after a toolchain upgrade."
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories { google(); mavenCentral() }
}
rootProject.name = "native_app"
include(":app")
