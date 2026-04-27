import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/virtual_library_provider.dart';
import '../app_theme.dart';
import '../widgets/animations.dart';

const _kRooms = [
  {'name': 'Engineering', 'emoji': '⚙️'},
  {'name': 'Medical', 'emoji': '🏥'},
  {'name': 'Science', 'emoji': '🔬'},
  {'name': 'Mathematics', 'emoji': '📐'},
  {'name': 'Arts & Humanities', 'emoji': '🎨'},
  {'name': 'Commerce', 'emoji': '💼'},
  {'name': 'General Study', 'emoji': '📚'},
];

class VirtualLibraryScreen extends ConsumerStatefulWidget {
  const VirtualLibraryScreen({super.key});

  @override
  ConsumerState<VirtualLibraryScreen> createState() => _VirtualLibraryScreenState();
}

class _VirtualLibraryScreenState extends ConsumerState<VirtualLibraryScreen> {
  String? _selectedRoom;
  String _mySubject = 'General Study';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(virtualLibraryProvider.notifier).connect();
    });
  }

  @override
  void dispose() {
    ref.read(virtualLibraryProvider.notifier).disconnect();
    super.dispose();
  }

  void _joinRoom(String room) {
    setState(() => _selectedRoom = room);
    ref.read(virtualLibraryProvider.notifier).joinRoom(
      room: room,
      subject: _mySubject,
    );
  }

  void _leaveRoom() {
    ref.read(virtualLibraryProvider.notifier).leaveRoom();
    setState(() => _selectedRoom = null);
  }

  @override
  Widget build(BuildContext context) {
    final libState = ref.watch(virtualLibraryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_library_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Virtual Library',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
        actions: [
          // Connection status dot
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: libState.isConnected
                  ? AppColors.accentGreen.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: libState.isConnected
                    ? AppColors.accentGreen.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: libState.isConnected ? AppColors.accentGreen : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  libState.isConnected ? 'Live' : 'Connecting...',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: libState.isConnected ? AppColors.accentGreen : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: libState.isJoined
          ? _buildRoomView(libState)
          : _buildRoomSelector(libState),
    );
  }

  Widget _buildRoomSelector(VirtualLibraryState libState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Hero Banner
          FadeSlideIn(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌐', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 10),
                  Text(
                    'Study Together,\nAchieve More',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join a live study room and stay focused with others.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),
          Text('Choose your room', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          // Room grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: _kRooms.length,
            itemBuilder: (context, i) {
              final room = _kRooms[i];
              final isSelected = _selectedRoom == room['name'];
              return PressButton(
                scaleDown: 0.94,
                onTap: () => _joinRoom(room['name']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 2 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(room['emoji']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 8),
                      Text(
                        room['name']!,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoomView(VirtualLibraryState libState) {
    return Column(
      children: [
        // Room header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          color: Colors.white,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      libState.currentRoom ?? 'Study Room',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${libState.members.length} studying now',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.accentGreen, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              PressButton(
                scaleDown: 0.9,
                onTap: _leaveRoom,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Leave',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.divider),

        // Members List
        Expanded(
          child: libState.members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_empty_rounded, size: 48, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Text(
                        'Waiting for others to join...',
                        style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: libState.members.length,
                  itemBuilder: (ctx, i) {
                    final member = libState.members[i];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: i * 60),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                gradient: AppColors.heroGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  member.userName.isNotEmpty
                                      ? member.userName[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.userName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Studying: ${member.subject}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Online',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accentGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
