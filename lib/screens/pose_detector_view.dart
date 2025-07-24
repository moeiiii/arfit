import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
// ✅ FIX: Hide conflicting class names to prevent ambiguity errors.
import 'package:vector_math/vector_math_64.dart' as vector;

// ==============================================================================
// 1. DATA MODELS & ENUMS
// ==============================================================================

enum WorkoutType { pushups, bicepCurls, shoulderPress, squats, none }
enum RepQuality { perfect, bad }
enum WorkoutStage { start, down, up }

class FrameAnalysis {
  final int repCount;
  final RepQuality? lastRepQuality;
  final String feedback;
  final Set<PoseLandmarkType> unstableJoints;

  FrameAnalysis({
    this.repCount = 0,
    this.lastRepQuality,
    this.feedback = "Initializing...",
    this.unstableJoints = const {},
  });
}

// ==============================================================================
// 2. THE BRAIN (THE POSE ANALYZER)
// ==============================================================================

class PoseAnalyzer {
  final WorkoutType workoutType;
  Pose? _startPose;
  final List<Pose> _calibrationFrames = [];
  bool _isCalibrated = false;

  int _repCount = 0;
  WorkoutStage _stage = WorkoutStage.start;
  RepQuality? _lastRepQuality;
  Set<PoseLandmarkType> _unstableJoints = {};
  String _feedback = "Get in START position";

  PoseAnalyzer({required this.workoutType});

  double _calculateAngle3D(vector.Vector3 p1, vector.Vector3 p2, vector.Vector3 p3) {
    final v1 = p1 - p2;
    final v2 = p3 - p2;
    final angle = v1.angleTo(v2);
    return angle * (180.0 / pi);
  }

  vector.Vector3 _getVector(Pose pose, PoseLandmarkType type) {
    final lm = pose.landmarks[type]!;
    return vector.Vector3(lm.x, lm.y, lm.z);
  }

  void _calibrate(Pose pose) {
    _calibrationFrames.add(pose);
    if (_calibrationFrames.length > 10) {
      final avgLandmarks = <PoseLandmarkType, PoseLandmark>{};
      for (final type in PoseLandmarkType.values) {
        if (pose.landmarks[type] != null && _calibrationFrames.every((p) => p.landmarks[type] != null)) {
          final x = _calibrationFrames.map((p) => p.landmarks[type]!.x).reduce((a, b) => a + b) / _calibrationFrames.length;
          final y = _calibrationFrames.map((p) => p.landmarks[type]!.y).reduce((a, b) => a + b) / _calibrationFrames.length;
          final z = _calibrationFrames.map((p) => p.landmarks[type]!.z).reduce((a, b) => a + b) / _calibrationFrames.length;
          avgLandmarks[type] = PoseLandmark(type: type, x: x, y: y, z: z, likelihood: 1);
        }
      }
      _startPose = Pose(landmarks: avgLandmarks);
      _isCalibrated = true;
      _feedback = "Ready!";
    }
  }

  FrameAnalysis analyze(Pose pose) {
    if (!_isCalibrated || _startPose == null) {
      _calibrate(pose);
    } else {
      switch (workoutType) {
        case WorkoutType.bicepCurls: _analyzeBicepCurls(pose); break;
        case WorkoutType.squats: _analyzeSquats(pose); break;
        case WorkoutType.shoulderPress: _analyzeShoulderPress(pose); break;
        case WorkoutType.pushups: _analyzePushups(pose); break;
        default: _feedback = "Workout not implemented.";
      }
    }
    return FrameAnalysis(
      repCount: _repCount,
      lastRepQuality: _lastRepQuality,
      feedback: _feedback,
      unstableJoints: _unstableJoints,
    );
  }
  
