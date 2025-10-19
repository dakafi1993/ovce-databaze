import 'package:flutter/material.dart';
import '../services/ovce_service_api.dart';

/// Widget pro zobrazení stavu internetového připojení a synchronizace
class ConnectionStatusWidget extends StatefulWidget {
  @override
  _ConnectionStatusWidgetState createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  final OvceService _ovceService = OvceService();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _ovceService.isOnline ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _ovceService.isOnline ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _ovceService.isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: _ovceService.isOnline ? Colors.green : Colors.orange,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            _ovceService.isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: _ovceService.isOnline ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!_ovceService.isOnline) ...[
            SizedBox(width: 4),
            Text(
              '(${_ovceService.cachedCount})',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget pro manuální synchronizaci
class SyncButton extends StatefulWidget {
  @override
  _SyncButtonState createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  final OvceService _ovceService = OvceService();
  bool _isSyncing = false;

  Future<void> _performSync() async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
    });

    try {
      await _ovceService.performPendingSync();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Synchronizace dokončena'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Chyba při synchronizaci'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _ovceService.isOnline ? _performSync : null,
      icon: _isSyncing
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(Icons.sync),
      tooltip: _ovceService.isOnline 
          ? 'Synchronizovat s serverem'
          : 'Není internetové připojení',
    );
  }
}