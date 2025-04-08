import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/screens/login_screens/home_page.dart';
import 'package:audioplayers/audioplayers.dart';

class EasterEggPage extends StatefulWidget {
  const EasterEggPage({Key? key}) : super(key: key);

  @override
  _EasterEggPageState createState() => _EasterEggPageState();
}

class _EasterEggPageState extends State<EasterEggPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentImageIndex = 0;
  bool _showButton = false;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;
  
  final List<String> _easterEggImages = [
    'assets/data/images/easter-eggs/eg1.jpeg',
    'assets/data/images/easter-eggs/eg2.jpeg',
    'assets/data/images/easter-eggs/eg3.jpeg',
    'assets/data/images/easter-eggs/eg4.jpeg',
    'assets/data/images/easter-eggs/eg5.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    
    //animation
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    //fade animation
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    
    //audio
    _playAudio();
    
    //start sequence of images
    _startImageSequence();
  }

  Future<void> _playAudio() async {
    try {
      print('attempt to play audio...');
      
      // Load the audio file first
      Source audioSource = AssetSource('data/audio/sad-hamster.mp3');
      print('audio source created: $audioSource');
      
      // Set volume to maximum
      await _audioPlayer.setVolume(1.0);
      print('Volume set to max');
      
      // Play the audio
      await _audioPlayer.play(audioSource);
      print('audio playback started');
      
      _isAudioPlaying = true;
      
      // Listen for playback state changes
      _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        print('Audio player state change: $state');
      });
      
      // Set up a listener for when audio completes
      _audioPlayer.onPlayerComplete.listen((event) {
        print('audio playback completed');
        _isAudioPlaying = false;
      });
    } catch (e) {
      print('error with playing audio: $e');
    }
  }

  void _startImageSequence() {
    //sow first image with fade in
    _controller.forward();
    
    //timer to cycle through images
    Timer.periodic(const Duration(seconds: 3), (timer) {
      // if shown all images, stop the timer and show the button
      if (_currentImageIndex >= _easterEggImages.length - 1) {
        timer.cancel();
        setState(() {
          _showButton = true;
        });
        return;
      }
      
      //fade out curr image
      _controller.reverse().then((_) {
        //change to next image
        setState(() {
          _currentImageIndex++;
        });
        //fade in new image
        _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //fade animation for current image
            Expanded(
              child: FadeTransition(
                opacity: _animation,
                child: Image.asset(
                  _easterEggImages[_currentImageIndex],
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // OK button appears after all images have been shown
            if (_showButton)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton(
                  onPressed: () {
                    //stop audio if still playing when OK is pressed
                    if (_isAudioPlaying) {
                      _audioPlayer.stop();
                    }
                    
                    //nav to HomePage
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => HomePage()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD2EB50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 50.0),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.bebasNeue(
                      color: Colors.black,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}