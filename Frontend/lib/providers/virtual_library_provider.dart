import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/storage_service.dart';

// Same base URL as DioClient but without /api/v1
const String _kSocketUrl = 'https://studyapp-e1sp.onrender.com';

class LibraryMember {
  final String userId;
  final String userName;
  final String subject;

  const LibraryMember({
    required this.userId,
    required this.userName,
    required this.subject,
  });

  factory LibraryMember.fromJson(Map<String, dynamic> json) {
    return LibraryMember(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Student',
      subject: json['subject'] ?? 'General Study',
    );
  }
}

class VirtualLibraryState {
  final bool isConnected;
  final bool isJoined;
  final String? currentRoom;
  final List<LibraryMember> members;
  final String? error;

  const VirtualLibraryState({
    this.isConnected = false,
    this.isJoined = false,
    this.currentRoom,
    this.members = const [],
    this.error,
  });

  VirtualLibraryState copyWith({
    bool? isConnected,
    bool? isJoined,
    String? currentRoom,
    List<LibraryMember>? members,
    String? error,
  }) {
    return VirtualLibraryState(
      isConnected: isConnected ?? this.isConnected,
      isJoined: isJoined ?? this.isJoined,
      currentRoom: currentRoom ?? this.currentRoom,
      members: members ?? this.members,
      error: error,
    );
  }
}

class VirtualLibraryNotifier extends StateNotifier<VirtualLibraryState> {
  IO.Socket? _socket;

  VirtualLibraryNotifier() : super(const VirtualLibraryState());

  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final token = await StorageService.getAccessToken();
    if (token == null) return;

    _socket = IO.io(
      _kSocketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      if (mounted) state = state.copyWith(isConnected: true, error: null);
    });

    _socket!.onDisconnect((_) {
      if (mounted) state = state.copyWith(isConnected: false, isJoined: false, members: []);
    });

    _socket!.on('room:update', (data) {
      if (!mounted) return;
      final rawMembers = List<Map<String, dynamic>>.from(data['members'] ?? []);
      final members = rawMembers.map((m) => LibraryMember.fromJson(m)).toList();
      state = state.copyWith(members: members);
    });

    _socket!.onError((err) {
      if (mounted) state = state.copyWith(error: err.toString());
    });

    _socket!.connect();
  }

  void joinRoom({required String room, required String subject}) {
    if (_socket?.connected != true) return;
    _socket!.emit('library:join', {'room': room, 'subject': subject});
    state = state.copyWith(isJoined: true, currentRoom: room);
  }

  void leaveRoom() {
    if (_socket?.connected != true || state.currentRoom == null) return;
    _socket!.emit('library:leave', {'room': state.currentRoom});
    state = state.copyWith(isJoined: false, currentRoom: null, members: []);
  }

  void disconnect() {
    leaveRoom();
    _socket?.disconnect();
    _socket = null;
    state = const VirtualLibraryState();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

final virtualLibraryProvider =
    StateNotifierProvider<VirtualLibraryNotifier, VirtualLibraryState>(
  (ref) => VirtualLibraryNotifier(),
);
