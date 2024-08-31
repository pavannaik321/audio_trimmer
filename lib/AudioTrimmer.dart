import 'dart:io';
import 'package:easy_audio_trimmer/easy_audio_trimmer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: AudioTrimmer()));
}

class AudioTrimmer extends StatefulWidget {
  @override
  State<AudioTrimmer> createState() => _AudioTrimmerState();
}

class _AudioTrimmerState extends State<AudioTrimmer> {
  bool isPickingFile = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Audio Trimmer",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50),
          onPressed: () async {
            print(isPickingFile);
            if (isPickingFile) return;
            setState(() {
              isPickingFile = true;
            });

            FilePickerResult? result;
            try {
              print("taking image");
              result = await FilePicker.platform.pickFiles(
                // type: FileType.audio,
                allowCompression: false,
              );
            } finally {
              setState(() {
                isPickingFile = false;
              });
            }

            if (result != null) {
              File file = File(result.files.single.path!);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) {
                  return AudioTrimmerView(file);
                }),
              );
            }
          },
          child: const Text(
            "Select File",
            style: TextStyle(color: Colors.blue),
          ),
        ),
      ),
    );
  }
}

class AudioTrimmerView extends StatefulWidget {
  final File file;

  const AudioTrimmerView(this.file, {Key? key}) : super(key: key);

  @override
  State<AudioTrimmerView> createState() => _AudioTrimmerViewState();
}

class _AudioTrimmerViewState extends State<AudioTrimmerView> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;
  bool isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAudio();
    print(_startValue);
  }

  void _loadAudio() async {
    setState(() {
      isLoading = true;
    });
    try {
      await _trimmer.loadAudio(audioFile: widget.file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading audio: ${e.toString()}")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _saveAudio() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _progressVisibility = true;
    });

    await _trimmer.saveTrimmedAudio(
      startValue: _startValue,
      endValue: _endValue,
      audioFileName: DateTime.now().millisecondsSinceEpoch.toString(),
      onSave: (outputPath) {
        setState(() {
          _isSaving = false;
          _progressVisibility = false;
        });
        debugPrint('OUTPUT PATH: $outputPath');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).userGestureInProgress) {
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            "Audio Trimmer",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TrimViewer(
                            trimmer: _trimmer,
                            viewerHeight: 100,
                            viewerWidth: MediaQuery.of(context).size.width,
                            durationStyle: DurationStyle.FORMAT_MM_SS,
                            backgroundColor: Colors.grey[400],
                            barColor: const Color.fromARGB(255, 0, 0, 0),
                            durationTextStyle: TextStyle(
                                color: Theme.of(context).primaryColor),
                            allowAudioSelection: true,
                            editorProperties: TrimEditorProperties(
                              circleSize: 10,
                              borderPaintColor: Colors.pink,
                              borderWidth: 4,
                              borderRadius: 5,
                              circlePaintColor: Colors.pink.shade800,
                            ),
                            areaProperties:
                                TrimAreaProperties.edgeBlur(blurEdges: true),
                            onChangeStart: (value) => _startValue = value,
                            onChangeEnd: (value) => _endValue = value,
                            onChangePlaybackState: (value) {
                              if (mounted) {
                                setState(() => _isPlaying = value);
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      // start and end time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Start Time TextField with increment and decrement buttons
                          Column(
                            children: [
                              Text('Start Time'), // Label
                              Row(
                                children: [
                                  // Decrement Button
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_downward,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        // Decrease the start time value
                                        _startValue = (_startValue - 1.0)
                                            .clamp(0.0, _endValue);
                                      });
                                    },
                                  ),
                                  // Time Input Field
                                  Container(
                                    width: 60, // Adjust width as needed
                                    child: TextField(
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                          text: _startValue.toStringAsFixed(2)),
                                      onChanged: (value) {
                                        setState(() {
                                          // Update the start time value when input changes
                                          _startValue =
                                              double.tryParse(value) ??
                                                  _startValue;
                                          _startValue =
                                              _startValue.clamp(0.0, _endValue);
                                        });
                                      },
                                    ),
                                  ),
                                  // Increment Button
                                  IconButton(
                                    icon: Icon(Icons.arrow_upward),
                                    onPressed: () {
                                      setState(() {
                                        // Increase the start time value
                                        _startValue = (_startValue + 1.0)
                                            .clamp(0.0, _endValue);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),

                          Column(
                            children: [
                              Text('End Time'), // Label
                              Row(
                                children: [
                                  // Decrement Button
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_downward,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        // Decrease the start time value
                                        _startValue = (_startValue - 1.0)
                                            .clamp(0.0, _endValue);
                                      });
                                    },
                                  ),
                                  // Time Input Field
                                  Container(
                                    width: 60, // Adjust width as needed
                                    child: TextField(
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                          text: _startValue.toStringAsFixed(2)),
                                      onChanged: (value) {
                                        setState(() {
                                          // Update the start time value when input changes
                                          _startValue =
                                              double.tryParse(value) ??
                                                  _startValue;
                                          _startValue =
                                              _startValue.clamp(0.0, _endValue);
                                        });
                                      },
                                    ),
                                  ),
                                  // Increment Button
                                  IconButton(
                                    icon: Icon(Icons.arrow_upward),
                                    onPressed: () {
                                      setState(() {
                                        // Increase the start time value
                                        _startValue = (_startValue + 1.0)
                                            .clamp(0.0, _endValue);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Play/Pause Button
                        ],
                      ),
                      // audio duration and pause start button
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Start Time TextField with increment and decrement buttons
                          Column(
                            children: [
                              Text('Duration'), // Label
                              Row(
                                children: [
                                  // Decrement Button
                                  // Time Input Field
                                  SizedBox(
                                    width: 30,
                                  ),
                                  Container(
                                    width: 60, // Adjust width as needed
                                    child: TextField(
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                          text: _startValue.toStringAsFixed(2)),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 30,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(!_isPlaying ? 'Play' : 'Pause'), // Label
                              Row(
                                children: [
                                  SizedBox(
                                    width: 30,
                                  ),
                                  TextButton(
                                    child: _isPlaying
                                        ? Icon(
                                            Icons.pause,
                                            size: 30.0,
                                            color:
                                                Theme.of(context).primaryColor,
                                          )
                                        : Icon(
                                            Icons.play_arrow,
                                            size: 30.0,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                    onPressed: () async {
                                      bool playbackState =
                                          await _trimmer.audioPlaybackControl(
                                        startValue: _startValue,
                                        endValue: _endValue,
                                      );
                                      setState(
                                          () => _isPlaying = playbackState);
                                    },
                                  ),
                                  SizedBox(
                                    width: 30,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Play/Pause Button
                        ],
                      ),

                      Visibility(
                        visible: _progressVisibility,
                        child: LinearProgressIndicator(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Back"),
                          ),
                          SizedBox(
                            width: 30,
                          ),
                          ElevatedButton(
                            onPressed: !_progressVisibility && !_isSaving
                                ? () => _saveAudio()
                                : null,
                            child: const Text("SAVE"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