  void _analyzeBicepCurls(Pose pose) {
    final startPose = _startPose!;
    final lS = _getVector(pose, PoseLandmarkType.leftShoulder), rS = _getVector(pose, PoseLandmarkType.rightShoulder);
    final lE = _getVector(pose, PoseLandmarkType.leftElbow), rE = _getVector(pose, PoseLandmarkType.rightElbow);
    final lW = _getVector(pose, PoseLandmarkType.leftWrist), rW = _getVector(pose, PoseLandmarkType.rightWrist);
    
    final startAngle = _calculateAngle3D(_getVector(startPose, PoseLandmarkType.leftShoulder), _getVector(startPose, PoseLandmarkType.leftElbow), _getVector(startPose, PoseLandmarkType.leftWrist));
    final currentAngle = (_calculateAngle3D(lS, lE, lW) + _calculateAngle3D(rS, rE, rW)) / 2;
    
    bool isStable = true;
    _unstableJoints.clear();
    if (_getVector(startPose, PoseLandmarkType.leftElbow).distanceTo(lE) > 80) { isStable = false; _unstableJoints.add(PoseLandmarkType.leftElbow); }
    if (_getVector(startPose, PoseLandmarkType.rightElbow).distanceTo(rE) > 80) { isStable = false; _unstableJoints.add(PoseLandmarkType.rightElbow); }
    
    if (currentAngle > startAngle * 0.9) {
        if (_stage == WorkoutStage.up) {
            _lastRepQuality = isStable ? RepQuality.perfect : RepQuality.bad;
            if (isStable) _repCount++;
        }
        _stage = WorkoutStage.start;
    } else if (currentAngle < startAngle * 0.3 && _stage == WorkoutStage.start) {
        _stage = WorkoutStage.down;
    } else if (currentAngle > startAngle * 0.35 && _stage == WorkoutStage.down) {
        _stage = WorkoutStage.up;
    }
    
    _feedback = "Curl Up";
    if (!isStable) _feedback = "Keep your elbows still!";
    else if (_stage == WorkoutStage.up) _feedback = "Lower with control";
    else if (_stage == WorkoutStage.down) _feedback = "Squeeze";
  }

  void _analyzeSquats(Pose pose) {
    final startPose = _startPose!;
    final lH = _getVector(pose, PoseLandmarkType.leftHip), rH = _getVector(pose, PoseLandmarkType.rightHip);
    final lK = _getVector(pose, PoseLandmarkType.leftKnee), rK = _getVector(pose, PoseLandmarkType.rightKnee);
    final lA = _getVector(pose, PoseLandmarkType.leftAnkle), lS = _getVector(pose, PoseLandmarkType.leftShoulder);
    
    final startHipY = _getVector(startPose, PoseLandmarkType.leftHip).y;
    final currentHipY = (lH.y + rH.y) / 2;
    final kneeY = (lK.y + rK.y) / 2;

    bool isStable = true;
    _unstableJoints.clear();
    final startBackAngle = _calculateAngle3D(_getVector(startPose, PoseLandmarkType.leftShoulder), _getVector(startPose, PoseLandmarkType.leftHip), _getVector(startPose, PoseLandmarkType.leftAnkle));
    final currentBackAngle = _calculateAngle3D(lS, lH, lA);
    if ((startBackAngle - currentBackAngle).abs() > 20) {
      isStable = false;
      _unstableJoints.addAll([PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip]);
    }

    if (currentHipY > startHipY - 20) {
        if (_stage == WorkoutStage.up) {
            _lastRepQuality = isStable ? RepQuality.perfect : RepQuality.bad;
            if (isStable) _repCount++;
        }
        _stage = WorkoutStage.start;
    } else if (currentHipY > kneeY && _stage == WorkoutStage.start) {
        _stage = WorkoutStage.down;
    } else if (currentHipY < kneeY && _stage == WorkoutStage.down) {
        _stage = WorkoutStage.up;
    }

    _feedback = "Squat Down";
    if (!isStable) _feedback = "Keep your chest up!";
    else if (_stage == WorkoutStage.down && currentHipY > kneeY) _feedback = "Go deeper!";
    else if (_stage == WorkoutStage.up) _feedback = "Drive Up!";
  }

  void _analyzePushups(Pose pose) {
    final startPose = _startPose!;
    final lS = _getVector(pose, PoseLandmarkType.leftShoulder), rS = _getVector(pose, PoseLandmarkType.rightShoulder);
    final lE = _getVector(pose, PoseLandmarkType.leftElbow), rE = _getVector(pose, PoseLandmarkType.rightElbow);
    final lW = _getVector(pose, PoseLandmarkType.leftWrist), rW = _getVector(pose, PoseLandmarkType.rightWrist);
    final lH = _getVector(pose, PoseLandmarkType.leftHip);
    final lA = _getVector(pose, PoseLandmarkType.leftAnkle);
    
    final startAngle = _calculateAngle3D(_getVector(startPose, PoseLandmarkType.leftShoulder), _getVector(startPose, PoseLandmarkType.leftElbow), _getVector(startPose, PoseLandmarkType.leftWrist));
    final currentAngle = (_calculateAngle3D(lS, lE, lW) + _calculateAngle3D(rS, rE, rW)) / 2;
    
    bool isStable = true;
    _unstableJoints.clear();
    final backAngle = _calculateAngle3D(lS, lH, lA);
    if (backAngle < 160) {
      isStable = false;
      _unstableJoints.addAll([PoseLandmarkType.leftHip, PoseLandmarkType.rightHip]);
    }
    
    if (currentAngle > startAngle * 0.9) {
        if (_stage == WorkoutStage.up) {
            _lastRepQuality = isStable ? RepQuality.perfect : RepQuality.bad;
            if (isStable) _repCount++;
        }
        _stage = WorkoutStage.start;
    } else if (currentAngle < 90 && _stage == WorkoutStage.start) {
        _stage = WorkoutStage.down;
    } else if (currentAngle > 95 && _stage == WorkoutStage.down) {
        _stage = WorkoutStage.up;
    }
    
    _feedback = "Lower Down";
    if (!isStable) _feedback = "Keep your back straight!";
    else if (_stage == WorkoutStage.down && currentAngle > 95) _feedback = "Go deeper!";
    else if (_stage == WorkoutStage.up) _feedback = "Push Up!";
  }

