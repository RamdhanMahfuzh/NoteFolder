import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:notefolder/core/network/weather_service.dart';
import 'package:notefolder/core/network/weather_snapshot.dart';
import 'package:notefolder/core/speech/speech_to_text_service.dart';
import 'package:notefolder/injection/injection.dart' as di;

class ContentSpeechField extends StatefulWidget {
  const ContentSpeechField({
    super.key,
    required this.controller,
    this.contentBlockAlignments = const [],
    this.onContentBlockAlignmentsChanged,
    this.onChanged,
    this.images = const [],
    this.onImagesChanged,
    this.weather = const [],
    this.onWeatherChanged,
    this.latitude,
    this.longitude,
    this.onLocationChanged,
  });

  final TextEditingController controller;
  final List<String> contentBlockAlignments;
  final ValueChanged<List<String>>? onContentBlockAlignmentsChanged;
  final ValueChanged<String>? onChanged;
  final List<String> images;
  final ValueChanged<List<String>>? onImagesChanged;
  final List<String> weather;
  final ValueChanged<List<String>>? onWeatherChanged;
  final double? latitude;
  final double? longitude;
  final ValueChanged<LatLng?>? onLocationChanged;

  @override
  State<ContentSpeechField> createState() => _ContentSpeechFieldState();
}

class _ContentSpeechFieldState extends State<ContentSpeechField> {
  final _speech = SpeechToTextService.instance;
  final _picker = ImagePicker();
  StreamSubscription<String>? _statusSubscription;
  StreamSubscription<dynamic>? _errorSubscription;
  String _startingText = '';
  bool _isListening = false;
  bool _isStarting = false;
  bool _isGettingLocation = false;
  bool _isAddingWeather = false;
  late List<TextEditingController> _blockControllers;
  late List<FocusNode> _blockFocusNodes;
  late List<String> _blockAlignments;
  int _activeBlockIndex = 0;

  FocusNode _createBlockFocusNode() {
    final focusNode = FocusNode();
    focusNode.addListener(() {
      if (!focusNode.hasFocus || !mounted) return;
      final index = _blockFocusNodes.indexOf(focusNode);
      if (index >= 0 && index != _activeBlockIndex) {
        setState(() => _activeBlockIndex = index);
      }
    });
    return focusNode;
  }

