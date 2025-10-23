// device_trust Example App - Production-level diagnostic UI
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_trust/device_trust.dart';

void main() {
  runApp(const DeviceTrustExampleApp());
}

class DeviceTrustExampleApp extends StatelessWidget {
  const DeviceTrustExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DeviceTrust Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const DeviceTrustScreen(),
    );
  }
}

class DeviceTrustScreen extends StatefulWidget {
  const DeviceTrustScreen({super.key});

  @override
  State<DeviceTrustScreen> createState() => _DeviceTrustScreenState();
}

class _DeviceTrustScreenState extends State<DeviceTrustScreen> {
  DeviceTrustReport? _report;
  String? _error;
  bool _isLoading = false;

  /// Fetch device trust report from plugin
  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _report = null;
    });

    try {
      final report = await DeviceTrust.getReport();
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Simple example policy: compromised if any major flag is true
  bool get _isCompromised {
    if (_report == null) return false;
    return _report!.rootedOrJailbroken ||
        _report!.fridaSuspected ||
        _report!.emulator ||
        _report!.debuggerAttached;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DeviceTrust Example'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Main action button
            FilledButton.icon(
              onPressed: _isLoading ? null : _fetchReport,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.security),
              label:
                  Text(_isLoading ? 'Analyzing...' : 'Get DeviceTrust Report'),
            ),

            const SizedBox(height: 24),

            // Error display
            if (_error != null) ...[
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Text(
                            'Error',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Report display
            if (_report != null) ...[
              // Summary Card
              _buildSummaryCard(theme),
              const SizedBox(height: 16),

              // Policy Card (example)
              _buildPolicyCard(theme),
              const SizedBox(height: 16),

              // Details Card
              _buildDetailsCard(theme),
              const SizedBox(height: 16),

              // Signals Card (lists from details)
              _buildSignalsCard(theme),
            ],

            // Initial state message
            if (_report == null && _error == null && !_isLoading)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tap the button above to collect device trust signals.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: theme.textTheme.titleLarge),
            const Divider(),
            const SizedBox(height: 8),
            _buildFlagRow(
              theme,
              'Rooted/Jailbroken',
              _report!.rootedOrJailbroken,
              Icons.phone_android,
            ),
            _buildFlagRow(
              theme,
              'Emulator/Simulator',
              _report!.emulator,
              Icons.computer,
            ),
            _buildFlagRow(
              theme,
              'Frida Suspected',
              _report!.fridaSuspected,
              Icons.bug_report,
            ),
            _buildFlagRow(
              theme,
              'Debugger Attached',
              _report!.debuggerAttached,
              Icons.code,
            ),
            _buildFlagRow(
              theme,
              'Dev Mode Enabled',
              _report!.devModeEnabled,
              Icons.developer_mode,
            ),
            _buildFlagRow(
              theme,
              'ADB Enabled',
              _report!.adbEnabled,
              Icons.usb,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagRow(
      ThemeData theme, String label, bool value, IconData icon) {
    final color = value ? Colors.red : Colors.green;
    final iconWidget = Icon(icon, color: color, size: 20);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: value ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value ? 'TRUE' : 'false',
              style: TextStyle(
                color: color.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(ThemeData theme) {
    final compromised = _isCompromised;
    final statusColor = compromised ? Colors.red : Colors.green;
    final statusText = compromised ? 'COMPROMISED' : 'OK';

    return Card(
      color: compromised ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Policy (Example)', style: theme.textTheme.titleLarge),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  compromised ? Icons.warning : Icons.check_circle,
                  color: statusColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Status: $statusText',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: statusColor.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        compromised
                            ? 'One or more security flags detected'
                            : 'No major security concerns detected',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(ThemeData theme) {
    final jsonString =
        const JsonEncoder.withIndent('  ').convert(_report!.details);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Details (JSON)', style: theme.textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy JSON',
                  onPressed: () => _copyToClipboard(jsonString),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  jsonString,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalsCard(ThemeData theme) {
    final details = _report!.details;

    // Extract signal arrays from details
    final jbPathHits = details['jbPathHits'] as List<dynamic>? ?? [];
    final urlSchemeHits = details['urlSchemeHits'] as List<dynamic>? ?? [];
    final dyldSuspicious =
        details['nativeDyldSuspicious'] as List<dynamic>? ?? [];

    // Only show card if there are signals
    if (jbPathHits.isEmpty && urlSchemeHits.isEmpty && dyldSuspicious.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detected Signals', style: theme.textTheme.titleLarge),
            const Divider(),
            const SizedBox(height: 8),
            if (jbPathHits.isNotEmpty) ...[
              Text(
                'Jailbreak Paths (${jbPathHits.length}):',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ...jbPathHits.map((path) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 2),
                    child: Text(
                      '• $path',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  )),
              const SizedBox(height: 12),
            ],
            if (urlSchemeHits.isNotEmpty) ...[
              Text(
                'URL Schemes (${urlSchemeHits.length}):',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ...urlSchemeHits.map((scheme) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 2),
                    child: Text(
                      '• $scheme',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  )),
              const SizedBox(height: 12),
            ],
            if (dyldSuspicious.isNotEmpty) ...[
              Text(
                'Suspicious DYLD Libraries (${dyldSuspicious.length}):',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ...dyldSuspicious.map((lib) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 2),
                    child: Text(
                      '• $lib',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('JSON copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
