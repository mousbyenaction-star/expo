package host.exp.exponent.modules.perfmonitor

import android.content.Context
import com.facebook.react.bridge.ReactApplicationContext

internal class PerfMonitorController(
  applicationContext: Context,
  private val onDisableRequested: () -> Unit,
) {
  private val dataSource = PerfMonitorDataSource()
  private val overlay = PerfMonitorOverlay(applicationContext, dataSource) {
    disable()
    onDisableRequested()
  }
  private var currentContext: ReactApplicationContext? = null
  private var enabled = false
  private var dataSourceRunning = false

  fun enable(reactContext: ReactApplicationContext?) {
    currentContext = reactContext
    enabled = true
    overlay.setReactContext(reactContext)

    if (!overlay.isShowing()) {
      try {
        overlay.show()
      } catch (_: Throwable) {
        enabled = false
        onDisableRequested.invoke()
        return
      }
    }
    maybeStartDataSource()
  }

  fun disable() {
    enabled = false
    if (dataSourceRunning) {
      dataSource.stop()
      dataSourceRunning = false
    }
    overlay.hide()
  }

  fun onContextCreated(reactContext: ReactApplicationContext) {
    currentContext = reactContext
    maybeStartDataSource()
  }

  fun onContextDestroyed(reactContext: ReactApplicationContext) {
    if (currentContext == reactContext) {
      currentContext = null
      if (dataSourceRunning) {
        dataSource.stop()
        dataSourceRunning = false
      }
    }
  }

  fun syncEnabledState(isEnabled: Boolean, context: ReactApplicationContext?) {
    if (isEnabled) {
      enable(context ?: currentContext)
    } else {
      disable()
    }
  }

  fun isEnabled() = enabled

  private fun maybeStartDataSource() {
    if (!enabled) return
    val reactContext = currentContext ?: return
    if (!dataSourceRunning) {
      dataSource.start(reactContext)
      dataSourceRunning = true
    }
  }
}
