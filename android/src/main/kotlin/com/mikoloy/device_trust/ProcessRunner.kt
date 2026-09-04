package com.mikoloy.device_trust

import java.io.Closeable
import java.util.concurrent.TimeUnit

/** Runs the plugin's short-lived shell commands without relying on API 26 Process methods. */
internal object ProcessRunner {
    private const val POLL_INTERVAL_MS = 5L

    fun readFirstLine(command: String, timeoutMillis: Long): String? {
        val process = try {
            Runtime.getRuntime().exec(command)
        } catch (_: Exception) {
            return null
        }

        return readFirstLine(process, timeoutMillis)
    }

    internal fun readFirstLine(process: Process, timeoutMillis: Long): String? {
        return try {
            if (!waitFor(process, timeoutMillis)) {
                null
            } else {
                process.inputStream.bufferedReader().use { reader -> reader.readLine() }
            }
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
            null
        } catch (_: Exception) {
            null
        } finally {
            destroyQuietly(process)
            closeQuietly { process.outputStream }
            closeQuietly { process.inputStream }
            closeQuietly { process.errorStream }
        }
    }

    /**
     * Polls [Process.exitValue], which is available on every supported Android API level.
     * `Process.waitFor(timeout, unit)` cannot be used because it was added in API 26.
     */
    @Throws(InterruptedException::class)
    private fun waitFor(process: Process, timeoutMillis: Long): Boolean {
        val timeoutNanos = TimeUnit.MILLISECONDS.toNanos(timeoutMillis.coerceAtLeast(0L))
        val startedAt = System.nanoTime()

        while (true) {
            try {
                process.exitValue()
                return true
            } catch (_: IllegalThreadStateException) {
                // The process is still running.
            }

            val elapsedNanos = System.nanoTime() - startedAt
            val remainingNanos = timeoutNanos - elapsedNanos
            if (remainingNanos <= 0L) return false

            val remainingMillis = TimeUnit.NANOSECONDS.toMillis(remainingNanos).coerceAtLeast(1L)
            Thread.sleep(minOf(POLL_INTERVAL_MS, remainingMillis))
        }
    }

    private fun destroyQuietly(process: Process) {
        try {
            process.destroy()
        } catch (_: Exception) {
            // Best-effort cleanup.
        }
    }

    private inline fun closeQuietly(stream: () -> Closeable) {
        try {
            stream().close()
        } catch (_: Exception) {
            // Best-effort cleanup.
        }
    }
}
