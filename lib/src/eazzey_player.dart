import 'dart:async';
import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:eazzey_player/src/bloc/player_bloc.dart';
import 'package:eazzey_player/src/config/constants.dart';
import 'package:eazzey_player/src/models/media_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:provider/provider.dart';

class EazzeyPlayer extends StatefulWidget {
  const EazzeyPlayer({super.key});

  @override
  _EazzeyPlayerState createState() => _EazzeyPlayerState();
}

class _EazzeyPlayerState extends State<EazzeyPlayer> {
  late Future<MediaMeta> futureMetaData;
  late VlcPlayerController _videoPlayerController;
  double seekValue = 0;
  double bufferValue = 0;
  double aspectRatio = 16 / 11;
  bool isPlayerPlaying = false;
  late StreamSubscription playerSubscription;
  late PlayerBloc applicationBloc;
  bool _controlsVisible = true;
  @override
  void initState() {
    super.initState();

    applicationBloc = Provider.of<PlayerBloc>(context, listen: false);
    playerSubscription = applicationBloc.uiCommunication.stream
        .asBroadcastStream()
        .listen((message) {
      if (message["type"] == "PLAYER_STATE_POSITION") {
        uploadPlayerState(message["position"]);
        //
      }
    });
    initializePlayer();
  }

  void initializePlayer() {
    _videoPlayerController = VlcPlayerController.network(
      "https://storage.googleapis.com/iwtms/moments/1.mp4",

      // 'https://media.w3.org/2010/05/sintel/trailer.mp4',
      hwAcc: HwAcc.auto,
      autoInitialize: false,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
    futureMetaData = initPlayer();
  }

  Future<void> uploadPlayerState(int position) async {
    if (mounted) {
      setState(() {
        seekValue = position.toDouble();
      });
    }
    bool isPlaying = await _videoPlayerController.isPlaying() ?? false;
    if (mounted) {
      setState(() {
        isPlayerPlaying = isPlaying;
      });
    }
  }

  Future<MediaMeta> initPlayer() async {
    await Future.delayed(const Duration(seconds: 3));
    await _videoPlayerController.initialize();
    await initMediaMeta();
    await Future.delayed(const Duration(seconds: 3));
    Future.delayed(const Duration(seconds: 5), () {
      //asynchronous delay
      if (mounted) {
        //checks if widget is still active and not disposed
        setState(() {
          //tells the widget builder to rebuild again because ui has updated
          _controlsVisible =
              false; //update the variable declare this under your class so its accessible for both your widget build and initState which is located under widget build{}
        });
      }
    });
    return initMediaMeta();
  }

  void showHideControls() {
    print("Hello");
    if (mounted) {
      setState(() {
        //tells the widget builder to rebuild again because ui has updated
        _controlsVisible =
            true; //update the variable declare this under your class so its accessible for both your widget build and initState which is located under widget build{}
      });
    }
    Future.delayed(const Duration(seconds: 5), () {
      //asynchronous delay
      if (mounted) {
        //checks if widget is still active and not disposed
        setState(() {
          //tells the widget builder to rebuild again because ui has updated
          _controlsVisible =
              false; //update the variable declare this under your class so its accessible for both your widget build and initState which is located under widget build{}
        });
      }
    });
  }

  Future<void> onPlayPause(VlcPlayerController videoPlayerController,
      int currentDuration, int totalDuration) async {
    if (currentDuration == totalDuration) {
      initializePlayer();
    } else {
      bool? isPlaying = await _videoPlayerController.isPlaying();
      if (isPlaying != null) {
        if (isPlaying) {
          _videoPlayerController.pause();
        } else {
          _videoPlayerController.play();
        }
        setState(() {
          isPlayerPlaying = !isPlaying;
        });
      } else {
        _videoPlayerController.stop();
        _videoPlayerController.play();
        setState(() {
          isPlayerPlaying = true;
        });
      }
    }
  }

  Future<void> onSeek(
      VlcPlayerController videoPlayerController, Duration newPosition) async {
    await videoPlayerController.seekTo(newPosition);
  }

  Future<MediaMeta> initMediaMeta() async {
    Duration duration = await _videoPlayerController.getDuration();
    Duration position = await _videoPlayerController.getPosition();
    int? volume = 0;
    //await _videoPlayerController.getVolume();
    double? playBackspeed = await _videoPlayerController.getPlaybackSpeed();
    int? audioDelay = await _videoPlayerController.getAudioDelay();
    bool? isPlaying = await _videoPlayerController.isPlaying();
    bool? isSeekable = await _videoPlayerController.isSeekable();
    int? audioTrackCount = await _videoPlayerController.getAudioTracksCount();
    int time = await _videoPlayerController.getTime();
    String? videoAspectRatio =
        await _videoPlayerController.getVideoAspectRatio();
    double? videoScale = await _videoPlayerController.getVideoScale();
    isPlayerPlaying = isPlaying ?? false;
    ////////
    return MediaMeta(
      duration: duration,
      position: position,
      volume: volume,
      time: time,
      playBackspeed: playBackspeed,
      audioDelay: audioDelay,
      audioTrackCount: audioTrackCount,
      isPlaying: isPlaying,
      isSeekable: isSeekable,
      videoAspectRatio: videoAspectRatio,
      videoScale: videoScale,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _videoPlayerController.stopRendererScanning();
    _videoPlayerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    // double diagonal =
    //     sqrt(pow(width, 2).toDouble() + pow(height, 2).toDouble());

    // double newHeight = diagonal / sqrt(pow(aspectRatio, 2) + 1);
    // print("diagonal: $newHeight");
    return OrientationBuilder(builder: (context, orientation) {
      bool isPortrait = orientation == Orientation.portrait;
      return Stack(children: [
        GestureDetector(
          onTap: () {
            showHideControls();
          },
          child: Container(
            color: Colors.black,
            child: VlcPlayer(
              controller: _videoPlayerController,
              aspectRatio: aspectRatio,
              // isPortrait ? 16 / 9 : 1.0
              placeholder: Container(
                width: double.infinity,
                height: isPortrait ? (height * 0.295) : height,
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: FutureBuilder(
              future: futureMetaData,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: double.infinity,
                    height: (height * 0.295),
                    color: Colors.black,
                    child: const Center(
                      child: SizedBox(
                        height: 60,
                        width: 60,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 6,
                        ),
                      ),
                    ),
                  );
                } else if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Container(
                      width: double.infinity,
                      height: (height * 0.295),
                      color: Colors.black,
                      child: const Center(
                        child: Text(
                          "Failed to load video",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  } else {
                    MediaMeta? meta = snapshot.data;
                    return meta != null
                        ? Visibility(
                            visible: _controlsVisible,
                            maintainSize: true,
                            maintainAnimation: true,
                            maintainState: true,
                            child: Container(
                              width: double.infinity,
                              color: Colors.transparent,
                              height: height * 0.295,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 50,
                                    color: Colors.black.withOpacity(0.3),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: generalPadding),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "The venom",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.subtitles_outlined,
                                              color: Colors.white,
                                              opticalSize: 1,
                                              size: 27,
                                            ),
                                            SizedBox(
                                              width: generalPadding,
                                            ),
                                            const Icon(
                                              Icons.settings_outlined,
                                              opticalSize: 1,
                                              color: Colors.white,
                                              size: 27,
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        color: Colors.black.withOpacity(0.5),
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.replay_10,
                                          color: Colors.white,
                                          opticalSize: 1,
                                          size: 42,
                                        ),
                                      ),
                                      SizedBox(
                                        width: generalPadding / 2,
                                      ),
                                      IconButton(
                                        color: Colors.black.withOpacity(0.5),
                                        onPressed: () {
                                          onPlayPause(
                                              _videoPlayerController,
                                              seekValue.toInt(),
                                              meta.duration.inSeconds);
                                        },
                                        icon: Icon(
                                          isPlayerPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                          opticalSize: 1,
                                          size: 72,
                                        ),
                                      ),
                                      SizedBox(
                                        width: generalPadding / 2,
                                      ),
                                      IconButton(
                                        color: Colors.black.withOpacity(0.5),
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.forward_10,
                                          color: Colors.white,
                                          opticalSize: 1,
                                          size: 42,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: double.infinity,
                                    color: Colors.black.withOpacity(0.3),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: generalPadding),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      seekValue
                                                          .toStringAsFixed(1),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      " /${meta.duration.inSeconds.toStringAsFixed(1)}",
                                                      style: const TextStyle(
                                                        color: Colors.white60,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                IconButton(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  onPressed: () {},
                                                  icon: const Icon(
                                                    Icons.fullscreen,
                                                    color: Colors.white,
                                                    opticalSize: 1,
                                                    size: 24,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: generalPadding),
                                            child: ProgressBar(
                                              progress: Duration(
                                                  seconds: seekValue.toInt()),
                                              buffered: Duration(
                                                  seconds: bufferValue.toInt()),
                                              total: meta.duration,
                                              barHeight: 3,
                                              progressBarColor:
                                                  seekBarActiveColor,
                                              thumbColor: Colors.white,
                                              bufferedBarColor:
                                                  seekBarSecondaryActiveColor,
                                              baseBarColor:
                                                  seekBarInactiveColor,
                                              onDragStart: (details) {
                                                _videoPlayerController.pause();
                                              },
                                              onDragEnd: () {
                                                _videoPlayerController.play();
                                              },
                                              onSeek: (duration) async {
                                                await onSeek(
                                                    _videoPlayerController,
                                                    duration);
                                                print(
                                                    'User selected a new time: $duration');
                                              },
                                            ),
                                          ),
                                          // SliderTheme(
                                          //   data: const SliderThemeData(
                                          //     trackHeight: 3,
                                          //   ),
                                          //   child: Slider(
                                          //     thumbColor: Colors.white,
                                          //     secondaryTrackValue:
                                          //         bufferValue, // buffer
                                          //     secondaryActiveColor:
                                          //         seekBarSecondaryActiveColor,
                                          //     inactiveColor: seekBarInactiveColor,
                                          //     value: seekValue,
                                          //     activeColor: seekBarActiveColor,
                                          //     max: meta.duration.inSeconds
                                          //         .toDouble(),
                                          //     onChangeStart: (value) {
                                          //       _videoPlayerController.pause();
                                          //       print("Change started: $value");
                                          //       onSeek(_videoPlayerController,
                                          //           value);
                                          //     },
                                          //     onChangeEnd: (value) async {
                                          //       print("Change Ended: $value");
                                          //       await onSeek(
                                          //           _videoPlayerController,
                                          //           value);
                                          //       _videoPlayerController.play();
                                          //     },
                                          //     onChanged: (double value) {
                                          //       setState(() {
                                          //         seekValue = value;
                                          //       });
                                          //     },
                                          //   ),
                                          // )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: (height * 0.295),
                            color: Colors.black,
                            child: const Center(
                              child: Text(
                                "Failed to load video",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                  }
                } else {
                  return Container(
                    width: double.infinity,
                    height: (height * 0.295),
                    color: Colors.black,
                    child: const Center(
                      child: Text(
                        "Failed to load video",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }
              }),
        )
      ]);
    });
  }
}
