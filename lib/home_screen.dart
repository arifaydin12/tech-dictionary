import 'package:flutter/material.dart';
import 'word_model.dart';
import 'add_word_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Örnek Başlangıç Verileri
  List<Word> allWords = [
    Word(term: "Flutter", definition: "Google tarafından geliştirilen açık kaynaklı UI kiti.", category: "Mobile"),
    Word(term: "Widget", definition: "Flutter'da arayüzü oluşturan temel yapı taşı.", category: "Core"),
    Word(term: "API", definition: "Uygulamaların birbirleriyle konuşmasını sağlayan arayüz.", category: "Backend"),
    Word(term: "Async", definition: "Eşzamansız programlama yapısı.", category: "Dart"),
  ];

  List<Word> filteredWords = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredWords = allWords;
  }

  void _filterWords(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredWords = allWords;
      } else {
        filteredWords = allWords
            .where((word) =>
                word.term.toLowerCase().contains(query.toLowerCase()) ||
                word.definition.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Hafif gri arka plan
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: filteredWords.isEmpty
                ? const Center(child: Text("Kelime bulunamadı."))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 80),
                    itemCount: filteredWords.length,
                    itemBuilder: (context, index) {
                      final word = filteredWords[index];
                      return _buildWordCard(word);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Kelime Ekleme Sayfasına Git ve Sonucu Bekle
          final newWord = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddWordScreen()),
          );

          if (newWord != null && newWord is Word) {
            setState(() {
              allWords.add(newWord);
              _filterWords(searchController.text);
            });
          }
        },
        backgroundColor: const Color(0xFF4C51BF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF4C51BF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tech Dictionary",
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            "Teknik terim kütüphanen",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: searchController,
            onChanged: _filterWords,
            decoration: InputDecoration(
              hintText: "Terim ara...",
              prefixIcon: const Icon(Icons.search, color: Color(0xFF4C51BF)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(Word word) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                word.term,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  word.category,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF4C51BF), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            word.definition,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }
}