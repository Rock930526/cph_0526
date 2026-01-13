import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../service/user_profile.dart';
import '../service/user_profile_dao.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _dao = UserProfileDao();

  // Firebase
  late final String _uid;
  String? _email;

  // 基本資料
  DateTime? _birthday;
  String _gender = 'M'; // M / F / O
  double _height = 170;
  double _weight = 65;

  // 慢性病
  final Set<String> _chronicConditions = {};
  final List<String> _conditionOptions = [
    '乾癬',
    '異位性皮膚炎',
    '糖尿病',
    '高血壓',
    '氣喘',
  ];

  // 聯絡資訊
  final TextEditingController _phoneCtrl = TextEditingController();

  bool _loading = true;

  // =========================
  // 初始化：讀 SQLite
  // =========================
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser!;
    _uid = user.uid;
    _email = user.email;

    final profile = await _dao.getProfileByUid(_uid);

    if (profile != null) {
      if (profile.birthday != null) {
        _birthday = DateTime.tryParse(profile.birthday!);
      }

      if (profile.gender != null) {
        _gender = profile.gender!;
      }

      if (profile.heightCm != null) {
        _height = profile.heightCm!;
      }

      if (profile.weightKg != null) {
        _weight = profile.weightKg!;
      }

      if (profile.chronicConditions != null &&
          profile.chronicConditions!.isNotEmpty) {
        _chronicConditions
            .addAll(profile.chronicConditions!.split(','));
      }

      _phoneCtrl.text = profile.phone ?? '';
    }

    setState(() => _loading = false);
  }

  // =========================
  // 日期選擇
  // =========================
  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  // =========================
  // 儲存到 SQLite
  // =========================
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dao = UserProfileDao();

    await dao.upsertProfile(
      uid: user.uid,
      birthday: _birthday,
      gender: _gender,
      heightCm: _height,
      weightKg: _weight,
      chronicConditions: _chronicConditions,
      email: user.email,
      phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }


  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('個人健康資料'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            title: '基本資料',
            children: [
              _birthdayTile(),
              const SizedBox(height: 12),
              _genderSelector(),
            ],
          ),

          _sectionCard(
            title: '身體數據',
            children: [
              _sliderField(
                label: '身高',
                unit: 'cm',
                value: _height,
                min: 100,
                max: 220,
                onChanged: (v) => setState(() => _height = v),
              ),
              const SizedBox(height: 12),
              _sliderField(
                label: '體重',
                unit: 'kg',
                value: _weight,
                min: 30,
                max: 200,
                onChanged: (v) => setState(() => _weight = v),
              ),
            ],
          ),

          _sectionCard(
            title: '慢性疾病',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _conditionOptions.map((c) {
                  return FilterChip(
                    label: Text(c),
                    selected: _chronicConditions.contains(c),
                    onSelected: (v) {
                      setState(() {
                        v
                            ? _chronicConditions.add(c)
                            : _chronicConditions.remove(c);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),

          _sectionCard(
            title: '聯絡資訊',
            children: [
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: '手機號碼',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('儲存資料'),
          ),
        ],
      ),
    );
  }

  // =========================
  // 共用元件
  // =========================
  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _birthdayTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('生日'),
      subtitle: Text(
        _birthday == null
            ? '請選擇'
            : '${_birthday!.year}-${_birthday!.month}-${_birthday!.day}',
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: _pickBirthday,
    );
  }

  Widget _genderSelector() {
    return ToggleButtons(
      isSelected: [
        _gender == 'M',
        _gender == 'F',
        _gender == 'O',
      ],
      onPressed: (i) {
        setState(() => _gender = ['M', 'F', 'O'][i]);
      },
      borderRadius: BorderRadius.circular(12),
      children: const [
        Padding(padding: EdgeInsets.all(8), child: Text('男')),
        Padding(padding: EdgeInsets.all(8), child: Text('女')),
        Padding(padding: EdgeInsets.all(8), child: Text('其他')),
      ],
    );
  }

  Widget _sliderField({
    required String label,
    required String unit,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label：${value.round()} $unit'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
