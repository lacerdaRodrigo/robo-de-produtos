package br.com.radarbeneficios.app

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "br.com.radarbeneficios.app/aparencia",
        ).setMethodCallHandler { call, result ->
            val preferencias = getSharedPreferences(
                "radar_aparencia",
                Context.MODE_PRIVATE,
            )
            when (call.method) {
                "carregar" -> result.success(preferencias.getString("tema", null))
                "salvar" -> {
                    val modo = call.argument<String>("modo")
                    if (modo == null) {
                        preferencias.edit().remove("tema").apply()
                    } else {
                        preferencias.edit().putString("tema", modo).apply()
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