  @override
  void initState() {
    super.initState();
    _setBlocks(widget.controller.text, widget.contentBlockAlignments);
    widget.controller.addListener(_syncExternalText);
    _statusSubscription = _speech.status.listen((status) {
      if (mounted) setState(() => _isListening = status == 'listening');
    });
    _errorSubscription = _speech.errors.listen((error) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _isStarting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition failed: ${error.errorMsg}')),
      );
    });
  }

  void _setBlocks(String text, List<String> alignments) {
    _blockControllers = [
      for (final block in text.split('\n')) TextEditingController(text: block),
    ];
    _blockFocusNodes = [
      for (var i = 0; i < _blockControllers.length; i++)
        _createBlockFocusNode(),
    ];
    _blockAlignments = List.generate(
      _blockControllers.length,
      (index) => index < alignments.length ? alignments[index] : 'left',
    );
    _activeBlockIndex = _activeBlockIndex.clamp(
      0,
      _blockControllers.length - 1,
    );
  }

  void _syncExternalText() {
    if (!mounted || _joinedBlocks == widget.controller.text) return;
    final oldAlignments = _blockAlignments;
    for (final controller in _blockControllers) {
      controller.dispose();
    }
    for (final focusNode in _blockFocusNodes) {
      focusNode.dispose();
    }
    setState(() => _setBlocks(widget.controller.text, oldAlignments));
    widget.onContentBlockAlignmentsChanged?.call([..._blockAlignments]);
  }

  String get _joinedBlocks =>
      _blockControllers.map((controller) => controller.text).join('\n');

  void _syncNoteContent() {
    final text = _joinedBlocks;
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onChanged?.call(text);
    widget.onContentBlockAlignmentsChanged?.call([..._blockAlignments]);
  }

  void _changeBlock(int index, String text) {
    if (!text.contains('\n')) {
      _syncNoteContent();
      return;
    }
    final parts = text.split('\n');
    final oldController = _blockControllers.removeAt(index);
    final oldFocusNode = _blockFocusNodes.removeAt(index);
    oldController.dispose();
    oldFocusNode.dispose();
    final alignment = _blockAlignments.removeAt(index);
    _blockControllers.insertAll(index, [
      for (final part in parts) TextEditingController(text: part),
    ]);
    _blockFocusNodes.insertAll(index, [
      for (var i = 0; i < parts.length; i++) _createBlockFocusNode(),
    ]);
    _blockAlignments.insertAll(index, [
      alignment,
      ...List<String>.filled(parts.length - 1, 'left'),
    ]);
    _syncNoteContent();
    final lastBlock = index + parts.length - 1;
    setState(() => _activeBlockIndex = lastBlock);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _blockFocusNodes[lastBlock].requestFocus();
      _blockControllers[lastBlock].selection = TextSelection.collapsed(
        offset: parts.last.length,
      );
    });
  }

  TextAlign _textAlign(String alignment) => switch (alignment) {
    'center' => TextAlign.center,
    'right' => TextAlign.right,
    'justify' => TextAlign.justify,
    _ => TextAlign.left,
  };

  void _setBlockAlignment(int index, String alignment) {
    setState(() => _blockAlignments[index] = alignment);
    _syncNoteContent();
  }

  Widget _blockList({required bool expanded}) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(12, 8, 12, expanded ? 8 : 150),
      child: Column(
        children: [
          for (var index = 0; index < _blockControllers.length; index++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: ObjectKey(_blockControllers[index]),
                    controller: _blockControllers[index],
                    focusNode: _blockFocusNodes[index],
                    onChanged: (text) => _changeBlock(index, text),
                    autofocus: expanded && index == 0,
                    textAlign: _textAlign(_blockAlignments[index]),
                    maxLines: null,
                    minLines: 1,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: index == 0 ? 'Content' : null,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (!mounted || images.isEmpty) return;
      widget.onImagesChanged?.call([
        ...widget.images,
        ...images.map((image) => image.path),
      ]);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not pick image: $error')));
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _errorSubscription?.cancel();
    widget.controller.removeListener(_syncExternalText);
    for (final controller in _blockControllers) {
      controller.dispose();
    }
    for (final focusNode in _blockFocusNodes) {
      focusNode.dispose();
    }
    if (_speech.isListening) unawaited(_speech.stop());
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_speech.isListening) {
      await _speech.stop();
      return;
    }
    setState(() => _isStarting = true);
    try {
      final available = await _speech.initialize();
      if (!mounted) return;
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available on this device'),
          ),
        );
        return;
      }
      _startingText = widget.controller.text.trimRight();
      await _speech.listen((result) {
        if (!mounted || result.recognizedWords.isEmpty) return;
        final separator = _startingText.isEmpty ? '' : ' ';
        final text = '$_startingText$separator${result.recognizedWords}';
        widget.controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        widget.onChanged?.call(text);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start speech recognition: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _pickLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on location services and try again');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is disabled. Enable it in your device settings',
        );
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      widget.onLocationChanged?.call(
        LatLng(position.latitude, position.longitude),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not get location: $error')));
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _addWeather() async {
    if (_isAddingWeather || widget.weather.isNotEmpty) return;
    setState(() => _isAddingWeather = true);
    try {
      var latitude = widget.latitude;
      var longitude = widget.longitude;
      if (latitude == null || longitude == null) {
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw Exception('Turn on location services to add local weather');
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception(
            'Location permission is required to add local weather',
          );
        }
        final position = await Geolocator.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
      }

      final weather = await di.sl<WeatherService>().getWeather(
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      if (widget.weather.isNotEmpty) return;
      final entry = weatherNoteEntry(weather);
      widget.onWeatherChanged?.call([...widget.weather, entry]);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add weather: $error')));
    } finally {
      if (mounted) setState(() => _isAddingWeather = false);
    }
  }

  Future<void> _expandContent() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Note content'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (widget.images.isNotEmpty) ...[
                    _photoStrip(),
                    const SizedBox(height: 12),
                  ],
                  Expanded(child: _blockList(expanded: true)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.latitude != null && widget.longitude != null
        ? LatLng(widget.latitude!, widget.longitude!)
        : null;
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: _blockList(expanded: false),
              ),
              if (widget.images.isNotEmpty)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 54,
                  child: _photoStrip(),
                ),
              Positioned(
                right: 6,
                bottom: 6,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _isGettingLocation ? null : _pickLocation,
                      tooltip: 'Add current location',
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.location_on_outlined),
                    ),
                    IconButton(
                      onPressed: _pickImages,
                      tooltip: 'Add photo to content',
                      icon: const Icon(Icons.image_outlined),
                    ),
                    IconButton(
                      onPressed: _isAddingWeather || widget.weather.isNotEmpty
                          ? null
                          : _addWeather,
                      tooltip: widget.weather.isEmpty
                          ? 'Add local weather to content'
                          : 'Weather already added',
                      icon: _isAddingWeather
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_outlined),
                    ),
                    Material(
                      color: _isListening
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.surface,
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: _isStarting ? null : _toggleListening,
                        tooltip: _isListening
                            ? 'Stop dictation'
                            : 'Dictate content',
                        icon: Icon(
                          _isStarting
                              ? Icons.hourglass_top
                              : _isListening
                              ? Icons.stop
                              : Icons.mic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 4,
                bottom: 6,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _expandContent,
                      tooltip: 'Expand content',
                      icon: const Icon(Icons.open_in_full),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Align current paragraph',
                      onSelected: (alignment) {
                        if (_activeBlockIndex < _blockAlignments.length) {
                          _setBlockAlignment(
                            _activeBlockIndex,
                            alignment == 'reset' ? 'left' : alignment,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        for (final alignment in const [
                          ('left', 'Align left', Icons.format_align_left),
                          ('center', 'Center', Icons.format_align_center),
                          ('right', 'Align right', Icons.format_align_right),
                          ('justify', 'Justify', Icons.format_align_justify),
                        ])
                          PopupMenuItem(
                            value: alignment.$1,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(alignment.$3),
                              title: Text(alignment.$2),
                            ),
                          ),
                        if (_blockAlignments[_activeBlockIndex] != 'left')
                          const PopupMenuItem(
                            value: 'reset',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.format_clear),
                              title: Text('Reset to left'),
                            ),
                          ),
                      ],
                      icon: Icon(
                        _alignmentIcon(_blockAlignments[_activeBlockIndex]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.weather.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (var index = 0; index < widget.weather.length; index++)
            Card(
              margin: EdgeInsets.zero,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(_weatherIcon(widget.weather[index])),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.weather[index],
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove weather',
                        onPressed: () {
                          final weather = [...widget.weather]..removeAt(index);
                          widget.onWeatherChanged?.call(weather);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        if (location != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  FlutterMap(
                    key: ValueKey(location),
                    options: MapOptions(
                      initialCenter: location,
                      initialZoom: 16,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'notefolder',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: location,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                      const RichAttributionWidget(
                        alignment: AttributionAlignment.bottomLeft,
                        attributions: [
                          TextSourceAttribution('OpenStreetMap contributors'),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () => widget.onLocationChanged?.call(null),
                        tooltip: 'Remove location',
                        icon: const Icon(Icons.close),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _photoStrip() {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(widget.images[index]),
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 76,
                  height: 76,
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton.filledTonal(
                onPressed: () {
                  final images = [...widget.images]..removeAt(index);
                  widget.onImagesChanged?.call(images);
                },
                tooltip: 'Remove photo',
                icon: const Icon(Icons.close, size: 16),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _alignmentIcon(String alignment) => switch (alignment) {
    'center' => Icons.format_align_center,
    'right' => Icons.format_align_right,
    'justify' => Icons.format_align_justify,
    _ => Icons.format_align_left,
  };

  IconData _weatherIcon(String weather) {
    final condition = weather.toLowerCase();
    if (condition.startsWith('clear')) return Icons.wb_sunny_outlined;
    if (condition.startsWith('partly cloudy')) return Icons.cloud_outlined;
    if (condition.startsWith('fog')) return Icons.foggy;
    if (condition.startsWith('rain')) return Icons.water_drop_outlined;
    if (condition.startsWith('snow')) return Icons.ac_unit;
    if (condition.startsWith('thunderstorm')) {
      return Icons.thunderstorm_outlined;
    }
    return Icons.cloud_outlined;
  }
}
