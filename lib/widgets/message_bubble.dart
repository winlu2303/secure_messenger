// lib/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;

  MessageBubble({required this.message, required this.isMe});

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.message.type == MessageType.video) {
      _videoController = VideoPlayerController.network(widget.message.content)
        ..initialize().then((_) {
          setState(() {
            _isInitialized = true;
          });
        });
    } else if (widget.message.type == MessageType.voice) {
      _audioPlayer = AudioPlayer();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _playVoice() async {
    if (_audioPlayer == null) return;

    if (_isPlaying) {
      await _audioPlayer!.stop();
    } else {
      await _audioPlayer!.setUrl(widget.message.content);
      await _audioPlayer!.play();
    }

    setState(() {
      _isPlaying = !_isPlaying;
    });

    _audioPlayer!.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!widget.isMe) _buildAvatar(),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isMe ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(),
                  SizedBox(height: 4),
                  _buildMessageInfo(),
                ],
              ),
            ),
          ),
          if (widget.isMe) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: Icon(Icons.person, color: Colors.white),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.message.type) {
      case MessageType.text:
        return Text(widget.message.content);

      case MessageType.image:
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => Dialog(
                child: CachedNetworkImage(imageUrl: widget.message.content),
              ),
            );
          },
          child: Container(
            width: 200,
            height: 200,
            child: CachedNetworkImage(
              imageUrl: widget.message.content,
              fit: BoxFit.cover,
              placeholder: (ctx, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (ctx, url, error) => Icon(Icons.error),
            ),
          ),
        );

      case MessageType.video:
        return _isInitialized && _videoController != null
            ? Container(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_videoController!),
                    IconButton(
                      icon: Icon(
                        _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 50,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                        });
                      },
                    ),
                  ],
                ),
              )
            : Container(
                width: 200,
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );

      case MessageType.voice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
              onPressed: _playVoice,
            ),
            Text('Голосовое сообщение ${widget.message.duration ?? 0}с'),
          ],
        );

      case MessageType.circleVideo:
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: CachedNetworkImageProvider(widget.message.content),
              fit: BoxFit.cover,
            ),
          ),
        );

      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildMessageInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(widget.message.timestamp),
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
        if (widget.isMe) ...[
          SizedBox(width: 4),
          Icon(
            widget.message.isRead ? Icons.done_all : Icons.done,
            size: 12,
            color: widget.message.isRead ? Colors.blue : Colors.grey,
          ),
        ],
      ],
    );
  }
}