// lib/widgets/circle_video_recorder.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class CircleVideoRecorder extends StatefulWidget {
  final Function(File file, int duration) onVideoComplete;

  CircleVideoRecorder({required this.onVideoComplete});

  @override
  _CircleVideoRecorderState createState() => _CircleVideoRecorderState();
}

class _CircleVideoRecorderState extends State<CircleVideoRecorder> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.medium);
      await _controller!.initialize();
      if (mounted) setState(() {});
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    await _controller!.startVideoRecording();
    setState(() {
      _isRecording = true;
    });

    // Таймер для отслеживания длительности
    Future.delayed(Duration(seconds: 1), () {
      if (_isRecording) {
        setState(() {
          _recordingDuration++;
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;

    final file = await _controller!.stopVideoRecording();
    setState(() {
      _isRecording = false;
    });

    widget.onVideoComplete(File(file.path), _recordingDuration);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      height: 400,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: Container(
              width: 300,
              height: 300,
              child: CameraPreview(_controller!),
            ),
          ),
          Positioned(
            bottom: 20,
            child: GestureDetector(
              onTapDown: (_) => _startRecording(),
              onTapUp: (_) => _stopRecording(),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : Colors.white,
                  border: Border.all(color: Colors.grey, width: 2),
                ),
                child: _isRecording
                    ? Center(
                        child: Text(
                          '$_recordingDuration',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      )
                    : Icon(Icons.circle, color: Colors.red, size: 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}