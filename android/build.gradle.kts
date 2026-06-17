allprojects {
    repositories {
        google()
        mavenCentral()
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
    tasks.matching {
        it.name.startsWith("extract") && it.name.endsWith("Annotations")
    }.configureEach {
        enabled = false
    }
    tasks.matching {
        it.name.startsWith("sync") && it.name.endsWith("LibJars")
    }.configureEach {
        val variantName = name.removePrefix("sync").removeSuffix("LibJars")
        val variantDir = variantName.replaceFirstChar { it.lowercase() }
        val typedefFile =
            project.layout.buildDirectory
                .file(
                    "intermediates/annotations_typedef_file/$variantDir/extract${variantName}Annotations/typedefs.txt"
                )
                .get()
                .asFile

        if (!typedefFile.exists()) {
            typedefFile.parentFile.mkdirs()
            typedefFile.writeText("")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
