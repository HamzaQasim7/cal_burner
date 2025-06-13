import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthPermissionHelper extends StatefulWidget {
  final VoidCallback? onPermissionsGranted;
  final VoidCallback? onPermissionsDenied;

  const HealthPermissionHelper({
    super.key,
    this.onPermissionsGranted,
    this.onPermissionsDenied,
  });

  @override
  State<HealthPermissionHelper> createState() => _HealthPermissionHelperState();
}

class _HealthPermissionHelperState extends State<HealthPermissionHelper> {
  bool _isRequesting = false;
  String _statusMessage = '';
  final Health _health = Health();

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    setState(() {
      _statusMessage = 'Checking Health Connect availability...';
    });

    final isAvailable = await _health.isHealthConnectAvailable();
    if (!isAvailable) {
      setState(() {
        _statusMessage =
            'Health Connect not available. Please install from Play Store.';
      });
    } else {
      setState(() {
        _statusMessage = 'Ready to request permissions';
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isRequesting = true;
      _statusMessage = 'Requesting permissions...';
    });

    try {
      // Step 1: Check Health Connect availability
      setState(() {
        _statusMessage = 'Checking Health Connect...';
      });

      final isAvailable = await _health.isHealthConnectAvailable();
      if (!isAvailable) {
        setState(() {
          _statusMessage = 'Installing Health Connect...';
        });

        await _health.installHealthConnect();
        await Future.delayed(Duration(seconds: 2));

        final isNowAvailable = await _health.isHealthConnectAvailable();
        if (!isNowAvailable) {
          throw Exception('Health Connect installation failed');
        }
      }

      // Step 2: Request Android permissions
      setState(() {
        _statusMessage = 'Requesting system permissions...';
      });

      final activityStatus = await Permission.activityRecognition.request();
      if (!activityStatus.isGranted) {
        throw Exception('Activity recognition permission denied');
      }

      // Step 3: Request Health permissions
      setState(() {
        _statusMessage = 'Requesting health data permissions...';
      });

      final types = [
        HealthDataType.STEPS,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ];

      final permissions = [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ];

      final authorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );

      if (authorized) {
        // Verify permissions
        final hasPermissions = await _health.hasPermissions(
          types,
          permissions: permissions,
        );

        if (hasPermissions == true) {
          setState(() {
            _statusMessage = 'Permissions granted successfully!';
          });
          widget.onPermissionsGranted?.call();
        } else {
          throw Exception('Permissions verification failed');
        }
      } else {
        throw Exception('Health permissions denied');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
      widget.onPermissionsDenied?.call();
    } finally {
      setState(() {
        _isRequesting = false;
      });
    }
  }

  Future<void> _openHealthConnectSettings() async {
    try {
      // This will open Health Connect app settings
      await _health.requestAuthorization([HealthDataType.STEPS]);
    } catch (e) {
      print('Error opening Health Connect settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.health_and_safety,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Health Data Access',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'To track your steps and calculate calories, we need access to your health data.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            if (_isRequesting)
              CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _requestPermissions,
                    child: Text('Grant Permissions'),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: _openHealthConnectSettings,
                    child: Text('Open Health Connect Settings'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
