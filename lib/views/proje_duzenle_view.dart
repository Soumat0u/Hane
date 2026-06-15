import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hano/models/project.dart';
import 'package:hano/providers/finance_provider.dart';
import 'package:hano/services/database_helper.dart';

class ProjeDuzenleView extends StatefulWidget {
  final Project project;

  const ProjeDuzenleView({super.key, required this.project});

  @override
  State<ProjeDuzenleView> createState() => _ProjeDuzenleViewState();
}

class _ProjeDuzenleViewState extends State<ProjeDuzenleView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _areaController;
  late TextEditingController _unitCountController;
  late TextEditingController _shopCountController;
  late TextEditingController _estimatedCostController;
  late TextEditingController _estimatedRevenueController;

  late String _selectedStatus;

  final List<Map<String, String>> _statusOptions = [
    {'status': 'Planlama', 'color': '0xFF3B82F6', 'bg': '0xFFEFF6FF'},
    {'status': 'Ruhsat Aşaması', 'color': '0xFFF59E0B', 'bg': '0xFFFFF7ED'},
    {'status': 'Temel Aşamasında', 'color': '0xFF8B5CF6', 'bg': '0xFFFAF5FF'},
    {'status': 'Kaba İnşaat', 'color': '0xFF6366F1', 'bg': '0xFFEEF2FF'},
    {'status': 'İnce İşçilik', 'color': '0xFF14B8A6', 'bg': '0xFFF0FDFA'},
    {'status': 'Tamamlandı', 'color': '0xFF10B981', 'bg': '0xFFF0FDF4'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _locationController = TextEditingController(text: widget.project.location);
    _areaController = TextEditingController(text: widget.project.areaSqMeters > 0 ? widget.project.areaSqMeters.toString() : '');
    _unitCountController = TextEditingController(text: widget.project.unitCount > 0 ? widget.project.unitCount.toString() : '');
    _shopCountController = TextEditingController(text: widget.project.shopCount > 0 ? widget.project.shopCount.toString() : '');
    _estimatedCostController = TextEditingController(text: widget.project.estimatedTotalCost > 0 ? widget.project.estimatedTotalCost.toInt().toString() : '');
    _estimatedRevenueController = TextEditingController(text: widget.project.estimatedTotalRevenue > 0 ? widget.project.estimatedTotalRevenue.toInt().toString() : '');
    
    // Validate if initial status is in options
    bool exists = _statusOptions.any((opt) => opt['status'] == widget.project.status);
    _selectedStatus = exists ? widget.project.status : 'Planlama';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _areaController.dispose();
    _unitCountController.dispose();
    _shopCountController.dispose();
    _estimatedCostController.dispose();
    _estimatedRevenueController.dispose();
    super.dispose();
  }

  void _updateProject() async {
    if (_formKey.currentState!.validate()) {
      final selectedStatusData = _statusOptions.firstWhere((element) => element['status'] == _selectedStatus);
      
      final updatedProject = Project(
        id: widget.project.id,
        name: _nameController.text.trim(),
        status: _selectedStatus,
        statusColorHex: selectedStatusData['color']!,
        statusBgColorHex: selectedStatusData['bg']!,
        location: _locationController.text.trim(),
        areaSqMeters: int.tryParse(_areaController.text) ?? 0,
        unitCount: int.tryParse(_unitCountController.text) ?? 0,
        shopCount: int.tryParse(_shopCountController.text) ?? 0,
        estimatedTotalCost: double.tryParse(_estimatedCostController.text) ?? 0.0,
        estimatedTotalRevenue: double.tryParse(_estimatedRevenueController.text) ?? 0.0,
        imagePath: widget.project.imagePath,
      );

      await DatabaseHelper.instance.updateProject(updatedProject);
      
      if (mounted) {
        Provider.of<FinanceProvider>(context, listen: false).refreshData();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proje başarıyla güncellendi!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Projeyi Düzenle',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF032B5E)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Project Image Placeholder
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/modern_apartment_building.png'),
                      fit: BoxFit.cover,
                      opacity: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.add_a_photo, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Görsel Yükle (Opsiyonel)',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Temel Bilgiler'),
              const SizedBox(height: 12),
              _buildInputField('Proje Adı', _nameController, TextInputType.text, icon: Icons.business),
              const SizedBox(height: 16),
              _buildInputField('Konum (Örn: İstanbul / Başakşehir)', _locationController, TextInputType.text, icon: Icons.location_on),
              const SizedBox(height: 16),
              
              const Text(
                'Durum',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                    items: _statusOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option['status'],
                        child: Text(
                          option['status']!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        if (value != null) _selectedStatus = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Fiziksel Detaylar'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInputField('Alan (m²)', _areaController, TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputField('Konut Sayısı', _unitCountController, TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputField('Dükkan Sayısı', _shopCountController, TextInputType.number)),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Finansal Öngörüler'),
              const SizedBox(height: 12),
              _buildInputField('Öngörülen Toplam Maliyet (₺)', _estimatedCostController, TextInputType.number, icon: Icons.money_off),
              const SizedBox(height: 16),
              _buildInputField('Öngörülen Toplam Gelir (₺)', _estimatedRevenueController, TextInputType.number, icon: Icons.attach_money),
              const SizedBox(height: 40),

              // Save Button
              ElevatedButton(
                onPressed: _updateProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF032B5E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0x33032B5E),
                ),
                child: const Text(
                  'Değişiklikleri Kaydet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, TextInputType type, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: type,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF94A3B8), size: 20) : null,
              hintText: '...',
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bu alan zorunludur';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
