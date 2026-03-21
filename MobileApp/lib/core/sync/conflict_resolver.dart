import 'package:flutter/material.dart';

class ConflictResolverWidget extends StatefulWidget {
  final String entityName;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;

  const ConflictResolverWidget({
    super.key,
    required this.entityName,
    required this.localData,
    required this.remoteData,
  });

  @override
  State<ConflictResolverWidget> createState() => _ConflictResolverWidgetState();
}

class _ConflictResolverWidgetState extends State<ConflictResolverWidget> {
  late Map<String, dynamic> _resolvedData;
  late Map<String, bool> _keepLocal;

  @override
  void initState() {
    super.initState();
    _resolvedData = {...widget.remoteData};
    _keepLocal = {};
    final allKeys = <String>{...widget.localData.keys, ...widget.remoteData.keys};
    for (final key in allKeys) {
      _keepLocal[key] = true;
      _resolvedData[key] = widget.localData.containsKey(key) ? widget.localData[key] : widget.remoteData[key];
    }
  }

  void _toggleKey(String key, bool useLocal) {
    setState(() {
      _keepLocal[key] = useLocal;
      _resolvedData[key] = useLocal ? widget.localData[key] : widget.remoteData[key];
    });
  }

  @override
  Widget build(BuildContext context) {
    final keys = <String>{...widget.localData.keys, ...widget.remoteData.keys}.toList()..sort();

    return AlertDialog(
      title: Text('Resolve ${widget.entityName} Conflict'),
      scrollable: true,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose which value to keep for each field:'),
            const SizedBox(height: 12),
            ...keys.map((key) {
              final localValue = widget.localData[key]?.toString() ?? '<missing>';
              final remoteValue = widget.remoteData[key]?.toString() ?? '<missing>';
              final localSelected = _keepLocal[key] ?? true;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Local: $localValue'),
                      Text('Remote: $remoteValue'),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Local'),
                              value: true,
                              groupValue: localSelected,
                              onChanged: (value) => _toggleKey(key, true),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Remote'),
                              value: false,
                              groupValue: localSelected,
                              onChanged: (value) => _toggleKey(key, false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_resolvedData),
          child: const Text('Apply Conflict Resolution'),
        ),
      ],
    );
  }
}