  void _analyzeShoulderPress(Pose pose) {
     final startPose = _startPose!;
    final lS = _getVector(pose, PoseLandmarkType.leftShoulder), rS = _getVector(pose, PoseLandmarkType.rightShoulder);
    final lE = _getVector(pose, PoseLandmarkType.leftElbow), rE = _getVector(pose, PoseLandmarkType.rightElbow);
    final lW = _getVector(pose, PoseLandmarkType.leftWrist), rW = _getVector(pose, PoseLandmarkType.rightWrist);
    
    final startAngle = _calculateAngle3D(_getVector(startPose, PoseLandmarkType.leftShoulder), _getVector(startPose, PoseLandmarkType.leftElbow), _getVector(startPose, PoseLandmarkType.leftWrist));
    final currentAngle = (_calculateAngle3D(lS, lE, lW) + _calculateAngle3D(rS, rE, rW)) / 2;
    
    bool isStable = true;
    _unstableJoints.clear();
    final startElbowDist = (_getVector(startPose, PoseLandmarkType.leftElbow).x - _getVector(startPose, PoseLandmarkType.rightElbow).x).abs();
    final currentElbowDist = (lE.x - rE.x).abs();
    if (currentElbowDist > startElbowDist * 1.5) {
      isStable = false;
      _unstableJoints.addAll([PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow]);
    }
    
    if (currentAngle < startAngle * 1.1) {
        if (_stage == WorkoutStage.up) {
            _lastRepQuality = isStable ? RepQuality.perfect : RepQuality.bad;
            if (isStable) _repCount++;
        }
        _stage = WorkoutStage.start;
    } else if (currentAngle > 160 && _stage == WorkoutStage.start) {
        _stage = WorkoutStage.down;
    } else if (currentAngle < 155 && _stage == WorkoutStage.down) {
        _stage = WorkoutStage.up;
    }
    
    _feedback = "Press Up";
    if (!isStable) _feedback = "Don't flare your elbows!";
    else if (_stage == WorkoutStage.up) _feedback = "Lower with control";
    else if (_stage == WorkoutStage.down) _feedback = "Extend fully";
  }
}

// ==============================================================================
// 3. THE ENGINE (MAIN WIDGET STATE)
// ==============================================================================

class PoseDetectorView extends StatefulWidget {
  final WorkoutType workoutType;
  final int? targetReps;

  const PoseDetectorView({super.key, this.workoutType = WorkoutType.none, this.targetReps});

