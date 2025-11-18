package com.example.studio_packet

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {

	companion object {
		private const val CHANNEL_NAME = "studio_packet/native_process"
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"runProcess" -> handleRunProcess(call, result)
					else -> result.notImplemented()
				}
			}
	}

	private fun handleRunProcess(call: MethodCall, result: MethodChannel.Result) {
		val executable = call.argument<String>("executable")
		val arguments = call.argument<List<String>>("arguments") ?: emptyList()
		val workingDirectory = call.argument<String>("workingDirectory")

		if (executable.isNullOrBlank()) {
			result.error("INVALID_ARGUMENT", "Executable path is required", null)
			return
		}

		thread {
			try {
				val response = runProcess(executable, arguments, workingDirectory)
				runOnUiThread { result.success(response) }
			} catch (e: Exception) {
				runOnUiThread {
					result.error("PROCESS_FAILED", e.localizedMessage ?: "Unknown error", null)
				}
			}
		}
	}

	private fun runProcess(
		executable: String,
		arguments: List<String>,
		workingDirectory: String?
	): HashMap<String, Any> {
		val command = mutableListOf(executable)
		command.addAll(arguments)

		val builder = ProcessBuilder(command)
		if (!workingDirectory.isNullOrBlank()) {
			builder.directory(File(workingDirectory))
		}

		val executableFile = File(executable)
		if (!executableFile.canExecute()) {
			executableFile.setExecutable(true, false)
		}

		val process = builder.start()

		var stdoutOutput = ""
		var stderrOutput = ""

		val stdoutThread = thread(start = true) {
			stdoutOutput = process.inputStream.bufferedReader().use { it.readText() }
		}
		val stderrThread = thread(start = true) {
			stderrOutput = process.errorStream.bufferedReader().use { it.readText() }
		}

		val exitCode = process.waitFor()
		stdoutThread.join()
		stderrThread.join()

		return hashMapOf(
			"exitCode" to exitCode,
			"stdout" to stdoutOutput,
			"stderr" to stderrOutput
		)
	}
}
