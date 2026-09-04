package com.mikoloy.device_trust

import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Test

class DeviceTrustReportTest {
    @Test
    fun wirePayloadUsesStableMasksForEachSignal() {
        val cases = listOf(
            report(rootedOrJailbroken = true) to 1L,
            report(emulator = true) to 2L,
            report(devModeEnabled = true) to 4L,
            report(adbEnabled = true) to 8L,
            report(fridaSuspected = true) to 16L,
            report(debuggerAttached = true) to 32L
        )

        cases.forEach { (report, expectedMask) ->
            assertEquals(expectedMask, report.toWirePayload()[1])
        }
    }

    @Test
    fun wirePayloadCombinesSignalsAndKeepsDetails() {
        val details = mapOf<String, Any?>(
            "rootSignals" to 2,
            "nativeError" to null
        )
        val report = report(
            rootedOrJailbroken = true,
            emulator = true,
            devModeEnabled = true,
            adbEnabled = true,
            fridaSuspected = true,
            debuggerAttached = true,
            details = details
        )

        val payload = report.toWirePayload()

        assertEquals(3, payload.size)
        assertEquals(1, payload[0])
        assertEquals(63L, payload[1])
        assertSame(details, payload[2])
    }

    @Test
    fun wirePayloadUsesZeroWhenNoSignalsAreSet() {
        assertEquals(listOf(1, 0L, emptyMap<String, Any?>()), report().toWirePayload())
    }

    private fun report(
        rootedOrJailbroken: Boolean = false,
        emulator: Boolean = false,
        devModeEnabled: Boolean = false,
        adbEnabled: Boolean = false,
        fridaSuspected: Boolean = false,
        debuggerAttached: Boolean = false,
        details: Map<String, Any?> = emptyMap()
    ) = DeviceTrustReport(
        rootedOrJailbroken = rootedOrJailbroken,
        emulator = emulator,
        devModeEnabled = devModeEnabled,
        adbEnabled = adbEnabled,
        fridaSuspected = fridaSuspected,
        debuggerAttached = debuggerAttached,
        details = details
    )
}
