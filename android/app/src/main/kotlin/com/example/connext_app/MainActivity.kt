package com.ppkd.connext

import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "connext/install_referrer"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"getInstallReferrer" -> getInstallReferrer(result)
					else -> result.notImplemented()
				}
			}
	}

	private fun getInstallReferrer(result: MethodChannel.Result) {
		val client = InstallReferrerClient.newBuilder(applicationContext).build()

		client.startConnection(object : InstallReferrerStateListener {
			override fun onInstallReferrerSetupFinished(responseCode: Int) {
				try {
					if (responseCode == InstallReferrerClient.InstallReferrerResponse.OK) {
						val details = client.installReferrer
						result.success(details.installReferrer)
					} else {
						result.success(null)
					}
				} catch (_: Exception) {
					result.success(null)
				} finally {
					try {
						client.endConnection()
					} catch (_: Exception) {
					}
				}
			}

			override fun onInstallReferrerServiceDisconnected() {
				try {
					client.endConnection()
				} catch (_: Exception) {
				}
			}
		})
	}
}