  @override
  State<PoseDetectorView> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> with TickerProviderStateMixin {
  CameraController? _cameraController;
  late final PoseDetector _poseDetector;
  late final PoseAnalyzer _poseAnalyzer;

  bool _isDetecting = false;
  CustomPaint? _customPaint;
  FrameAnalysis _analysis = FrameAnalysis();
  
  String? _error;
  late AnimationController _repFeedbackController;
  late Animation<double> _repFeedbackAnimation;
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _lastRepCount = 0;
  bool _workoutCompleted = false;

  @override
  void initState() {
    super.initState();
    _poseAnalyzer = PoseAnalyzer(workoutType: widget.workoutType);
    _poseDetector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream, model: PoseDetectionModel.accurate));
    _initializeCamera();
    _repFeedbackController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _repFeedbackAnimation = CurvedAnimation(parent: _repFeedbackController, curve: Curves.elasticOut);
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }
  
  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    _repFeedbackController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      setState(() => _error = "Camera permission denied");
      return;
    }
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
      _cameraController = CameraController(camera, ResolutionPreset.high, enableAudio: false);
      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      if (mounted) setState(() => _error = "Failed to initialize camera: $e");
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_workoutCompleted || _isDetecting || !mounted) return;
    _isDetecting = true;
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) { // ✅ FIX: This now correctly uses camera.Plane
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final imageRotation = InputImageRotationValue.fromRawValue(_cameraController!.description.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.bgra8888;
      
      final inputImageData = InputImageMetadata(
        size: imageSize, rotation: imageRotation, format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );
      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);

      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty && mounted) {
        final analysis = _poseAnalyzer.analyze(poses.first);
        
        setState(() {
            _analysis = analysis;
            if (_analysis.repCount > _lastRepCount) {
                _lastRepCount = _analysis.repCount;
                _repFeedbackController.forward(from: 0.0);
                if(widget.targetReps != null && _analysis.repCount >= widget.targetReps!) {
                  _handleWorkoutCompletion();
                }
            }
             _customPaint = CustomPaint(
                painter: PosePainter(pose: poses.first, imageSize: imageSize, analysis: _analysis),
            );
        });
      }
    } finally {
      _isDetecting = false;
    }
  }

  void _handleWorkoutCompletion() {
    setState(() => _workoutCompleted = true);
    _confettiController.play();
    _audioPlayer.play(AssetSource('success.mp3'));
    Future.delayed(const Duration(milliseconds: 500), () => _showSummaryDialog(isComplete: true));
  }
  
  void _showSummaryDialog({bool isComplete = false}) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(isComplete ? 'Workout Complete!' : 'End Workout?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Total Reps: ${_analysis.repCount}', style: const TextStyle(color: Colors.white, fontSize: 18)),
      ]),
      actions: [
        if (!isComplete) TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCEL')),
        TextButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('END')),
       ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(body: Center(child: Text('Error: $_error')));
    if (_cameraController == null || !_cameraController!.value.isInitialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _showSummaryDialog(isComplete: false);
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(pi), child: CameraPreview(_cameraController!)),
            if (_customPaint != null) Positioned.fill(child: _customPaint!),
            
            Center(child: ScaleTransition(scale: _repFeedbackAnimation, child: (_analysis.lastRepQuality != null) ? Text(
              _analysis.lastRepQuality == RepQuality.perfect ? "PERFECT!" : "Bad Rep",
              style: TextStyle(
                color: _analysis.lastRepQuality == RepQuality.perfect ? Colors.amberAccent : Colors.redAccent,
                fontSize: 60, fontWeight: FontWeight.bold, shadows: const [Shadow(blurRadius: 5, color: Colors.black)]
              ),
            ) : const SizedBox.shrink())),
            
            Align(alignment: Alignment.topCenter, child: ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive, shouldLoop: false)),

            Positioned(top: 40, left: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => _showSummaryDialog(isComplete: false))),

            Positioned(bottom: 40, left: 20, right: 20, child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                child: Text(_analysis.feedback, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              Text('${_analysis.repCount} / ${widget.targetReps ?? '∞'}', style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold)),
            ])),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 4. THE EYES (THE POSE PAINTER)
// ==============================================================================

class PosePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final FrameAnalysis analysis;

  PosePainter({required this.pose, required this.imageSize, required this.analysis});

  @override
  void paint(Canvas canvas, Size size) {
    final goodPaint = Paint()..color = Colors.greenAccent;
    final badPaint = Paint()..color = Colors.redAccent;
    
    Offset translate(double x, double y) {
      final flippedX = imageSize.width - x;
      final scale = min(size.width / imageSize.width, size.height / imageSize.height);
      final offsetX = (size.width - imageSize.width * scale) / 2;
      final offsetY = (size.height - imageSize.height * scale) / 2;
      return Offset(flippedX * scale + offsetX, y * scale + offsetY);
    }
    
    final points = <PoseLandmarkType, Offset>{};
    pose.landmarks.forEach((type, landmark) => points[type] = translate(landmark.x, landmark.y));

    final connections = [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],[PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],[PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],[PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],[PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],[PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],[PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle]
    ];
    
    for (var conn in connections) {
        final p1Type = conn[0]; final p2Type = conn[1];
        final p1 = points[p1Type]; final p2 = points[p2Type];
        if (p1 != null && p2 != null) {
          final isIncorrect = analysis.unstableJoints.contains(p1Type) || analysis.unstableJoints.contains(p2Type);
          canvas.drawLine(p1, p2, (isIncorrect ? badPaint : goodPaint)..strokeWidth = 3);
        }
    }
    
    points.forEach((type, point) {
        final isIncorrect = analysis.unstableJoints.contains(type);
        canvas.drawCircle(point, 6, (isIncorrect ? badPaint : goodPaint));
    });
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) => true;
}