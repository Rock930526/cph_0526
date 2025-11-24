// === QuestionnairePage.dart ===
import 'package:flutter/material.dart';
import 'dart:io';
import '../service/api_services.dart';

class QuestionnairePage extends StatefulWidget {
  final String imagePath;
  const QuestionnairePage({super.key, required this.imagePath});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final _formKey = GlobalKey<FormState>();

  // ============================
  // 問卷資料（依皮膚科問診邏輯）
  // ============================

  // 基本資料
  String age = '';
  String gender = '男';
  String contact = '';

  // 病程
  String onset = '';
  String firstTime = '是';
  String recurrenceBefore = '否';
  String stillActive = '是';

  // 症狀
  String itching = '否';
  String itchingScore = '';
  String itchingNight = '否';
  String pain = '否';
  String fluid = '否';
  String scaling = '否';
  String blister = '否';

  // 分布與型態
  String border = '';
  List<String> locations = [];
  String symmetric = '否';

  // 病史
  List<String> pastDisease = [];
  List<String> familyHistory = [];

  // 接觸史 / 誘因
  String contactNew = '否';
  String contactNewNote = '';
  List<String> recentFactors = [];
  String otherFactors = '';

  // 治療經歷 / 影響
  String treated = '否';
  String treatedNote = '';
  String impact = '無影響';
  String impactNote = '';

  // 補充
  String extra = '';

  // ============================
  // UI Helper
  // ============================

