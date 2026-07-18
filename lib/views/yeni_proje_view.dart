import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hane/models/project.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/services/api_service.dart';
import 'package:hane/views/widgets/map_location_picker.dart';

class YeniProjeView extends StatefulWidget {
  final Project? project; // If provided, we are in Edit Mode

  const YeniProjeView({super.key, this.project});

  @override
  State<YeniProjeView> createState() => _YeniProjeViewState();
}

class _YeniProjeViewState extends State<YeniProjeView> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  String? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile.path;
      });
    }
  }

  void _deleteProject(BuildContext context) {
    if (widget.project?.id == null) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Projeyi Sil'),
        content: const Text('Bu projeyi silmek istediğinize emin misiniz? Tüm proje verileri silinecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: context.colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final fp = Provider.of<FinanceProvider>(context, listen: false);
                await fp.deleteProject(widget.project!.id!);
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Proje silindi.'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.danger),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Controllers for Step 1
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _locationController = TextEditingController();
  final _paftaController = TextEditingController();
  final _parselController = TextEditingController();
  final _areaController = TextEditingController();
  final _totalSectionsController = TextEditingController();
  final _unitCountController = TextEditingController();
  final _shopCountController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _projectType = 'Konut';

  // Controllers for Step 2
  final _estimatedCostController = TextEditingController();
  final _estimatedRevenueController = TextEditingController();
  String _selectedStatus = 'Planlama Aşaması';

  final List<Map<String, String>> _statusOptions = [
    {'status': 'Planlama Aşaması', 'color': 'F59E0B', 'bg': 'FFF7ED'},
    {'status': 'İhale Aşaması', 'color': '3B82F6', 'bg': 'EFF6FF'},
    {'status': 'Devam Ediyor', 'color': '10B981', 'bg': 'ECFDF5'},
    {'status': 'Tamamlandı', 'color': '64748B', 'bg': 'F8FAFC'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      final p = widget.project!;
      _nameController.text = p.name;
      _codeController.text = p.projectCode;
      _locationController.text = p.location;
      _paftaController.text = p.pafta;
      _parselController.text = p.parsel;
      _areaController.text = p.areaSqMeters > 0 ? p.areaSqMeters.toString() : '';
      _totalSectionsController.text = p.totalIndependentSections > 0 ? p.totalIndependentSections.toString() : '';
      _unitCountController.text = p.unitCount > 0 ? p.unitCount.toString() : '';
      _shopCountController.text = p.shopCount > 0 ? p.shopCount.toString() : '';
      _startDateController.text = p.startDate;
      _endDateController.text = p.endDate;
      _descriptionController.text = p.description;
      _projectType = p.projectType.isEmpty ? 'Konut' : p.projectType;

      _estimatedCostController.text = p.estimatedTotalCost > 0 ? p.estimatedTotalCost.toString() : '';
      _estimatedRevenueController.text = p.estimatedTotalRevenue > 0 ? p.estimatedTotalRevenue.toString() : '';
      
      // Ensure status exists in options
      if (_statusOptions.any((opt) => opt['status'] == p.status)) {
        _selectedStatus = p.status;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _locationController.dispose();
    _paftaController.dispose();
    _parselController.dispose();
    _areaController.dispose();
    _totalSectionsController.dispose();
    _unitCountController.dispose();
    _shopCountController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    _estimatedCostController.dispose();
    _estimatedRevenueController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.colors.brand,
              onPrimary: Colors.white,
              onSurface: context.colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}";
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 1) {
      setState(() => _currentStep++);
    } else {
      _saveProject();
    }
  }

  void _saveProject() async {
    final selectedStatusData = _statusOptions.firstWhere((element) => element['status'] == _selectedStatus);
    
    final project = Project(
      id: widget.project?.id,
      name: _nameController.text.trim(),
      projectCode: _codeController.text.trim(),
      projectType: _projectType,
      status: _selectedStatus,
      statusColorHex: selectedStatusData['color']!,
      statusBgColorHex: selectedStatusData['bg']!,
      location: _locationController.text.trim(),
      pafta: _paftaController.text.trim(),
      parsel: _parselController.text.trim(),
      areaSqMeters: int.tryParse(_areaController.text) ?? 0,
      totalIndependentSections: int.tryParse(_totalSectionsController.text) ?? 0,
      unitCount: int.tryParse(_unitCountController.text) ?? 0,
      shopCount: int.tryParse(_shopCountController.text) ?? 0,
      estimatedTotalCost: double.tryParse(_estimatedCostController.text) ?? 0.0,
      estimatedTotalRevenue: double.tryParse(_estimatedRevenueController.text) ?? 0.0,
      startDate: _startDateController.text,
      endDate: _endDateController.text,
      description: _descriptionController.text.trim(),
      imagePath: widget.project?.imagePath,
    );

    final fp = Provider.of<FinanceProvider>(context, listen: false);
    
    try {
      if (widget.project != null) {
        await fp.updateProject(project);
        if (_imageFile != null) {
          await fp.uploadProjectImage(widget.project!.id!, _imageFile!);
        }
      } else {
        final createdProject = await fp.createProject(project);
        if (_imageFile != null && createdProject.id != null) {
          await fp.uploadProjectImage(createdProject.id!, _imageFile!);
        }
      }
      if (mounted) {
        Navigator.pop(context, true); // Return true indicating success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.project != null ? 'Proje güncellendi!' : 'Proje eklendi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    }
  }

  Widget _buildStepIcon(int step, String title, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? context.colors.brand : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? context.colors.brand : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? context.colors.brand : Colors.grey[500],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? context.colors.brand : Colors.grey[200],
        margin: const EdgeInsets.only(bottom: 24),
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepIcon(1, 'Bilgiler', _currentStep >= 0),
          _buildStepLine(_currentStep >= 1),
          _buildStepIcon(2, 'Detaylar', _currentStep >= 1),
          _buildStepLine(_currentStep >= 2),
          _buildStepIcon(3, 'Özet', _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String type, IconData icon) {
    final isSelected = _projectType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _projectType = type),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? context.colors.brand.withValues(alpha: 0.05) : context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? context.colors.brand : context.colors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? context.colors.brand : Colors.grey[500], size: 28),
              const SizedBox(height: 8),
              Text(
                type,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? context.colors.brand : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Proje Görseli Ekleme
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border, style: BorderStyle.solid),
                image: _imageFile != null
                    ? DecorationImage(image: FileImage(File(_imageFile!)), fit: BoxFit.cover)
                    : (widget.project?.imagePath != null
                        ? DecorationImage(
                            image: NetworkImage(widget.project!.imagePath!.startsWith('/media') ? '${ApiService.baseUrl.replaceAll(RegExp(r'/api/?$'), '')}${widget.project!.imagePath}' : widget.project!.imagePath!),
                            fit: BoxFit.cover)
                        : null),
              ),
              child: _imageFile == null && widget.project?.imagePath == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 48, color: context.colors.border.withOpacity(0.8)),
                        const SizedBox(height: 8),
                        Text('Proje Görseli Ekle', style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: context.colors.surface,
                          child: Icon(Icons.edit, size: 16, color: context.colors.textPrimary),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          Text('Temel Bilgiler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
          const SizedBox(height: 16),
          
          _buildInputField('Proje Adı', 'Proje adını giriniz', _nameController, icon: Icons.business, isRequired: true),
          const SizedBox(height: 16),
          
          _buildInputField('Proje Kodu', 'Proje kodunu giriniz (örn. AKP-001)', _codeController, icon: Icons.local_offer_outlined),
          const SizedBox(height: 16),
          
          Text('Proje Tipi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeCard('Konut', Icons.home_work_outlined),
              _buildTypeCard('İşyeri', Icons.storefront_outlined),
              _buildTypeCard('Ofis', Icons.domain),
              _buildTypeCard('Diğer', Icons.more_horiz),
            ],
          ),
          const SizedBox(height: 16),

          Text('Konum', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextFieldOnly('İl / İlçe seçiniz', _locationController, icon: Icons.location_on_outlined),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => const MapLocationPicker()),
                  );
                  if (result != null && result.isNotEmpty) {
                    setState(() => _locationController.text = result);
                  }
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Icon(Icons.gps_fixed, color: Colors.grey[600]),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildInputField('Pafta', 'Pafta no', _paftaController)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField('Parsel', 'Parsel no', _parselController)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField('Alan (m²)', 'Alan m²', _areaController, type: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildInputField('Toplam Bağımsız Bölüm', 'Örn. 48', _totalSectionsController, type: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField('Konut Sayısı', 'Örn. 40', _unitCountController, type: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField('İşyeri Sayısı', 'Örn. 8', _shopCountController, type: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildDateField('Başlangıç Tarihi', _startDateController)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateField('Tahmini Bitiş Tarihi', _endDateController)),
            ],
          ),
          const SizedBox(height: 16),

          Text('Açıklama (Opsiyonel)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.border),
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              style: TextStyle(fontSize: 14, color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Proje hakkında not ekleyebilirsiniz...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                counterText: '', // Using default counter looks fine, or custom
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Finansal ve Durum Detayları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
        const SizedBox(height: 16),
        _buildInputField('Öngörülen Toplam Maliyet (₺)', '0.0', _estimatedCostController, type: TextInputType.number, icon: Icons.money_off),
        const SizedBox(height: 16),
        _buildInputField('Öngörülen Toplam Gelir (₺)', '0.0', _estimatedRevenueController, type: TextInputType.number, icon: Icons.attach_money),
        const SizedBox(height: 16),
        Text('Durum', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textSecondary),
              items: _statusOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['status'],
                  child: Text(
                    option['status']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
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
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Özet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Proje Adı', _nameController.text),
              const Divider(),
              _buildSummaryRow('Tipi', _projectType),
              const Divider(),
              _buildSummaryRow('Lokasyon', _locationController.text),
              const Divider(),
              _buildSummaryRow('Durum', _selectedStatus),
              const Divider(),
              _buildSummaryRow('Öngörülen Maliyet', '₺${_estimatedCostController.text}'),
              const Divider(),
              _buildSummaryRow('Öngörülen Gelir', '₺${_estimatedRevenueController.text}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          Text(value.isEmpty ? '-' : value, style: TextStyle(fontSize: 14, color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'Seçiniz' : controller.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: controller.text.isEmpty ? Colors.grey[400] : context.colors.textPrimary,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller, {IconData? icon, TextInputType type = TextInputType.text, bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        _buildTextFieldOnly(hint, controller, icon: icon, type: type, isRequired: isRequired),
      ],
    );
  }

  Widget _buildTextFieldOnly(String hint, TextEditingController controller, {IconData? icon, TextInputType type = TextInputType.text, bool isRequired = false}) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        style: TextStyle(fontSize: 14, color: context.colors.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[500], size: 20) : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        validator: isRequired ? (value) => (value == null || value.isEmpty) ? 'Zorunlu alan' : null : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        title: Text(
          widget.project != null ? 'Projeyi Düzenle' : 'Projeyi Tasarla',
          style: TextStyle(color: context.colors.brand, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.brand),
        centerTitle: true,
        actions: [
          if (widget.project != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: context.colors.danger),
              tooltip: 'Projeyi Sil',
              onPressed: () => _deleteProject(context),
            ),
          if (_currentStep == 2)
             TextButton(
               onPressed: _saveProject,
               child: Text('Kaydet', style: TextStyle(color: context.colors.brand, fontWeight: FontWeight.bold, fontSize: 15)),
             )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: _currentStep == 0 ? _buildStep1() : _currentStep == 1 ? _buildStep2() : _buildStep3(),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.brand,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentStep == 2 ? (widget.project != null ? 'Güncelle' : 'Oluştur') : 'İleri',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              if (_currentStep < 2)
                const Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
