import 'package:flutter/material.dart';

/// =======================
/// 疾病類型
/// =======================
enum SeverityDisease {
  psoriasis, // 乾癬 PASI
  eczema, // 濕疹 / 異位性皮膚炎 EASI（簡化）
}

/// =======================
/// 嚴重度下拉選單
/// =======================
const Map<int, String> severityLabels = {
  0: "0 - 無",
  1: "1 - 輕微",
  2: "2 - 中等",
  3: "3 - 明顯",
  4: "4 - 嚴重",
};

/// =======================
/// 各部位「掌心法說明」
/// （僅顯示用，不影響 PASI/EASI 計算）
/// =======================
const Map<String, Map<int, String>> areaLabelsByRegion = {
  "頭": {
    0: "0 - 無",
    1: "1 - 約 1 掌（頭部 ~10%，全身 ~1%）",
    2: "2 - 約 2 掌（頭部 ~20%，全身 ~2%）",
    3: "3 - 約 3~4 掌（頭部 ~30~40%）",
    4: "4 - 約 5~6 掌（頭部 ~50~60%）",
    5: "5 - 約 7~8 掌（頭部 ~70~80%）",
    6: "6 - 幾乎整個頭部（≥90%）",
  },
  "上肢": {
    0: "0 - 無",
    1: "1 - 約 1~2 掌（<10%，全身 ~1~2%）",
    2: "2 - 約 3~6 掌（10~29%）",
    3: "3 - 約 7~10 掌（30~49%）",
    4: "4 - 約 11~14 掌（50~69%）",
    5: "5 - 約 15~18 掌（70~89%）",
    6: "6 - 幾乎整個上肢（≥90%）",
  },
  "軀幹": {
    0: "0 - 無",
    1: "1 - 約 3 掌（<10%，全身 ~3%）",
    2: "2 - 約 4~9 掌（10~29%）",
    3: "3 - 約 10~14 掌（30~49%）",
    4: "4 - 約 15~20 掌（50~69%）",
    5: "5 - 約 21~26 掌（70~89%）",
    6: "6 - 幾乎整個軀幹（≥90%）",
  },
  "下肢": {
    0: "0 - 無",
    1: "1 - 約 4 掌（<10%，全身 ~4%）",
    2: "2 - 約 5~11 掌（10~29%）",
    3: "3 - 約 12~18 掌（30~49%）",
    4: "4 - 約 19~25 掌（50~69%）",
    5: "5 - 約 26~35 掌（70~89%）",
    6: "6 - 幾乎整條下肢（≥90%）",
  },
};

/// =======================
/// 「面積等級 → 掌心數」
/// 這裡用你 UI 文字的「中位數估計」
/// 目的：讓 BSA 用掌心法真的算得出來
/// =======================
const Map<String, List<int>> palmsByRegionAndArea = {
  // index 0..6 對應 area 0..6
  "頭":   [0, 1, 2, 4, 6, 8, 9],   // 3~4 -> 4, 5~6 -> 6, 7~8 -> 8, ≥90% -> 9（保守）
  "上肢": [0, 2, 5, 9, 13, 17, 18], // 1~2->2, 3~6->5, 7~10->9, 11~14->13, 15~18->17
  "軀幹": [0, 3, 7, 12, 18, 24, 26], // 4~9->7, 10~14->12, 15~20->18, 21~26->24, ≥90%->26
  "下肢": [0, 4, 8, 15, 22, 31, 35], // 5~11->8, 12~18->15, 19~25->22, 26~35->31, ≥90%->35
};

int estimatePalms(String region, int areaScore) {
  final list = palmsByRegionAndArea[region];
  if (list == null) return 0;
  if (areaScore < 0) return 0;
  if (areaScore > 6) return list.last;
  return list[areaScore];
}

/// =======================
/// 主頁
/// =======================
class SeverityCalculatorPage extends StatefulWidget {
  const SeverityCalculatorPage({super.key});

  @override
  State<SeverityCalculatorPage> createState() => _SeverityCalculatorPageState();
}

class _SeverityCalculatorPageState extends State<SeverityCalculatorPage> {
  SeverityDisease disease = SeverityDisease.psoriasis;

  /// 四個部位
  /// area：面積「分級 0..6」給 PASI/EASI 用（你原本的）
  /// bsaPalm：掌心數（新增，用來算 BSA）
  final Map<String, Map<String, int>> regions = {
    "頭": {"a": 0, "b": 0, "c": 0, "d": 0, "area": 0, "bsaPalm": 0},
    "上肢": {"a": 0, "b": 0, "c": 0, "d": 0, "area": 0, "bsaPalm": 0},
    "軀幹": {"a": 0, "b": 0, "c": 0, "d": 0, "area": 0, "bsaPalm": 0},
    "下肢": {"a": 0, "b": 0, "c": 0, "d": 0, "area": 0, "bsaPalm": 0},
  };

