import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'AIzaSyC7Zvy3bzlQxedat_Kb7E8BhiYZsF0T1FM',
    appId: '1:250570827907:web:730d7af9250099dae4d3b6',
    messagingSenderId: '250570827907',
    projectId: 'my-chat-app-b43fd',
    authDomain: 'my-chat-app-b43fd.firebaseapp.com',
    storageBucket: 'my-chat-app-b43fd.firebasestorage.app',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WeApp());
}

class WeApp extends StatelessWidget {
  const WeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF075E54),
          primary: const Color(0xFF075E54),
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. LAYAR LOGIN & REGISTER EMAIL
// -----------------------------------------------------------------------------
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  void _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua kolom!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        UserCredential creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await creds.user?.updateDisplayName(name);

        await FirebaseFirestore.instance.collection('users').doc(creds.user!.uid).set({
          'uid': creds.user!.uid,
          'name': name,
          'email': email,
          'createdAt': Timestamp.now(),
        });
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Terjadi kesalahan autentikasi')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF075E54),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat, size: 60, color: Color(0xFF075E54)),
                  const SizedBox(height: 10),
                  Text(
                    _isLogin ? 'Masuk ke WeApp' : 'Daftar Akun Baru',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (!_isLogin) ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF075E54),
                            ),
                            onPressed: _submitAuth,
                            child: Text(
                              _isLogin ? 'MASUK' : 'DAFTAR',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? 'Belum punya akun? Daftar' : 'Sudah punya akun? Masuk',
                      style: const TextStyle(color: Color(0xFF075E54)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. LAYAR UTAMA (TAB CHAT PRIBADI, GRUP, DAN STATUS)
// -----------------------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WeApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF075E54),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'PRIBADI'),
              Tab(text: 'GRUP'),
              Tab(text: 'STATUS'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PrivateChatListTab(),
            GroupChatTab(),
            StatusTab(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: DAFTAR PENGGUNA UNTUK CHAT PRIBADI (1-ON-1)
// -----------------------------------------------------------------------------
class PrivateChatListTab extends StatelessWidget {
  const PrivateChatListTab({super.key});

  String _getChatRoomId(String myUid, String peerUid) {
    List<String> ids = [myUid, peerUid];
    ids.sort();
    return ids.join("_");
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs
            .where((doc) => doc.id != currentUser?.uid)
            .toList();

        if (users.isEmpty) {
          return const Center(child: Text('Belum ada pengguna lain.\nAjak temanmu untuk mendaftar!'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;
            final peerUid = data['uid'];
            final peerName = data['name'] ?? 'Pengguna';
            final peerEmail = data['email'] ?? '';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF075E54),
                child: Text(
                  peerName.isNotEmpty ? peerName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(peerName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(peerEmail),
              trailing: const Icon(Icons.chat, color: Color(0xFF075E54)),
              onTap: () {
                final chatRoomId = _getChatRoomId(currentUser!.uid, peerUid);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SingleChatScreen(
                      chatRoomId: chatRoomId,
                      title: peerName,
                      isGroup: false,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: GRUP CHAT
// -----------------------------------------------------------------------------
class GroupChatTab extends StatelessWidget {
  const GroupChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChatScreen(
      chatRoomId: 'global_group_room',
      title: 'Grup Chat Publik',
      isGroup: true,
    );
  }
}

// -----------------------------------------------------------------------------
// LAYAR OBROLAN CHAT (PRIBADI MAUPUN GRUP)
// -----------------------------------------------------------------------------
class SingleChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String title;
  final bool isGroup;

  const SingleChatScreen({
    super.key,
    required this.chatRoomId,
    required this.title,
    required this.isGroup,
  });

  @override
  State<SingleChatScreen> createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<SingleChatScreen> {
  final _messageController = TextEditingController();

  void _sendMessage({String? imageUrl}) async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
      'text': text,
      'imageUrl': imageUrl,
      'senderId': user?.uid,
      'senderName': user?.displayName ?? user?.email ?? 'Anonim',
      'createdAt': Timestamp.now(),
    });
  }

  void _showImagePickerDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim Gambar (URL)'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'Tempel link/URL gambar...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) _sendMessage(imageUrl: url);
              Navigator.pop(ctx);
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF075E54),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFECE5DD),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == myUid;
                    final text = data['text'] ?? '';
                    final imageUrl = data['imageUrl'];
                    final senderName = data['senderName'] ?? 'Pengguna';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(8),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFE1FFC7) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAlignment.end : CrossAlignment.start,
                          children: [
                            if (!isMe && widget.isGroup)
                              Text(senderName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF075E54))),
                            if (imageUrl != null && imageUrl.toString().isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(imageUrl, fit: BoxFit.cover),
                              ),
                            if (text.isNotEmpty)
                              Text(text, style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.attach_file), onPressed: _showImagePickerDialog),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Ketik pesan...', border: InputBorder.none),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFF075E54)), onPressed: () => _sendMessage()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: FITUR STATUS / STORIES
// -----------------------------------------------------------------------------
class StatusTab extends StatelessWidget {
  const StatusTab({super.key});

  void _addStatusDialog(BuildContext context) {
    final textController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Status Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'Teks Status'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'URL Gambar Status (Opsional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              final text = textController.text.trim();
              final url = urlController.text.trim();

              if (text.isNotEmpty || url.isNotEmpty) {
                await FirebaseFirestore.instance.collection('statuses').add({
                  'userName': user?.displayName ?? user?.email ?? 'Pengguna',
                  'text': text,
                  'imageUrl': url,
                  'createdAt': Timestamp.now(),
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Post Status'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('statuses')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada status. Buat status pertamamu!'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final userName = data['userName'] ?? 'Pengguna';
              final text = data['text'] ?? '';
              final imageUrl = data['imageUrl'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF075E54),
                    child: Text(userName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      if (text.isNotEmpty) Text(text),
                      if (imageUrl != null && imageUrl.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF075E54),
        onPressed: () => _addStatusDialog(context),
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }
}
