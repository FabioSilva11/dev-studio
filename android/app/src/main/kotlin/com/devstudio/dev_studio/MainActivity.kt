package com.devstudio.dev_studio

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.charset.StandardCharsets
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private companion object {
        const val PROJECTS_CHANNEL = "dev_studio/projects"
        const val STORAGE_PERMISSION_REQUEST = 9501
        const val ICON_PICK_REQUEST = 9502
        const val TAG = "DevStudioProjects"
        const val SKETCHWARE_VERSION = 150
        const val PROJECT_KIND = "sketchware"
        const val AES_SECRET = "sketchwaresecure"

        val JAVA_RESERVED_WORDS = setOf(
            "abstract", "boolean", "break", "byte", "case", "catch",
            "char", "class", "const", "continue", "default", "do", "double",
            "else", "extends", "final", "finally", "float", "for",
            "goto", "if", "implements", "import", "instanceof", "int",
            "interface", "long", "native", "new", "package", "private",
            "protected", "public", "return", "short", "static",
            "super", "switch", "synchronized", "this", "throw", "throws",
            "transient", "try", "void", "volatile", "while", "true", "false",
            "null", "Override", "Deprecated", "Activity", "Bundle", "LayoutInfater",
            "Toolbar", "DrawerLayout", "FloatingActionButton", "View", "Context",
            "EditText", "onCreate", "onClick", "LinearLayout", "FrameLayout",
            "RelativeLayout", "TextView", "Spinner", "CheckBox", "WebView",
            "CalendarView", "ImageView", "Button", "ArrayList", "String", "Intent",
            "SharedPreferences", "Calendar", "none", "SeekBar", "Switch", "root",
            "R", "gyroscope", "FirebaseDatabase", "DatabaseReference",
            "FirebaseStorage", "StorageReference", "File", "AdView", "RequestNetwork",
            "MediaController", "NetworkRequest", "RequestNetworkController",
            "ProgressBar", "TextToSpeech", "SpeechRecognizer", "BluetoothConnect",
            "BluetoothController", "GoogleMapController", "MapView", "GoogleMap",
            "LocationListener", "LocationManager", "ProgressDialog", "RewardedVideoAd",
            "DatePickerDialog", "TimePickerDialog", "Notification", "ListView",
            "CardView", "GridView", "VideoView", "SearchView", "RadioButton",
            "RatingBar", "DatePicker", "TimePicker", "DigitalClock", "AnalogClock",
            "RecyclerView", "ViewPager", "SwipeRefreshLayout", "CoordinatorLayout",
            "TabLayout", "TextInputLayout", "BottomNavigationView", "ImageButton",
            "ShimmerButton", "ShimmerTextView", "CircleImageView",
            "AutoCompleteTextView", "MultiAutoCompleteTextView", "BadgeView",
            "BubbleLayout", "PatternLockView", "WaveSideBar", "BottomAppBar",
            "BottomSheetBehavior", "NavigationView", "NestedScrollView",
            "CollapsingToolbarLayout", "AppBarLayout",
        )
    }

    private var pendingIconResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PROJECTS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasStorageAccess" -> result.success(hasStorageAccess())
                "requestStorageAccess" -> {
                    requestStorageAccess()
                    result.success(true)
                }
                "loadProjects" -> loadProjects(result)
                "getProjectCreationDefaults" -> getProjectCreationDefaults(result)
                "pickProjectIcon" -> pickProjectIcon(result)
                "createProject" -> createProject(call.arguments, result)
                "loadEditorProject" -> loadEditorProject(call.arguments, result)
                "saveEditorProject" -> saveEditorProject(call.arguments, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun hasStorageAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestStorageAccess() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val appSettingsIntent = Intent(
                Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                Uri.parse("package:$packageName"),
            )
            try {
                startActivity(appSettingsIntent)
            } catch (_: Exception) {
                startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
            }
        } else {
            requestPermissions(
                arrayOf(
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE,
                ),
                STORAGE_PERMISSION_REQUEST,
            )
        }
    }

    private fun requireStorageAccess(result: MethodChannel.Result): Boolean {
        if (hasStorageAccess()) return true
        result.error(
            "storage_permission_required",
            "Storage access is required to manage Sketchware projects.",
            null,
        )
        return false
    }

    private fun loadProjects(result: MethodChannel.Result) {
        if (!requireStorageAccess(result)) return

        Thread {
            try {
                val projects = readSketchwareProjects()
                runOnUiThread { result.success(projects) }
            } catch (error: Throwable) {
                Log.e(TAG, "Unable to load Sketchware projects", error)
                runOnUiThread {
                    result.error("project_read_failed", error.message, null)
                }
            }
        }.start()
    }

    private fun getProjectCreationDefaults(result: MethodChannel.Result) {
        if (!requireStorageAccess(result)) return

        Thread {
            try {
                val projects = readAllProjectIdentities()
                val usedIds = projects.map { it.first }.toSet()
                var projectId = maxOf(
                    601,
                    (usedIds.mapNotNull { it.toIntOrNull() }.maxOrNull() ?: 600) + 1,
                )
                while (usedIds.contains(projectId.toString())) projectId++

                val usedWorkspaceNames = projects.map { it.second }.toSet()
                var sequence = 1
                var projectName = "NewProject"
                while (usedWorkspaceNames.contains(projectName)) {
                    sequence++
                    projectName = "NewProject$sequence"
                }

                val defaults = mapOf(
                    "id" to projectId.toString(),
                    "projectName" to projectName,
                    "packageName" to "com.my.${projectName.lowercase(Locale.US)}",
                    "versionCode" to "1",
                    "versionName" to "1.0",
                    "colors" to defaultThemeColors(),
                )
                runOnUiThread { result.success(defaults) }
            } catch (error: Throwable) {
                Log.e(TAG, "Unable to prepare project defaults", error)
                runOnUiThread {
                    result.error("project_defaults_failed", error.message, null)
                }
            }
        }.start()
    }

    private fun defaultThemeColors(): List<Int> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val systemAccent = getColor(android.R.color.system_accent1_500)
            return listOf(
                systemAccent,
                systemAccent,
                systemAccent,
                getColor(android.R.color.system_accent1_100),
                systemAccent,
            )
        }
        return listOf(
            0xFF2196F3.toInt(),
            0xFF2196F3.toInt(),
            0xFF1976D2.toInt(),
            0x202196F3,
            0xFF2196F3.toInt(),
        )
    }

    private fun pickProjectIcon(result: MethodChannel.Result) {
        if (pendingIconResult != null) {
            result.error("icon_picker_busy", "The icon picker is already open.", null)
            return
        }
        pendingIconResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
        }
        try {
            startActivityForResult(intent, ICON_PICK_REQUEST)
        } catch (error: Throwable) {
            pendingIconResult = null
            result.error("icon_picker_failed", error.message, null)
        }
    }

    @Deprecated("Deprecated in Android SDK, retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != ICON_PICK_REQUEST) return

        val result = pendingIconResult ?: return
        pendingIconResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }

        try {
            val selectedBitmap = contentResolver.openInputStream(data.data!!).use { stream ->
                BitmapFactory.decodeStream(stream)
            } ?: throw IllegalArgumentException("The selected image could not be decoded.")
            val side = minOf(selectedBitmap.width, selectedBitmap.height)
            val left = (selectedBitmap.width - side) / 2
            val top = (selectedBitmap.height - side) / 2
            val squareBitmap = Bitmap.createBitmap(selectedBitmap, left, top, side, side)
            val iconBitmap = Bitmap.createScaledBitmap(squareBitmap, 512, 512, true)
            val output = ByteArrayOutputStream()
            check(iconBitmap.compress(Bitmap.CompressFormat.PNG, 100, output)) {
                "The selected icon could not be encoded."
            }
            result.success(output.toByteArray())
            if (iconBitmap !== squareBitmap) iconBitmap.recycle()
            if (squareBitmap !== selectedBitmap) squareBitmap.recycle()
            selectedBitmap.recycle()
        } catch (error: Throwable) {
            Log.e(TAG, "Unable to process the selected icon", error)
            result.error("icon_processing_failed", error.message, null)
        }
    }

    private fun createProject(arguments: Any?, result: MethodChannel.Result) {
        if (!requireStorageAccess(result)) return
        val values = arguments as? Map<*, *> ?: run {
            result.error("invalid_project", "Project data is missing.", null)
            return
        }

        Thread {
            try {
                val project = saveProject(values)
                runOnUiThread { result.success(project) }
            } catch (error: IllegalArgumentException) {
                runOnUiThread {
                    result.error("invalid_project", error.message, null)
                }
            } catch (error: Throwable) {
                Log.e(TAG, "Unable to create Sketchware project", error)
                runOnUiThread {
                    result.error("project_create_failed", error.message, null)
                }
            }
        }.start()
    }

    private fun loadEditorProject(arguments: Any?, result: MethodChannel.Result) {
        if (!requireStorageAccess(result)) return
        val values = arguments as? Map<*, *> ?: run {
            result.error("invalid_project", "Project ID is missing.", null)
            return
        }
        val projectId = values["projectId"]?.toString().orEmpty()
        if (!Regex("[A-Za-z0-9_-]+").matches(projectId)) {
            result.error("invalid_project", "Project ID is invalid.", null)
            return
        }

        Thread {
            try {
                val file = editorProjectFile(projectId)
                val sketchwareView = sketchwareViewFile(projectId)
                val useEditorData = file.isFile && (
                    !sketchwareView.isFile ||
                        file.lastModified() >= sketchwareView.lastModified()
                    )
                val data = if (useEditorData) {
                    jsonObjectToMap(JSONObject(file.readText(StandardCharsets.UTF_8)))
                } else {
                    readSketchwareEditorProject(projectId)
                }
                runOnUiThread { result.success(data) }
            } catch (error: Throwable) {
                Log.e(TAG, "Unable to load editor data for $projectId", error)
                runOnUiThread {
                    result.error("editor_load_failed", error.message, null)
                }
            }
        }.start()
    }

    private fun saveEditorProject(arguments: Any?, result: MethodChannel.Result) {
        if (!requireStorageAccess(result)) return
        val values = arguments as? Map<*, *> ?: run {
            result.error("invalid_project", "Editor data is missing.", null)
            return
        }
        val projectId = values["projectId"]?.toString().orEmpty()
        val data = values["data"] as? Map<*, *>
        if (!Regex("[A-Za-z0-9_-]+").matches(projectId) || data == null) {
            result.error("invalid_project", "Editor data is invalid.", null)
            return
        }

        Thread {
            try {
                val file = editorProjectFile(projectId)
                check(file.parentFile?.isDirectory == true || file.parentFile?.mkdirs() == true) {
                    "Unable to create the editor data directory."
                }
                val temporaryFile = File(file.parentFile, "${file.name}.tmp")
                val json = platformValueToJson(data) as JSONObject
                temporaryFile.writeText(json.toString(), StandardCharsets.UTF_8)
                if (file.exists() && !file.delete()) {
                    throw IllegalStateException("Unable to replace the editor data file.")
                }
                check(temporaryFile.renameTo(file)) {
                    "Unable to finish the editor data file."
                }
                writeSketchwareViewFile(projectId, data)
                writeSketchwareStrings(projectId, data)
                file.setLastModified(System.currentTimeMillis())
                runOnUiThread { result.success(true) }
            } catch (error: Throwable) {
                Log.e(TAG, "Unable to save editor data for $projectId", error)
                runOnUiThread {
                    result.error("editor_save_failed", error.message, null)
                }
            }
        }.start()
    }

    private fun editorProjectFile(projectId: String): File {
        return File(
            Environment.getExternalStorageDirectory(),
            ".sketchware/data/$projectId/dev_studio/editor.json",
        )
    }

    private fun sketchwareViewFile(projectId: String): File {
        return File(
            Environment.getExternalStorageDirectory(),
            ".sketchware/data/$projectId/view",
        )
    }

    private fun readSketchwareEditorProject(projectId: String): Map<String, Any?> {
        val viewFile = sketchwareViewFile(projectId)
        if (!viewFile.isFile || viewFile.length() == 0L) return emptyMap()
        val plaintext = decryptProjectFile(viewFile)
        val sections = parseSketchwareViewSections(plaintext)
        val strings = readSketchwareStrings(projectId)
        val allViews = buildList {
            sections.forEach { (fileName, lines) ->
                val baseFileName = fileName.removeSuffix("_fab")
                lines.forEach { line ->
                    if (line.isNotBlank()) {
                        val widget = viewBeanToEditorWidget(JSONObject(line), strings).toMutableMap()
                        widget["layoutFile"] = baseFileName
                        add(widget)
                    }
                }
            }
        }
        return mapOf(
            "version" to 1,
            "fileName" to "main.xml",
            "widgets" to allViews,
            "events" to listOf(mapOf("target" to "Activity", "name" to "onCreate")),
            "components" to emptyList<Any>(),
            "strings" to strings,
        )
    }

    private fun parseSketchwareViewSections(
        plaintext: String,
    ): LinkedHashMap<String, MutableList<String>> {
        val sections = linkedMapOf<String, MutableList<String>>()
        var currentSection: MutableList<String>? = null
        plaintext.lineSequence().forEach { rawLine ->
            val line = rawLine.trimEnd('\r')
            if (line.startsWith("@") && line.length > 1) {
                currentSection = sections.getOrPut(line.substring(1)) { mutableListOf() }
            } else if (line.isNotBlank()) {
                currentSection?.add(line)
            }
        }
        return sections
    }

    private fun viewBeanToEditorWidget(
        view: JSONObject,
        strings: Map<String, String>,
    ): Map<String, Any?> {
        val layout = view.optJSONObject("layout") ?: JSONObject()
        val text = view.optJSONObject("text") ?: JSONObject()
        val type = view.optInt("type", 4)
        val defaultWidth = if (type == 0 || type == 1) 280 else 150
        val defaultHeight = if (type == 0 || type == 1) 180 else 52
        val rawWidth = layout.optInt("width", defaultWidth)
        val rawHeight = layout.optInt("height", defaultHeight)
        val inject = view.optString("inject", "")
        val storedText = text.optString("text", "")
        val resolvedText = if (storedText.startsWith("@string/")) {
            strings[storedText.removePrefix("@string/")] ?: storedText
        } else {
            storedText
        }
        val elevation = Regex(
            "(?:android:elevation|app:cardElevation)=\\\"([0-9.]+)dp\\\"",
        ).find(inject)?.groupValues?.getOrNull(1)?.toDoubleOrNull() ?: 0.0
        val visible = !inject.contains("android:visibility=\"gone\"")
        return mapOf(
            "id" to view.optString("id", "view"),
            "type" to type,
            "parent" to view.optString("parent", "root"),
            "parentType" to view.optInt("parentType", -1),
            "index" to view.optInt("index", 0),
            "x" to layout.optInt("marginLeft", 24),
            "y" to layout.optInt("marginTop", 24),
            "width" to if (rawWidth != 0) rawWidth else defaultWidth,
            "height" to if (rawHeight != 0) rawHeight else defaultHeight,
            "text" to resolvedText,
            "hint" to text.optString("hint", ""),
            "backgroundColor" to layout.optLong("backgroundColor", 0xFFFFFFFFL),
            "textColor" to text.optLong("textColor", 0xFF1C1C1EL),
            "fontSize" to text.optInt("textSize", 14),
            "elevation" to elevation,
            "borderRadius" to 4,
            "visible" to visible,
            "enabled" to (view.optInt("enabled", 1) != 0),
            "orientation" to if (layout.optInt("orientation", 1) == 0) {
                "horizontal"
            } else {
                "vertical"
            },
            "paddingLeft" to layout.optDouble("paddingLeft", 0.0),
            "paddingTop" to layout.optDouble("paddingTop", 0.0),
            "paddingRight" to layout.optDouble("paddingRight", 0.0),
            "paddingBottom" to layout.optDouble("paddingBottom", 0.0),
            "marginLeft" to layout.optDouble("marginLeft", 0.0),
            "marginTop" to layout.optDouble("marginTop", 0.0),
            "marginRight" to layout.optDouble("marginRight", 0.0),
            "marginBottom" to layout.optDouble("marginBottom", 0.0),
            "gravity" to layout.optInt("gravity", 0),
            "layoutGravity" to layout.optInt("layoutGravity", 0),
            "weight" to layout.optInt("weight", 0),
        )
    }

    private fun readSketchwareStrings(projectId: String): Map<String, String> {
        val stringsFile = File(
            Environment.getExternalStorageDirectory(),
            ".sketchware/data/$projectId/files/resource/values/strings.xml",
        )
        if (!stringsFile.isFile) return emptyMap()
        return try {
            val pattern = Regex(
                "<string\\s+name=\\\"([^\\\"]+)\\\"[^>]*>(.*?)</string>",
                setOf(RegexOption.DOT_MATCHES_ALL),
            )
            pattern.findAll(stringsFile.readText(StandardCharsets.UTF_8)).associate { match ->
                match.groupValues[1] to unescapeXmlValue(match.groupValues[2])
            }
        } catch (error: Throwable) {
            Log.w(TAG, "Unable to read strings.xml for $projectId", error)
            emptyMap()
        }
    }

    private fun writeSketchwareViewFile(projectId: String, data: Map<*, *>) {
        val widgets = data["widgets"] as? List<*> ?: emptyList<Any>()
        val stringResources = (data["strings"] as? Map<*, *>)
            ?.entries
            ?.associate { it.key.toString() to it.value?.toString().orEmpty() }
            .orEmpty()

        val sectionViews = linkedMapOf<String, MutableList<String>>()

        widgets.forEachIndexed { index, rawWidget ->
            val widget = rawWidget as? Map<*, *> ?: return@forEachIndexed
            val layoutFile = widget["layoutFile"]?.toString() ?: "main.xml"
            val isFab = (widget["type"] as? Number)?.toInt() == 16
            val sectionName = if (isFab) "${layoutFile}_fab" else layoutFile
            
            val serialized = editorWidgetToViewBean(widget, index, stringResources).toString()
            sectionViews.getOrPut(sectionName) { mutableListOf() }.add(serialized)
        }

        val viewFile = sketchwareViewFile(projectId)
        val plaintext = buildString {
            sectionViews.forEach { (name, lines) ->
                append('@').append(name).append('\n')
                lines.forEach { append(it).append('\n') }
                append('\n')
            }
        }
        check(viewFile.parentFile?.isDirectory == true || viewFile.parentFile?.mkdirs() == true) {
            "Unable to create the Sketchware view directory."
        }
        val temporaryFile = File(viewFile.parentFile, "view.tmp")
        temporaryFile.writeBytes(encryptProjectData(plaintext))
        if (viewFile.exists() && !viewFile.delete()) {
            throw IllegalStateException("Unable to replace the Sketchware view file.")
        }
        check(temporaryFile.renameTo(viewFile)) {
            "Unable to finish the Sketchware view file."
        }
    }

    private fun editorWidgetToViewBean(
        widget: Map<*, *>,
        index: Int,
        stringResources: Map<String, String>,
    ): JSONObject {
        fun number(key: String, fallback: Int): Int {
            return (widget[key] as? Number)?.toInt() ?: fallback
        }
        fun decimal(key: String, fallback: Double): Double {
            return (widget[key] as? Number)?.toDouble() ?: fallback
        }
        fun string(key: String, fallback: String = ""): String {
            return widget[key]?.toString() ?: fallback
        }
        val type = number("type", 4)
        val rawText = string("text")
        val resourceText = stringResources.entries
            .firstOrNull { it.value == rawText }
            ?.let { "@string/${it.key}" }
            ?: rawText
        val elevation = decimal("elevation", 0.0)
        val visible = widget["visible"] != false
        val inject = buildString {
            if (elevation > 0) {
                append(
                    if (type == 36) {
                        "app:cardElevation=\"${elevation}dp\""
                    } else {
                        "android:elevation=\"${elevation}dp\""
                    },
                )
            }
            if (!visible) {
                if (isNotEmpty()) append('\n')
                append("android:visibility=\"gone\"")
            }
        }
        val layout = JSONObject().apply {
            put("width", number("width", 150))
            put("height", number("height", 52))
            put("orientation", if (string("orientation", "vertical") == "horizontal") 0 else 1)
            put("gravity", number("gravity", 0))
            put("paddingLeft", decimal("paddingLeft", 0.0).toInt())
            put("paddingTop", decimal("paddingTop", 0.0).toInt())
            put("paddingRight", decimal("paddingRight", 0.0).toInt())
            put("paddingBottom", decimal("paddingBottom", 0.0).toInt())
            put("marginLeft", decimal("marginLeft", decimal("x", 0.0)).toInt())
            put("marginTop", decimal("marginTop", decimal("y", 0.0)).toInt())
            put("marginRight", decimal("marginRight", 0.0).toInt())
            put("marginBottom", decimal("marginBottom", 0.0).toInt())
            put("weight", number("weight", 0))
            put("weightSum", 0)
            put("layoutGravity", number("layoutGravity", 0))
            put("backgroundColor", signedColor(number("backgroundColor", 0x00FFFFFF)))
            put("borderColor", 0xFF008DCD.toInt())
        }
        val text = JSONObject().apply {
            put("text", resourceText)
            put("textSize", decimal("fontSize", 14.0).toInt())
            put("textColor", signedColor(number("textColor", 0xFF1C1C1E.toInt())))
            put("textType", 0)
            put("textFont", "default_font")
            put("hint", string("hint"))
            put("hintColor", 0xFF9E9E9E.toInt())
            put("singleLine", 0)
            put("line", 0)
            put("inputType", 1)
            put("imeOption", 0)
        }
        val image = JSONObject().apply {
            put("scaleType", "CENTER")
            put("rotate", 0)
        }
        return JSONObject().apply {
            put("id", string("id", "view$index"))
            put("type", type)
            put("parent", string("parent", "root"))
            put("parentType", number("parentType", -1))
            put("index", number("index", index))
            put("enabled", if (widget["enabled"] == false) 0 else 1)
            put("clickable", 1)
            put("spinnerMode", 1)
            put("dividerHeight", 1)
            put("choiceMode", 0)
            put("customView", "")
            put("checked", 0)
            put("alpha", 1.0)
            put("translationX", 0.0)
            put("translationY", 0.0)
            put("scaleX", 1.0)
            put("scaleY", 1.0)
            put("max", 100)
            put("progress", 0)
            put("firstDayOfWeek", 1)
            put("adSize", "")
            put("adUnitId", "")
            put("layout", layout)
            put("text", text)
            put("image", image)
            put("indeterminate", "false")
            put("inject", inject)
            put("convert", "")
            put("progressStyle", "?android:progressBarStyle")
            put("parentAttributes", JSONObject())
        }
    }

    private fun signedColor(value: Int): Int = value

    private fun writeSketchwareStrings(projectId: String, data: Map<*, *>) {
        val strings = (data["strings"] as? Map<*, *>)
            ?.entries
            ?.associate { it.key.toString() to it.value?.toString().orEmpty() }
            ?: return
        val stringsFile = File(
            Environment.getExternalStorageDirectory(),
            ".sketchware/data/$projectId/files/resource/values/strings.xml",
        )
        check(stringsFile.parentFile?.isDirectory == true || stringsFile.parentFile?.mkdirs() == true) {
            "Unable to create the Sketchware strings directory."
        }
        var xml = if (stringsFile.isFile) {
            stringsFile.readText(StandardCharsets.UTF_8)
        } else {
            "<resources>\n</resources>"
        }
        if (!xml.contains("<resources")) xml = "<resources>\n</resources>"

        val existingPattern = Regex(
            "(?s)\\s*<string\\s+name=\\\"([^\\\"]+)\\\"[^>]*>.*?</string>",
        )
        xml = existingPattern.replace(xml) { match ->
            val key = match.groupValues[1]
            val value = strings[key] ?: return@replace ""
            val openTagEnd = match.value.indexOf('>')
            val openTag = match.value.substring(0, openTagEnd + 1).trimStart()
            "\n    $openTag${escapeXmlValue(value)}</string>"
        }
        val existingNames = existingPattern
            .findAll(xml)
            .map { it.groupValues[1] }
            .toSet()
        val additions = strings
            .filterKeys { it !in existingNames }
            .entries
            .joinToString("") { (key, value) ->
                "\n    <string name=\"$key\">${escapeXmlValue(value)}</string>"
            }
        xml = if (xml.contains("</resources>")) {
            xml.replace("</resources>", "$additions\n</resources>")
        } else {
            "<resources>$additions\n</resources>"
        }
        stringsFile.writeText(xml.trim() + "\n", StandardCharsets.UTF_8)
    }

    private fun escapeXmlValue(value: String): String {
        return value
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "\\'")
            .replace("\n", "&#10;")
            .replace("\r", "&#13;")
    }

    private fun unescapeXmlValue(value: String): String {
        return value
            .replace("&#10;", "\n")
            .replace("&#13;", "\r")
            .replace("&quot;", "\"")
            .replace("&gt;", ">")
            .replace("&lt;", "<")
            .replace("&amp;", "&")
            .replace("\\'", "'")
    }

    private fun platformValueToJson(value: Any?): Any? {
        return when (value) {
            null -> JSONObject.NULL
            is Map<*, *> -> JSONObject().apply {
                value.forEach { (key, item) ->
                    put(key.toString(), platformValueToJson(item))
                }
            }
            is List<*> -> JSONArray().apply {
                value.forEach { put(platformValueToJson(it)) }
            }
            else -> value
        }
    }

    private fun jsonObjectToMap(json: JSONObject): Map<String, Any?> {
        return json.keys().asSequence().associateWith { key ->
            jsonValueToPlatform(json.opt(key))
        }
    }

    private fun jsonValueToPlatform(value: Any?): Any? {
        return when (value) {
            null, JSONObject.NULL -> null
            is JSONObject -> jsonObjectToMap(value)
            is JSONArray -> List(value.length()) { index ->
                jsonValueToPlatform(value.opt(index))
            }
            else -> value
        }
    }

    private fun saveProject(values: Map<*, *>): Map<String, Any?> {
        val appName = values.requiredString("appName")
        val projectName = values.requiredString("projectName")
        val packageName = values.requiredString("packageName")
        val versionCode = values.requiredString("versionCode").trim()
        val versionName = values.requiredString("versionName").trim()
        validateProject(appName, projectName, packageName, versionCode, versionName)

        val requestedId = values.requiredString("id").toIntOrNull()
            ?: throw IllegalArgumentException("Invalid project ID.")
        var projectId = maxOf(601, requestedId)
        while (projectIdExists(projectId.toString())) projectId++

        val rawColors = values["colors"] as? List<*>
            ?: throw IllegalArgumentException("Theme colors are missing.")
        if (rawColors.size != 5) {
            throw IllegalArgumentException("Exactly five theme colors are required.")
        }
        val colors = rawColors.map {
            (it as? Number)?.toLong()?.toInt()
                ?: throw IllegalArgumentException("Invalid theme color.")
        }
        val iconBytes = values["iconBytes"] as? ByteArray
        val hasCustomIcon = iconBytes != null && iconBytes.isNotEmpty()

        val projectDirectory = File(projectRoot(), projectId.toString())
        check(projectDirectory.mkdirs()) { "Unable to create the project directory." }

        val projectDataDirectory = File(
            Environment.getExternalStorageDirectory(),
            ".sketchware/data/$projectId",
        )
        try {
            if (projectDataDirectory.exists()) projectDataDirectory.deleteRecursively()
            check(projectDataDirectory.mkdirs()) {
                "Unable to create the project data directory."
            }
            File(projectDataDirectory, "project_config").writeText(
                "{\"xml_command\":\"true\",\"enable_viewbinding\":\"true\"}",
                StandardCharsets.UTF_8,
            )

            val resourcesRoot = File(
                Environment.getExternalStorageDirectory(),
                ".sketchware/resources",
            )
            val resourceDirectories = listOf("icons", "images", "sounds", "fonts")
                .map { resourceType -> File(resourcesRoot, "$resourceType/$projectId") }
            resourceDirectories.forEach { resourceDirectory ->
                check(resourceDirectory.isDirectory || resourceDirectory.mkdirs()) {
                    "Unable to create the ${resourceDirectory.parentFile?.name} resource directory."
                }
            }

            File(resourcesRoot, "icons/$projectId/icon.png").writeBytes(
                if (hasCustomIcon) iconBytes!! else byteArrayOf(),
            )

            val metadata = JSONObject().apply {
                put("custom_icon", hasCustomIcon)
                put("proj_type", 1)
                put("sc_ver_code", versionCode)
                put("my_ws_name", projectName)
                put("project_kind", PROJECT_KIND)
                put("color_accent", colors[0])
                put("my_app_name", appName)
                put("sc_ver_name", versionName)
                put("sc_id", projectId.toString())
                put("color_primary", colors[1])
                put("color_control_highlight", colors[3])
                put("color_control_normal", colors[4])
                put(
                    "my_sc_reg_dt",
                    SimpleDateFormat("yyyyMMddHHmmss", Locale.US).format(Date()),
                )
                put("sketchware_ver", SKETCHWARE_VERSION)
                put("isIconAdaptive", false)
                put("my_sc_pkg_name", packageName)
                put("color_primary_dark", colors[2])
            }
            val metadataFile = File(projectDirectory, "project")
            val temporaryFile = File(projectDirectory, "project.tmp")
            temporaryFile.writeBytes(encryptProjectData(metadata.toString()))
            check(temporaryFile.renameTo(metadataFile)) {
                "Unable to finish the project file."
            }

            return mapOf(
                "id" to projectId.toString(),
                "appName" to appName,
                "workspaceName" to projectName,
                "packageName" to packageName,
                "versionName" to versionName,
                "versionCode" to versionCode,
                "kind" to PROJECT_KIND,
                "sourcePath" to projectDirectory.absolutePath,
                "iconBytes" to iconBytes,
            )
        } catch (error: Throwable) {
            projectDirectory.deleteRecursively()
            projectDataDirectory.deleteRecursively()
            throw error
        }
    }

    private fun validateProject(
        appName: String,
        projectName: String,
        packageName: String,
        versionCode: String,
        versionName: String,
    ) {
        require(appName.trim().length in 1..50) {
            "Application name must contain between 1 and 50 characters."
        }
        require(appName.none { it in "&\"'<>" }) {
            "Application name contains an unsupported character."
        }
        require(Regex("[A-Za-z][A-Za-z0-9_]{0,19}").matches(projectName)) {
            "Project name must start with a letter and use only letters, numbers, or underscores."
        }
        require(packageName.length <= 50 && packageName.contains('.')) {
            "Package name must contain at least two valid segments."
        }
        require(
            packageName.split('.').all { segment ->
                Regex("[A-Za-z][A-Za-z0-9]*").matches(segment) &&
                    !JAVA_RESERVED_WORDS.contains(segment)
            },
        ) { "Package name is invalid." }
        require(versionCode.toIntOrNull()?.let { it > 0 } == true) {
            "Version code must be a positive whole number."
        }
        require(
            Regex("[0-9]+(?:\\.[0-9]+)*(?: [A-Za-z0-9_]+)?").matches(versionName),
        ) {
            "Version name must contain numbers and dots, with an optional postfix."
        }
    }

    private fun projectIdExists(projectId: String): Boolean {
        val externalStorage = Environment.getExternalStorageDirectory()
        return File(projectRoot(), projectId).exists() ||
            File(externalStorage, ".sketcware_ide/$projectId").exists()
    }

    private fun readAllProjectIdentities(): List<Pair<String, String>> {
        val externalStorage = Environment.getExternalStorageDirectory()
        return listOf(
            projectRoot(),
            File(externalStorage, ".sketcware_ide"),
        ).flatMap { root ->
            root.listFiles()
                ?.filter { it.isDirectory }
                ?.mapNotNull { directory ->
                    val metadataFile = File(directory, "project")
                    if (!metadataFile.isFile) return@mapNotNull null
                    try {
                        val metadata = JSONObject(decryptProjectFile(metadataFile))
                        Pair(
                            metadata.stringValue("sc_id", directory.name),
                            metadata.stringValue("my_ws_name", directory.name),
                        )
                    } catch (_: Throwable) {
                        Pair(directory.name, directory.name)
                    }
                }
                .orEmpty()
        }
    }

    private fun readSketchwareProjects(): List<Map<String, Any?>> {
        val root = projectRoot()
        val externalStorage = Environment.getExternalStorageDirectory()
        val projects = mutableListOf<Map<String, Any?>>()

        root.listFiles()
            ?.filter { it.isDirectory }
            ?.sortedBy { it.name }
            ?.forEach { projectDirectory ->
                val metadataFile = File(projectDirectory, "project")
                if (!metadataFile.isFile) return@forEach

                try {
                    val metadata = JSONObject(decryptProjectFile(metadataFile))
                    val projectId = metadata.stringValue("sc_id", projectDirectory.name)
                    if (projectId != projectDirectory.name) return@forEach
                    val isSketchwareProject = metadata.stringValue(
                        "project_kind",
                        PROJECT_KIND,
                    ) != "android_studio" && metadata.optInt("proj_type", 1) != 2
                    if (!isSketchwareProject) return@forEach

                    val iconFile = File(
                        externalStorage,
                        ".sketchware/resources/icons/$projectId/icon.png",
                    )
                    projects.add(
                        mapOf(
                            "id" to projectId,
                            "appName" to metadata.stringValue(
                                "my_app_name",
                                metadata.stringValue("my_ws_name", projectId),
                            ),
                            "workspaceName" to metadata.stringValue(
                                "my_ws_name",
                                metadata.stringValue("my_app_name", projectId),
                            ),
                            "packageName" to metadata.stringValue("my_sc_pkg_name", ""),
                            "versionName" to metadata.stringValue("sc_ver_name", "1.0"),
                            "versionCode" to metadata.stringValue("sc_ver_code", "1"),
                            "kind" to PROJECT_KIND,
                            "sourcePath" to projectDirectory.absolutePath,
                            "iconBytes" to if (iconFile.isFile) iconFile.readBytes() else null,
                        ),
                    )
                } catch (error: Throwable) {
                    Log.w(
                        TAG,
                        "Ignoring invalid project ${projectDirectory.absolutePath}",
                        error,
                    )
                }
            }
        return projects
    }

    private fun projectRoot(): File {
        return File(Environment.getExternalStorageDirectory(), ".sketchware/mysc/list")
    }

    private fun decryptProjectFile(file: File): String {
        val cipher = projectCipher(Cipher.DECRYPT_MODE)
        return String(cipher.doFinal(file.readBytes()), StandardCharsets.UTF_8)
    }

    private fun encryptProjectData(data: String): ByteArray {
        return projectCipher(Cipher.ENCRYPT_MODE).doFinal(
            data.toByteArray(StandardCharsets.UTF_8),
        )
    }

    private fun projectCipher(mode: Int): Cipher {
        val secret = AES_SECRET.toByteArray(StandardCharsets.UTF_8)
        return Cipher.getInstance("AES/CBC/PKCS5Padding").apply {
            init(mode, SecretKeySpec(secret, "AES"), IvParameterSpec(secret))
        }
    }

    private fun JSONObject.stringValue(key: String, fallback: String): String {
        if (!has(key) || isNull(key)) return fallback
        val value = opt(key)?.toString().orEmpty()
        return if (value.isBlank()) fallback else value
    }

    private fun Map<*, *>.requiredString(key: String): String {
        return this[key]?.toString()
            ?: throw IllegalArgumentException("Missing project field: $key")
    }
}
