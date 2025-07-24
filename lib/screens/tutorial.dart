// lib/screens/tutorial.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class TutorialScreen extends StatefulWidget {
  final String exerciseName;
  const TutorialScreen({super.key, required this.exerciseName});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  YoutubePlayerController? _controller;
  String? _matchedExerciseName;

  static final Map<String, String> _videoMap = {
    // Barbell
    'barbell squat': 'bEv6CCg2BC8', 'bench press': 'gRVjAtPip0Y', 'deadlift': 'ytGaGIn3SjE',
    'overhead press': '2yjwXTZQDDI', 'barbell row': '-agM_i_w_d0', 'hip thrust': 'xDmFkJxP_pg',
    // Dumbbell
    'dumbbell bench press': 'vmB1G1K7vIE', 'dumbbell row': 'pYcpY20QaE8', 'bicep curl': 'ykJmrZ5v0Oo',
    'shoulder press': 'qEwKCR5-j_I', 'goblet squat': 'MeXsaEmB-wA', 'dumbbell fly': 'eozbU_aXkL8',
    'lateral raise': '3VcKaXpzqRo', 'tricep extension': 'nRi_d4gG_bA', 'romanian deadlift': 'C_p03qCvS2E',
    'bulgarian split squat': '2C-uNgN5n_4',
    // Bodyweight & Calisthenics
    'push up': 'IODxDxX7oi4', 'pull up': 'eGo4IYlbE5g', 'dip': '2z8JmcrW-fk',
    'bodyweight squat': 'C_VtOYc6j5c', 'lunge': 'QO_o_i4iGpa', 'plank': 'ASdvN_XEl_c',
    'chin up': 'brhRXlOhsAM',
    // Machines & Cables
    'lat pulldown': 'trPCb2_jaib', 'leg press': 'IZxySo_7i0I', 'cable crossover': 'taI4XduLpTk',
    'leg extension': 'YyvSfVjQeL0', 'hamstring curl': 'F488k67BTaw', 'seated cable row': 'GZbfZ033f74',
  };
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    final (videoId, matchedName) = _findBestMatchVideo();
    if (videoId != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      );
      _matchedExerciseName = matchedName;
    }
  }

  // ✅ NEW: Smarter, multi-stage matching algorithm
  (String?, String?) _findBestMatchVideo() {
    final searchName = widget.exerciseName.toLowerCase();
    final searchWords = searchName.split(' ').toSet(); // Use a Set for efficient lookups

    // Stage 1: Check for a perfect match
    if (_videoMap.containsKey(searchName)) {
      return (_videoMap[searchName], searchName);
    }

    // Stage 2: Find keys that contain ALL search words
    String? bestCandidate;
    int bestCandidateWordCount = 1000; // Start high to find the shortest match

    for (var key in _videoMap.keys) {
      final keyWords = key.split(' ').toSet();
      if (keyWords.containsAll(searchWords)) {
        // If this key is shorter than the previous best candidate, it's a better match
        if (keyWords.length < bestCandidateWordCount) {
          bestCandidate = key;
          bestCandidateWordCount = keyWords.length;
        }
      }
    }

    if (bestCandidate != null) {
      return (_videoMap[bestCandidate], bestCandidate);
    }
    
    // Stage 3: Fallback to partial word scoring (original method)
    String bestMatch = '';
    int highestScore = 0;

    _videoMap.forEach((key, videoId) {
      int currentScore = 0;
      for (var word in searchWords) {
        if (key.contains(word)) currentScore++;
      }
      if (currentScore > highestScore) {
        highestScore = currentScore;
        bestMatch = key;
      }
    });

    return bestMatch.isNotEmpty ? (_videoMap[bestMatch], bestMatch) : (null, null);
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelColor = const Color(0xFF0E1216);
    final accent = const Color(0xFFF06500);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Tutorial: ${widget.exerciseName}', style: GoogleFonts.exo()),
        backgroundColor: panelColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_controller != null)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: YoutubePlayer(controller: _controller!),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.grey[800]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(child: Text("No video found for this exercise.", style: TextStyle(color: Colors.white))),
              ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exerciseName,
                    style: GoogleFonts.exo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  if (_matchedExerciseName != null)
                    Text(
                      'Showing tutorial for: ${_matchedExerciseName![0].toUpperCase()}${_matchedExerciseName!.substring(1)}',
                      style: GoogleFonts.exo(color: accent, fontSize: 16),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Use the video controls to play, pause, and go fullscreen.',
                    style: GoogleFonts.exo(color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}