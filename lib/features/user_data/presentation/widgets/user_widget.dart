import 'dart:async';

import 'package:cloudy/features/user_data/domain/entities/last_message_entity.dart';
import 'package:cloudy/features/user_data/presentation/bloc/user_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserWidget extends StatefulWidget {
  final String? localName;
  final String userName;
  final String avatarUrl;
  final String initiatorID;
  final String secondID;
  final Function()? onTap;

  const UserWidget({
    super.key,
    required this.userName,
    required this.avatarUrl,
    required this.onTap,
    required this.initiatorID,
    required this.secondID,
    this.localName,
  });

  @override
  State<UserWidget> createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> {
  late StreamController<LastMessageEntity?> _lastMessageController;
  late Future<void> _lastMessageFuture;

  @override
  void initState() {
    super.initState();
    _lastMessageController = StreamController<LastMessageEntity?>();
    _lastMessageFuture = _subscribeToLastMessageStream();
  }

  @override
  void dispose() {
    if (!_lastMessageController.isClosed) {
      _lastMessageController.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: FutureBuilder(
        future: _lastMessageFuture,
        builder: (context, futureSnapshot) {
          if (futureSnapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          } else if (futureSnapshot.hasError) {
            return Text('Ошибка: ${futureSnapshot.error}');
          } else {
            return StreamBuilder<LastMessageEntity?>(
              stream: _lastMessageController.stream,
              builder: (context, streamSnapshot) {
                if (streamSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                } else if (streamSnapshot.hasError) {
                  return Text('Ошибка: ${streamSnapshot.error}');
                } else if (streamSnapshot.hasData) {
                  final lastMessage = streamSnapshot.data;

                  return SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(widget.avatarUrl),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formateNickname(widget.localName ?? 'null',
                                    widget.userName, widget.secondID),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                lastMessage != null
                                    ? (lastMessage.isFromInitiator == true
                                        ? 'You: ${lastMessage.message}'
                                        : lastMessage.message)
                                    : 'No messages',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lastMessage?.dateTime != null
                                ? lastMessage!.dateTime
                                : ''),
                          ],
                        )
                      ],
                    ),
                  );
                } else {
                  return SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(widget.avatarUrl),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formateNickname(widget.localName ?? 'null',
                                  widget.userName, widget.secondID),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }

  String _formateNickname(String localName, String userName, String AID) {
    if (localName != 'null') {
      return localName;
    } else if (userName != AID) {
      return userName;
    } else {
      return '${userName.substring(0, 5)}...${widget.userName.substring(widget.userName.length - 3, widget.userName.length)}';
    }
  }

  Future<void> _subscribeToLastMessageStream() async {
    try {
      final stream = await context
          .read<UserDataBloc>()
          .messagingRepository
          .getLastMessageStream(
            widget.initiatorID,
            widget.secondID,
          );

      stream.listen(
        (message) {
          if (!_lastMessageController.isClosed) {
            _lastMessageController.add(message);
          }
        },
        onError: (error) {
          if (!_lastMessageController.isClosed) {
            _lastMessageController.addError(error);
          }
        },
      );
    } catch (e) {
      _lastMessageController.addError(e);
    }
  }
}
