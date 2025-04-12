import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/anniversary.dart';
import '../models/memory.dart';
import '../models/whisper.dart';
import '../services/api_service.dart';
import '../utils/image_utils.dart';
import 'home_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final User user;
  final Function(int)? onNavigateToPage;

  const DashboardScreen({
    super.key, 
    required this.user,
    this.onNavigateToPage,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  List<Anniversary> _recentAnniversaries = [];
  List<Memory> _recentMemories = [];
  List<Whisper> _recentWhispers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 并行加载所有数据
      final futures = await Future.wait([
        _apiService.getAnniversaries(),
        _apiService.getMemories(),
        _apiService.getWhispers(),
      ]);

      setState(() {
        _recentAnniversaries = (futures[0] as List<Anniversary>).take(3).toList();
        _recentMemories = (futures[1] as List<Memory>).take(3).toList();
        _recentWhispers = (futures[2] as List<Whisper>).take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 欢迎信息
            _buildWelcomeCard(),
            
            const SizedBox(height: 24),
            
            // 纪念日部分
            _buildSectionHeader('纪念日', Icons.calendar_today, 0),
            const SizedBox(height: 8),
            _recentAnniversaries.isEmpty
                ? _buildEmptyPlaceholder('暂无纪念日')
                : Column(
                    children: _recentAnniversaries.map((anniversary) => 
                      _buildAnniversaryCard(anniversary)
                    ).toList(),
                  ),
            
            const SizedBox(height: 24),
            
            // 美好回忆部分
            _buildSectionHeader('美好回忆', Icons.photo_album, 1),
            const SizedBox(height: 8),
            _recentMemories.isEmpty
                ? _buildEmptyPlaceholder('暂无美好回忆')
                : Column(
                    children: _recentMemories.map((memory) => 
                      _buildMemoryCard(memory)
                    ).toList(),
                  ),
            
            const SizedBox(height: 24),
            
            // 悄悄话部分
            _buildSectionHeader('悄悄话', Icons.chat, 2),
            const SizedBox(height: 8),
            _recentWhispers.isEmpty
                ? _buildEmptyPlaceholder('暂无悄悄话')
                : Column(
                    children: _recentWhispers.map((whisper) => 
                      _buildWhisperCard(whisper)
                    ).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // 构建板块标题
  Widget _buildSectionHeader(String title, IconData icon, int pageIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.pink),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            if (widget.onNavigateToPage != null) {
              widget.onNavigateToPage!(pageIndex + 1);
            }
          },
          child: const Text('查看全部'),
        ),
      ],
    );
  }

  // 构建空白提示
  Widget _buildEmptyPlaceholder(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // 构建欢迎信息部分
  Widget _buildWelcomeCard() {
    return Card(
      color: Colors.pink[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 用户头像 - 支持Base64和URL两种格式
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.pink[200],
              child: ImageUtils.isValidBase64Image(widget.user.avatar)
                ? ClipOval(
                    child: ImageUtils.base64ToImage(
                      widget.user.avatar,
                      width: 60,
                      height: 60,
                      errorWidget: const Icon(Icons.person, size: 30, color: Colors.white),
                    ),
                  )
                : (widget.user.avatar != null && widget.user.avatar!.startsWith('http'))
                  ? ClipOval(
                      child: Image.network(
                        widget.user.avatar!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '欢迎回来，${widget.user.username}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '今天是 ${DateFormat('yyyy年MM月dd日').format(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建纪念日卡片
  Widget _buildAnniversaryCard(Anniversary anniversary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像 - 支持Base64和URL两种格式
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 20,
              child: ImageUtils.isValidBase64Image(anniversary.avatar)
                ? ClipOval(
                    child: ImageUtils.base64ToImage(
                      anniversary.avatar,
                      width: 40,
                      height: 40,
                      errorWidget: const Icon(Icons.person, color: Colors.white),
                    ),
                  )
                : (anniversary.avatar != null && anniversary.avatar!.startsWith('http'))
                  ? ClipOval(
                      child: Image.network(
                        anniversary.avatar!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anniversary.name ?? '匿名用户',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    anniversary.content ?? '无内容',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        anniversary.moodTag ?? '无心情标签',
                        style: TextStyle(
                          color: Colors.pink[300],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        DateFormat('yyyy-MM-dd').format(anniversary.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建美好回忆卡片
  Widget _buildMemoryCard(Memory memory) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: memory.image != null
                ? Image.network(
                    memory.image!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title ?? '无标题',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  memory.content ?? '无内容',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      memory.moodTag ?? '无心情标签',
                      style: TextStyle(
                        color: Colors.pink[300],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd').format(memory.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建悄悄话卡片
  Widget _buildWhisperCard(Whisper whisper) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: whisper.avatar != null
                      ? NetworkImage(whisper.avatar!)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: whisper.avatar == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    whisper.name ?? '匿名用户',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                whisper.content ?? '无内容',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateFormat('yyyy-MM-dd').format(whisper.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 