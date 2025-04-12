// 允许插件添加自己的Maven仓库
buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

// 构建路径设置
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// 子项目配置
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // 添加公共仓库配置，解决Maven冲突
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

// 确保所有子项目都依赖app项目
subprojects {
    project.evaluationDependsOn(":app")
}

// 启用Gradle并行构建
gradle.startParameter.apply {
    // 注意：configureOnDemand是私有属性，不能直接访问
    // 而是通过系统属性设置
    isParallelProjectExecutionEnabled = true
}

// 通过系统属性设置configureOnDemand
System.setProperty("org.gradle.configureondemand", "false")

// 清理任务
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
