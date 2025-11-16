+// lib/main.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

// ----- IMPORTANT -----
// Change this to match your backend address before running.
// For Android emulator (AVD): use 10.0.2.2
// Example: "http://10.0.2.2:8000/predict"
const String BACKEND_URL = "http://YOUR_PC_IP:8000/predict";

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WSI Liver Detector',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HistoryItem {
  final String filename;
  final String prediction;
  final double confidence;
  final DateTime time;
  HistoryItem({
    required this.filename,
    required this.prediction,
    required this.confidence,
    required this.time,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isProcessing = false;
  double _uploadProgress = 0.0;
  String _status = "Pick an .svs file to analyze";
  List<HistoryItem> _history = [];

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svs'],
        allowMultiple: false,
      );

      if (result == null) return; // cancelled

      final path = result.files.single.path!;
      final name = result.files.single.name;
      final size = result.files.single.size;

      setState(() {
        _isProcessing = true;
        _uploadProgress = 0.0;
        _status =
            "Uploading $name (${(size / 1024 / 1024).toStringAsFixed(2)} MB)...";
      });

      // Prepare multipart
      final uri = Uri.parse(BACKEND_URL);
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', path));

      // Send
      final streamedResponse = await request.send();

      // read streaming response (no progress from server, but we wait)
      final respStr = await streamedResponse.stream.bytesToString();
      if (streamedResponse.statusCode != 200) {
        setState(() {
          _isProcessing = false;
          _status = "Server error ${streamedResponse.statusCode}: $respStr";
        });
        return;
      }

      final jsonResp = jsonDecode(respStr);
      final prediction = jsonResp['prediction'] as String? ?? "Unknown";
      final probs = (jsonResp['probabilities'] as List?)
          .map((e) => (e as num).toDouble())
          .toList();
      double topProb = probs.isNotEmpty
          ? probs.reduce((a, b) => a > b ? a : b)
          : 0.0;

      setState(() {
        _isProcessing = false;
        _status =
            "Prediction: $prediction • Confidence: ${topProb.toStringAsFixed(4)}";
        _history.insert(
          0,
          HistoryItem(
            filename: name,
            prediction: prediction,
            confidence: topProb,
            time: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _status = "Error: ${e.toString()}";
      });
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Liver Cancer Detector",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          "Upload a whole-slide .svs image. The backend will run the model and return a result.",
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickAndUpload,
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload .svs"),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _history.clear();
                  _status = "History cleared";
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text("Clear history"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            if (_isProcessing) const CircularProgressIndicator(),
            if (_isProcessing) const SizedBox(width: 12),
            Expanded(
              child: Text(_status, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty)
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            "No history yet",
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final h = _history[index];
        final timeStr = DateFormat('HH:mm:ss').format(h.time);
        return ListTile(
          leading: CircleAvatar(child: Text(h.prediction[0].toUpperCase())),
          title: Text(h.filename),
          subtitle: Text(
            "${h.prediction} • ${h.confidence.toStringAsFixed(3)}",
          ),
          trailing: Text(timeStr),
          onTap: () {
            // show details popup
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(h.filename),
                content: Text(
                  "Prediction: ${h.prediction}\nConfidence: ${h.confidence.toStringAsFixed(4)}\nTime: $timeStr",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("WSI Liver Detector")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 18),
            const Text(
              "History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildHistoryList(),
            const SizedBox(height: 30),
            Center(
              child: Text(
                "Backend: $BACKEND_URL",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
