import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:CampGo/models/user_model.dart';
import 'package:CampGo/services/data_service.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  late GenerativeModel _model;
  late ChatSession _chat;
  bool _isLoading = false;
  final DataService _dataService = DataService();
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    UserProfile? userProfile = await _dataService.getUserProfile();
    if (userProfile != null) {
      setState(() {
        _userProfile = userProfile;
      });
    }
  }

  Future<void> _initializeChat() async {
    try {
      final String apiKey = 'AIzaSyAzhJ_WOybmDXuUMV-hkuR7FQ0fNFqedsQ';
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );
      _chat = _model.startChat(
        history: [
          Content.text('Hi! Im CampGos virtual assistant. How can I help you?'),
        ],
      );
    } catch (e) {
      print('Error initializing chat: $e');
      _showErrorDialog('Cannot initialize Chatbot. Please try again later.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    setState(() {
      _messages.add({
        'role': 'user',
        'content': userMessage,
      });
      _isLoading = true;
    });

    try {
      final response = await _chat.sendMessage(
        Content.text(userMessage),
      );
      String botResponse = response.text ?? 'Sorry, I cannot answer this question.';
      botResponse = botResponse.replaceAll(RegExp(r'https?://[^\s]+\.(jpg|jpeg|png|gif)'), '');
      botResponse = botResponse.replaceAll(RegExp(r'https?://[^\s]+'), '');
      
      setState(() {
        _messages.add({
          'role': 'bot',
          'content': botResponse,
        });
      });
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        _messages.add({
          'role': 'bot',
          'content': 'Sorry, an error occurred. Please try again later.',
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CampGo ChatBot'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message['role'] == 'user';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) 
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.assistant, color: Colors.white, size: 20),
                            ),
                          ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blue[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message['content']!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        if (isUser)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: _userProfile?.profileImage != null && 
                                  _userProfile!.profileImage!['url'] != null
                                ? CircleAvatar(
                                    radius: 16,
                                    backgroundImage: NetworkImage(_userProfile!.profileImage!['url']),
                                  )
                                : const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.blue,
                                    child: Icon(Icons.person, color: Colors.white, size: 20),
                                  ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFEDECF2),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Enter your message...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}