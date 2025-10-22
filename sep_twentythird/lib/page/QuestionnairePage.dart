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

  String rednessSeverity = '無';
  String scaling = '無';
  String itching = '否';
  String itchingNote = '';
  String fluid = '無';
  String recurrence = '單次';
  String lesionLocation = '';
  String duration = '';
  String usedMedication = '否';
  String medicationNote = '';
  String note = '';

  void submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    Map<String, dynamic> data = {
      'rednessSeverity': rednessSeverity,
      'hasScaling': scaling == '有',
      'hasItching': itching == '是',
      'itchingNote': itchingNote,
      'hasFluid': fluid == '有',
      'recurrence': recurrence,
      'lesionLocation': lesionLocation,
      'duration': duration,
      'usedMedication': usedMedication == '是',
      'medicationNote': medicationNote,
      'note': note
    };

    await uploadImageAndSurvey(widget.imagePath, data, context);
  }

  Widget buildRadioGroup(String label, String groupValue, List<String> options, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...options.map((option) => RadioListTile(
              title: Text(option),
              value: option,
              groupValue: groupValue,
              onChanged: onChanged,
            ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('皮膚症狀問卷')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.file(File(widget.imagePath), height: 200),
              const SizedBox(height: 20),
              buildRadioGroup('紅腫程度：', rednessSeverity, ['無', '輕度', '中度', '嚴重'], (val) => setState(() => rednessSeverity = val!)),
              buildRadioGroup('是否有皮屑脫落：', scaling, ['有', '無'], (val) => setState(() => scaling = val!)),
              buildRadioGroup('是否有癢感：', itching, ['是', '否'], (val) => setState(() => itching = val!)),
              if (itching == '是')
                TextFormField(
                  decoration: const InputDecoration(labelText: '請描述癢感的時機與特性'),
                  onSaved: (val) => itchingNote = val ?? '',
                ),
              buildRadioGroup('是否有滲液或濕潤現象：', fluid, ['有', '無'], (val) => setState(() => fluid = val!)),
              buildRadioGroup('發作頻率：', recurrence, ['單次', '偶爾反覆', '長期持續'], (val) => setState(() => recurrence = val!)),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: '病灶部位'),
                items: ['臉部', '手部', '腿部', '軀幹', '背部', '其他']
                    .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                    .toList(),
                onChanged: (val) => lesionLocation = val ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '症狀已持續多久（例如2週）'),
                onSaved: (val) => duration = val ?? '',
              ),
              buildRadioGroup('是否曾使用藥膏？', usedMedication, ['是', '否'], (val) => setState(() => usedMedication = val!)),
              if (usedMedication == '是')
                TextFormField(
                  decoration: const InputDecoration(labelText: '請描述使用藥物與效果'),
                  onSaved: (val) => medicationNote = val ?? '',
                ),
              TextFormField(
                decoration: const InputDecoration(labelText: '其他補充（如接觸史、過敏原等）'),
                maxLines: 3,
                onSaved: (val) => note = val ?? '',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('返回重拍'),
                  ),
                  ElevatedButton(
                    onPressed: submit,
                    child: const Text('送出分析'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('⚠️ 此結果僅供參考，請以醫師診斷為準。', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