  /// =======================
  /// PASI（你原本寫法 OK）
  /// =======================
  double calcPASI() {
    const weights = {"頭": 0.1, "上肢": 0.2, "軀幹": 0.3, "下肢": 0.4};
    double total = 0;

    regions.forEach((region, d) {
      final areaScore = d["area"] ?? 0;
      if (areaScore == 0) return;

      final severity = (d["a"] ?? 0) + (d["b"] ?? 0) + (d["c"] ?? 0);
      total += severity * areaScore * weights[region]!;
    });

    return total;
  }

  /// =======================
  /// EASI（結構 OK；你把它當簡化 EASI 沒問題）
  /// =======================
  double calcEASI() {
    const weights = {"頭": 0.1, "上肢": 0.2, "軀幹": 0.3, "下肢": 0.4};
    double total = 0;

    regions.forEach((region, d) {
      final areaScore = d["area"] ?? 0;
      if (areaScore == 0) return;

      final severity = (d["a"] ?? 0) + (d["b"] ?? 0) + (d["c"] ?? 0) + (d["d"] ?? 0);
      total += severity * areaScore * weights[region]!;
    });

    return total;
  }

  /// =======================
  /// BSA（掌心法：1 掌 ≈ 1%）
  /// =======================
  // double calcBSA() {
  //   double total = 0;
  //   regions.forEach((_, d) {
  //     total += (d["bsaPalm"] ?? 0) * 1.0;
  //   });
  //   return total;
  // }

  /// =======================
  /// 分級
  /// =======================
  String getSeverityLevel(double score) {
    if (score < 7) return "輕度";
    if (score < 12) return "中度";
    return "重度";
  }

  /// =======================
  /// 下拉選單
  /// =======================
  Widget buildDropdown({
    required String label,
    required String keyName,
    required Map<String, int> data,
    required Map<int, String> options,
    required bool enabled,
    ValueChanged<int?>? onChanged, // ✅ 允許針對 area 做特例
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: enabled ? Colors.white : Colors.white38,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: data[keyName],
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              filled: !enabled,
              fillColor: enabled ? null : Colors.white10,
            ),
            items: options.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: enabled
                ? (v) {
                    if (onChanged != null) return onChanged(v);
                    setState(() => data[keyName] = v ?? 0);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget buildRegion(String region) {
    final d = regions[region]!;
    final enabled = (d["area"] ?? 0) > 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(region, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

            buildDropdown(
              label: "紅斑",
              keyName: "a",
              data: d,
              options: severityLabels,
              enabled: enabled,
            ),

            buildDropdown(
              label: "厚度 / 浸潤",
              keyName: "b",
              data: d,
              options: severityLabels,
              enabled: enabled,
            ),

            buildDropdown(
              label: "鱗屑 / 抓痕",
              keyName: "c",
              data: d,
              options: severityLabels,
              enabled: enabled,
            ),

            if (disease == SeverityDisease.eczema)
              buildDropdown(
                label: "苔癬化",
                keyName: "d",
                data: d,
                options: severityLabels,
                enabled: enabled,
              ),

            const Divider(),

            /// ✅ 你原本只有一個面積下拉：保留
            /// ✅ 但選的同時，額外把掌心數存進 bsaPalm，讓 BSA 正確
            buildDropdown(
              label: "病灶面積（掌心法）",
              keyName: "area",
              data: d,
              options: areaLabelsByRegion[region]!,
              enabled: true,
              onChanged: (v) {
                final areaScore = v ?? 0;
                setState(() {
                  d["area"] = areaScore;
                  d["bsaPalm"] = estimatePalms(region, areaScore); // ✅ 新增同步紀錄
                });
              },
            ),

            // ✅ 非必要，但超有用：直接顯示這部位目前換算出的掌心數（不影響你原本顯示）
            // Text(
            //   "（本部位估計：${d["bsaPalm"]} 掌 ≈ ${d["bsaPalm"]}%）",
            //   style: const TextStyle(fontSize: 12, color: Colors.white70),
            // ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = disease == SeverityDisease.psoriasis ? calcPASI() : calcEASI();
    // final bsa = calcBSA();

    return Scaffold(
      appBar: AppBar(title: const Text("皮膚病嚴重度計算")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<SeverityDisease>(
              value: disease,
              decoration: const InputDecoration(labelText: "選擇疾病"),
              items: const [
                DropdownMenuItem(
                  value: SeverityDisease.psoriasis,
                  child: Text("乾癬（PASI）"),
                ),
                DropdownMenuItem(
                  value: SeverityDisease.eczema,
                  child: Text("濕疹 / 異位性皮膚炎（EASI）"),
                ),
              ],
              onChanged: (v) => setState(() => disease = v!),
            ),
            const SizedBox(height: 12),
            ...regions.keys.map(buildRegion),
            const SizedBox(height: 20),
            // Text("BSA：約 ${bsa.toStringAsFixed(1)} %",
            //     style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("總分：${score.toStringAsFixed(1)}",
                style: const TextStyle(fontSize: 20)),
            Text("嚴重度分級：${getSeverityLevel(score)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
