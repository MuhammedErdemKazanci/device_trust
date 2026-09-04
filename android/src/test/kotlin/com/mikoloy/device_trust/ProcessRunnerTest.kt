package com.mikoloy.device_trust

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.io.OutputStream
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ProcessRunnerTest {
    @Test
    fun readFirstLineReturnsOutputAndClosesProcessResources() {
        val process = FakeProcess(completed = true, stdout = "expected\nignored")

        val result = ProcessRunner.readFirstLine(process, timeoutMillis = 50L)

        assertEquals("expected", result)
        assertTrue(process.destroyed)
        assertTrue(process.stdin.closed)
        assertTrue(process.stdout.closed)
        assertTrue(process.stderr.closed)
    }

    @Test
    fun readFirstLineDestroysProcessAfterTimeout() {
        val process = FakeProcess(completed = false, stdout = "late output")

        val result = ProcessRunner.readFirstLine(process, timeoutMillis = 1L)

        assertNull(result)
        assertTrue(process.destroyed)
        assertTrue(process.stdin.closed)
        assertTrue(process.stdout.closed)
        assertTrue(process.stderr.closed)
    }

    @Test
    fun readFirstLineRestoresInterruptedStatusAndCleansUp() {
        val process = FakeProcess(completed = false, stdout = "")

        try {
            Thread.currentThread().interrupt()

            val result = ProcessRunner.readFirstLine(process, timeoutMillis = 50L)

            assertNull(result)
            assertTrue(Thread.currentThread().isInterrupted)
            assertTrue(process.destroyed)
            assertTrue(process.stdin.closed)
            assertTrue(process.stdout.closed)
            assertTrue(process.stderr.closed)
        } finally {
            assertTrue(Thread.interrupted())
            assertFalse(Thread.currentThread().isInterrupted)
        }
    }

    private class FakeProcess(
        private var completed: Boolean,
        stdout: String
    ) : Process() {
        val stdin = TrackingOutputStream()
        val stdout = TrackingInputStream(stdout.toByteArray())
        val stderr = TrackingInputStream(ByteArray(0))
        var destroyed = false

        override fun getOutputStream(): OutputStream = stdin

        override fun getInputStream(): InputStream = stdout

        override fun getErrorStream(): InputStream = stderr

        override fun waitFor(): Int {
            completed = true
            return 0
        }

        override fun exitValue(): Int {
            if (!completed) throw IllegalThreadStateException("still running")
            return 0
        }

        override fun destroy() {
            destroyed = true
            completed = true
        }
    }

    private class TrackingInputStream(bytes: ByteArray) : ByteArrayInputStream(bytes) {
        var closed = false

        override fun close() {
            closed = true
            super.close()
        }
    }

    private class TrackingOutputStream : ByteArrayOutputStream() {
        var closed = false

        override fun close() {
            closed = true
            super.close()
        }
    }
}
