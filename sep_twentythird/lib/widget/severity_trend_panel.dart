import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../service/severity_record_dao.dart';

/// =====================================================
/// SeverityTrendPanel
/// - 可重用：大版（計算頁）/ 迷你版（主畫面）
/// - ✅ 支援 refresh()：存完評估後立刻更新
/// - ✅ 點某個點：展開該次四部位明細（含濕疹 d 欄）
///
/// ⚠️ 重要：UI 外觀完全不改
/// ✅ 只改「點擊查明細」改用 id（不再用 created_at 當 key）
/// =====================================================
class SeverityTrendPanel extends StatefulWidget {
  final String disease; // psoriasis / eczema
  final int limit;
  final bool mini;

  const SeverityTrendPanel({
    super.key,
    required this.disease,
    this.limit = 8, // 我幫你預設 8，比 5 更好看也合理
    this.mini = false,
  });

  @override
  State<SeverityTrendPanel> createState() => _SeverityTrendPanelState();
}

class _SeverityTrendPanelState extends State<SeverityTrendPanel> {
  final _dao = SeverityRecordDao();

  bool _loading = true;

  /// rows：[{id, created_at, total_score}, ...]（舊→新）
  /// ※ 這裡「一定要有 id」，點擊要用
  List<Map<String, dynamic>> _rows = [];

  /// spots：[(0,score0),(1,score1)...]
  List<FlSpot> _spots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// ✅ 外部可呼叫：讓你存完直接更新圖表
  Future<void> refresh() async {
    await _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _rows = [];
        _spots = [];
      });
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }

    // ✅ 這裡拿到的 rows 會包含 id/created_at/total_score
    final rows = await _dao.getRecentScores(
      uid: user.uid,
      disease: widget.disease,
      limit: widget.limit,
    );

    final spots = List.generate(rows.length, (i) {
      final y = (rows[i]['total_score'] as num).toDouble();
      return FlSpot(i.toDouble(), y);
    });

    if (!mounted) return;
    setState(() {
      _rows = rows;
      _spots = spots;
      _loading = false;
    });
  }

  String _title() {
    if (widget.disease == 'psoriasis') return '乾癬（PASI）近期趨勢';
    return '濕疹（EASI）近期趨勢';
  }

  /// 讓圖不會「貼地板」：依資料自動抓合理 maxY
  double _autoMaxY() {
    if (_spots.isEmpty) return 10;
    final maxVal = _spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final padded = (maxVal + 2).clamp(5, 72); // PASI 最高 72，留點空間
    return padded.toDouble();
  }

  Future<void> _onSpotTap(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (index < 0 || index >= _rows.length) return;

    // ================================
    // ✅ UI 顯示仍用 createdAt（只是顯示）
    // ✅ 明細查詢改用 id（核心修正）
    // ================================
    final createdAt = (_rows[index]['created_at'] ?? '').toString();
    final totalScore = (_rows[index]['total_score'] as num).toDouble();

    // ✅ 關鍵：拿 id 查明細（不再用 created_at）
    final rawId = _rows[index]['id'];
    final int? id = rawId is int ? rawId : int.tryParse(rawId.toString());

    // id 不存在就直接回傳空（理論上不應該）
    final detailRows = (id == null)
        ? <Map<String, dynamic>>[]
        : await _dao.getRecordsById(id: id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true, // ⭐ 關鍵 1
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6, // ⭐ 保持「差不多現在大小」
            child: SingleChildScrollView( // ⭐ 關鍵 2
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "評估時間：$createdAt",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("總分：${totalScore.toStringAsFixed(1)}"),
                  const SizedBox(height: 12),
                  const Text(
                    "各部位評估",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ...detailRows.map((r) {
                    final region = (r['region'] ?? '').toString();
                    final a = r['a'] ?? 0;
                    final b = r['b'] ?? 0;
                    final c = r['c'] ?? 0;
                    final d = r['d'] ?? 0;
                    final area = r['area'] ?? 0;

                    final showD = widget.disease == 'eczema';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(region, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              _kv("面積", area.toString()),
                              _kv("紅斑", a.toString()),
                              _kv("厚度/浸潤", b.toString()),
                              _kv("鱗屑/抓痕", c.toString()),
                              if (showD) _kv("苔癬化", d.toString()),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  if (detailRows.isEmpty)
                    const Text(
                      "（找不到該次明細，可能資料尚未寫入 severity_assessment / 或 id 遺失）",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text("$k：$v"),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_spots.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(widget.mini ? "—" : "尚無歷史紀錄"),
        ),
      );
    }

    final maxY = _autoMaxY();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        // ✅ 增加留白，避免你說的「上下太擠」「靠左」
        padding: EdgeInsets.fromLTRB(14, widget.mini ? 10 : 12, 14, widget.mini ? 10 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.mini)
              Text(
                _title(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            if (!widget.mini) const SizedBox(height: 10),

            SizedBox(
              height: widget.mini ? 80 : 190,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,

                  // ✅ 格線保留（mini 就關掉）
                  gridData: FlGridData(show: !widget.mini),

                  // ✅ 邊框簡化
                  borderData: FlBorderData(show: false),

                  // ✅ 只留 X 軸「第 1 次/第 2 次…」，左右軸數字全部關掉
                  titlesData: widget.mini
                      ? const FlTitlesData(show: false)
                      : FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              reservedSize: 26,
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= _rows.length) return const SizedBox.shrink();
                                // 只顯示第 1 次、第 2 次…（你要的）
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text("第 ${idx + 1} 次", style: const TextStyle(fontSize: 11)),
                                );
                              },
                            ),
                          ),
                        ),

                  // ✅ 點擊事件（mini 不開）
                  lineTouchData: LineTouchData(
                    enabled: !widget.mini,
                    handleBuiltInTouches: true,
                    touchCallback: (event, response) {
                      if (widget.mini) return;
                      if (event is FlTapUpEvent && response?.lineBarSpots?.isNotEmpty == true) {
                        final idx = response!.lineBarSpots!.first.x.toInt();
                        _onSpotTap(idx);
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((s) {
                          return LineTooltipItem(
                            "第 ${s.x.toInt() + 1} 次\n分數 ${s.y.toStringAsFixed(1)}",
                            const TextStyle(fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: _spots,
                      isCurved: true,
                      barWidth: widget.mini ? 2 : 3,
                      dotData: FlDotData(show: !widget.mini),
                      color: widget.disease == 'psoriasis' ? Colors.blue : Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
