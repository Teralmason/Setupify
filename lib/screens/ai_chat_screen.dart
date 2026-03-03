import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Pano kopyalama için
import 'package:flutter_markdown/flutter_markdown.dart'; // Şık görünüm için
import '../services/ai_service.dart';
import '../theme/app_theme.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String userMsg = _controller.text.trim();
    setState(() {
      _messages.add({"role": "user", "content": userMsg});
      _isTyping = true;
      _controller.clear();
    });
    _scrollToBottom();

    final cevap = await AIService.cevapAl(_messages);

    setState(() {
      _messages.add({"role": "assistant", "content": cevap});
      _isTyping = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Setupify AI GURU"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              setState(() => _messages.clear());
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildChatBubble(_messages[index]),
                  ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text("Guru düşünüyor...",
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.psychology,
              size: 80, color: SetuplyTheme.accentPurple),
          const SizedBox(height: 20),
          const Text("Donanım Gurusuna Hoş Geldin!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Hangi ekran kartını almalısın? İşlemcin darboğaz yapar mı? Sor gelsin.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withAlpha(128)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, String> msg) {
    bool isUser = msg['role'] == 'user';
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: msg['content'] ?? ""));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Mesaj kopyalandı!"),
              duration: Duration(seconds: 1)),
        );
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isUser ? SetuplyTheme.accentPurple : SetuplyTheme.glassColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 0),
              bottomRight: Radius.circular(isUser ? 0 : 20),
            ),
          ),
          child: MarkdownBody(
            data: msg['content'] ?? "",
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: Colors.white, fontSize: 15),
              strong: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.orangeAccent),
              listBullet: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 10, 20, MediaQuery.of(context).padding.bottom + 10),
      color: Colors.black26,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: "Örn: i7-14700K vs i9-14900K...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: SetuplyTheme.glassColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: const CircleAvatar(
              backgroundColor: SetuplyTheme.accentPurple,
              child: Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
