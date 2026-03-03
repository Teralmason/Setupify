import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _groqApiKey =
      "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";
  static const String _tavilyApiKey =
      "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";
  static const String _groqUrl =
      "https://api.groq.com/openai/v1/chat/completions";
  static const String _tavilyUrl = "https://api.tavily.com/search";

  static Future<String> internetteAra(String sorgu) async {
    try {
      final response = await http.post(
        Uri.parse(_tavilyUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "api_key": _tavilyApiKey,
          "query": sorgu,
          "search_depth": "advanced",
          "max_results": 3,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return (data['results'] as List)
            .map((e) => "KAYNAK: ${e['title']}\nİÇERİK: ${e['content']}")
            .join("\n\n");
      }
    } catch (e) {
      print("Arama hatası: $e");
    }
    return "";
  }

  static Future<String> cevapAl(
    List<Map<String, String>> sohbetGecmisi, {
    String model = "llama-3.1-8b-instant",
  }) async {
    String sonMesaj =
        sohbetGecmisi.isNotEmpty ? (sohbetGecmisi.last['content'] ?? "") : "";
    String aramaSonucu = "";

    List<String> tetikleyiciler = [
      "kim",
      "ne zaman",
      "kaç",
      "nasıl",
      "fiyat",
      "benchmark",
      "vs"
    ];
    bool bilgiSorusu =
        tetikleyiciler.any((k) => sonMesaj.toLowerCase().contains(k));

    if (bilgiSorusu && sonMesaj.length > 5) {
      aramaSonucu = await internetteAra(sonMesaj);
    }

    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          "Authorization": "Bearer $_groqApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": model,
          "messages": [
            {
              "role": "system",
              "content": "Sen 'Setuply Guru' adında CIDDI bir donanım uzmanısın. "
                  "HAYATI KURAL: Teknik verilerde asla hata yapma. "
                  "1. Donanım isimlerini (Örn: **RTX 4060**, **i5-13400F**) mutlaka KALIN yaz. "
                  "2. Tavsiyelerini mutlaka MADDELER halinde (-) sun. "
                  "3. Anakart ve işlemci uyumuna bakmadan tavsiye verme. "
                  "Üslubun: Bilgili biri gibi güven verici ve teknik olsun. "
                  "Güncel Bilgi: $aramaSonucu",
            },
            ...sohbetGecmisi,
          ],
          "temperature": 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        return "Hata kodu: ${response.statusCode} - Guru meşgul usta.";
      }
    } catch (e) {
      return "Bağlantı koptu reis.";
    }
  }
}