  Widget buildTitle(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget buildRadioGroup(
      String label, String groupValue, List<String> options, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ...options.map((o) => RadioListTile(
              value: o,
              groupValue: groupValue,
              title: Text(o),
              onChanged: onChanged,
            ))
      ],
    );
  }

  Widget buildCheckGroup(
      String label, List<String> options, List<String> selected, void Function(bool, String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ...options.map((o) => CheckboxListTile(
              value: selected.contains(o),
              title: Text(o),
              onChanged: (val) => onChanged(val ?? false, o),
            ))
      ],
    );
  }

  // ============================
  // 送出
  // ============================
  void submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    Map<String, dynamic> data = {
      // 基本資料
      "age": age,
      "gender": gender,
      "contact": contact,

      // 病程
      "onset": onset,
      "firstTime": firstTime == "是",
      "recurrenceBefore": recurrenceBefore == "是",
      "stillActive": stillActive == "是",

      // 症狀
      "itching": itching == "是",
      "itchingScore": itchingScore,
      "itchingNight": itchingNight == "是",
      "pain": pain == "是",
      "fluid": fluid == "是",
      "scaling": scaling == "是",
      "blister": blister == "是",

      // 分布
      "border": border,
      "locations": locations,
      "symmetric": symmetric == "是",

      // 病史
      "pastDisease": pastDisease,
      "familyHistory": familyHistory,

      // 接觸史與誘因
      "contactNew": contactNew == "是",
      "contactNewNote": contactNewNote,
      "recentFactors": recentFactors,
      "otherFactors": otherFactors,

      // 影響與治療
      "treated": treated == "是",
      "treatedNote": treatedNote,
      "impact": impact,
      "impactNote": impactNote,

      // 補充
      "extra": extra
    };

    await uploadImageAndSurvey(widget.imagePath, data, context);
  }

  // ============================
  // UI
  // ============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("皮膚症狀自述問卷")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.file(File(widget.imagePath), height: 200),
              const SizedBox(height: 20),

              // ------------------------------------
              // 一、基本資料
              // ------------------------------------
              buildTitle("一、基本資料"),

              TextFormField(
                decoration: const InputDecoration(labelText: "年齡"),
                keyboardType: TextInputType.number,
                onSaved: (v) => age = v ?? "",
              ),

              buildRadioGroup("性別", gender, ["男", "女", "其他"],
                  (v) => setState(() => gender = v!)),

              TextFormField(
                decoration: const InputDecoration(labelText: "聯絡方式（選填）"),
                onSaved: (v) => contact = v ?? "",
              ),

              // ------------------------------------
              // 二、病程
              // ------------------------------------
              buildTitle("二、主訴與病程"),

              buildRadioGroup(
                  "症狀出現時間",
                  onset,
                  ["< 3天", "3–7天", "一週以上但 <1月", "≥1月", "記不清楚"],
                  (v) => setState(() => onset = v!)),

              buildRadioGroup("是否首次發生？", firstTime, ["是", "否"],
                  (v) => setState(() => firstTime = v!)),

              buildRadioGroup("是否曾反覆發作？", recurrenceBefore, ["是", "否", "不確定"],
                  (v) => setState(() => recurrenceBefore = v!)),

              buildRadioGroup(
                  "症狀是否仍持續？", stillActive, ["是", "否"],
                  (v) => setState(() => stillActive = v!)),

              // ------------------------------------
              // 三、症狀
              // ------------------------------------
              buildTitle("三、症狀與表現"),

              buildRadioGroup("是否有癢感？", itching, ["是", "否"],
                  (v) => setState(() => itching = v!)),

              if (itching == "是")
                TextFormField(
                  decoration: const InputDecoration(labelText: "癢感程度 1–10"),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => itchingScore = v ?? "",
                ),

              if (itching == "是")
                buildRadioGroup("夜間是否更嚴重？", itchingNight, ["是", "否"],
                    (v) => setState(() => itchingNight = v!)),

              buildRadioGroup("是否有痛感？", pain, ["是", "否"],
                  (v) => setState(() => pain = v!)),

              buildRadioGroup("是否有滲液？", fluid, ["是", "否"],
                  (v) => setState(() => fluid = v!)),

              buildRadioGroup("是否有皮屑？", scaling, ["是", "否"],
                  (v) => setState(() => scaling = v!)),

              buildRadioGroup("是否有水泡／膿泡？", blister, ["是", "否"],
                  (v) => setState(() => blister = v!)),

              // ------------------------------------
              // 四、分布特徵
              // ------------------------------------
              buildTitle("四、病灶特徵與分佈"),

              buildRadioGroup("邊界型態", border,
                  ["邊界清楚", "邊界模糊", "環狀"], (v) => setState(() => border = v!)),

              buildCheckGroup(
                "主要病灶部位（可複選）",
                [
                  "頭皮", "臉部", "耳後／頸部", "胸背",
                  "四肢伸側", "四肢屈側", "手指／趾縫",
                  "生殖／臀部", "指甲／趾甲", "其他"
                ],
                locations,
                (checked, value) {
                  setState(() {
                    checked ? locations.add(value) : locations.remove(value);
                  });
                },
              ),

              buildRadioGroup(
                  "是否對稱分布？", symmetric, ["是", "否"],
                  (v) => setState(() => symmetric = v!)),

              // ------------------------------------
              // 五、病史
              // ------------------------------------
              buildTitle("五、病史與相關背景"),

              buildCheckGroup(
                "曾被診斷的疾病（可複選）",
                [
                  "異位性皮膚炎",
                  "牛皮癬",
                  "接觸性皮膚炎",
                  "蕁麻疹",
                  "白癜風",
                  "甲真菌感染",
                  "其他"
                ],
                pastDisease,
                (checked, value) {
                  setState(() {
                    checked ? pastDisease.add(value) : pastDisease.remove(value);
                  });
                },
              ),

              buildCheckGroup(
                "家族病史（可複選）",
                [
                  "過敏性鼻炎／哮喘",
                  "濕疹",
                  "自身免疫疾病",
                  "家族皮膚病",
                  "無或不清楚"
                ],
                familyHistory,
                (checked, value) {
                  setState(() {
                    checked
                        ? familyHistory.add(value)
                        : familyHistory.remove(value);
                  });
                },
              ),

              // ------------------------------------
              // 六、接觸史與誘因
              // ------------------------------------
              buildTitle("六、接觸史與可能誘因"),

              buildRadioGroup(
                  "是否近期使用新產品或化學品？",
                  contactNew, ["是", "否", "不確定"],
                  (v) => setState(() => contactNew = v!)),

              if (contactNew == "是")
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: "請描述新產品或化學品"),
                  onSaved: (v) => contactNewNote = v ?? "",
                ),

              buildCheckGroup(
                "最近是否出現以下情況？（可複選）",
                [
                  "強日曬／紫外線曝露",
                  "高溫或潮濕",
                  "壓力大",
                  "情緒波動",
                  "飲食辛辣／酒精",
                  "睡眠不足",
                  "旅遊／接觸動物",
                ],
                recentFactors,
                (checked, value) {
                  setState(() {
                    checked
                        ? recentFactors.add(value)
                        : recentFactors.remove(value);
                  });
                },
              ),

              TextFormField(
                decoration:
                    const InputDecoration(labelText: "其他可能的誘發因素"),
                onSaved: (v) => otherFactors = v ?? "",
              ),

              // ------------------------------------
              // 七、治療經歷與影響
              // ------------------------------------
              buildTitle("七、治療與生活影響"),

              buildRadioGroup(
                  "是否曾接受治療？", treated, ["是", "否"],
                  (v) => setState(() => treated = v!)),

              if (treated == "是")
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: "請描述治療方式與反應"),
                  onSaved: (v) => treatedNote = v ?? "",
                ),

              buildRadioGroup("對生活影響程度", impact,
                  ["無影響", "輕微影響", "顯著影響"],
                  (v) => setState(() => impact = v!)),

              if (impact == "顯著影響")
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: "請描述影響內容"),
                  onSaved: (v) => impactNote = v ?? "",
                ),

              // ------------------------------------
              // 八、其他補充
              // ------------------------------------
              buildTitle("八、其他補充"),

              TextFormField(
                decoration:
                    const InputDecoration(labelText: "有無其他重要補充？"),
                maxLines: 3,
                onSaved: (v) => extra = v ?? "",
              ),

              const SizedBox(height: 20),

              // ------------------------------------
              // 按鈕
              // ------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("返回重拍")),
                  ElevatedButton(
                      onPressed: submit, child: const Text("送出分析")),
                ],
              ),

              const SizedBox(height: 10),
              const Text(
                "⚠️ 此結果僅供參考，請以醫師診斷為主。",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              )
            ],
          ),
        ),
      ),
    );
  }
}
