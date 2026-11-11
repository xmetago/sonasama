allprojects {
    repositories {
        google()
        mavenCentral()
        // Maven Central alternatifi (repo.maven.apache.org erişilemezse)
        maven { url = uri("https://repo1.maven.org/maven2/") }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Eski eklentiler (file_picker 8) compileSdk 34 yazıyor. AGP 9, 36 isteyen
// AndroidX kaydını bu yüzden reddediyor. finalizeDsl, eklentinin kendi
// bloğundan sonra ve kilitlenmeden önce değeri yükseltir. Uygulama modülü
// flutter.compileSdkVersion kullanmaya devam eder.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension>(
            "androidComponents",
        ) {
            finalizeDsl { ext ->
                ext.compileSdk = 36
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Java 8 uyarılarını bastır (eski Flutter plugin'leri Java 8 kullanıyor)
gradle.projectsEvaluated {
    subprojects.forEach { subproject ->
        subproject.tasks.withType<JavaCompile>().configureEach {
            options.compilerArgs.add("-Xlint:-options")
        }
    }
}