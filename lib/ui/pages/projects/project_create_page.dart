
import 'package:flutter/material.dart';
import 'package:dev_studio/core/config/dependencies.dart';
import 'package:dev_studio/ui/pages/projects/viewmodel/project_create_viewmodel.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';

class ProjectCreatePage extends StatefulWidget {
  const ProjectCreatePage({
    super.key,
    this.viewModel,
  });

  final ProjectCreateViewModel? viewModel;

  @override
  State<ProjectCreatePage> createState() => _ProjectCreatePageState();
}

class _ProjectCreatePageState extends State<ProjectCreatePage> {
  static const _accent = Color(0xFF6B5CE7);
  static const _background = Color(0xFFF8F9FA);
  static const _border = Color(0xFFE5E5EA);
  
  final _formKey = GlobalKey<FormState>();
  final _appNameController = TextEditingController();
  final _packageController = TextEditingController();
  
  late final ProjectCreateViewModel _viewModel;
  
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? Dependencies.projectCreateViewModel();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _packageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_loading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    final result = await _viewModel.createProject(
      name: _appNameController.text.trim(),
      packageName: _packageController.text.trim(),
    );
    
    if (!mounted) return;
    setState(() => _loading = false);
    
    if (result.project != null) {
      Navigator.pop(context, result.project);
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!.message)),
      );
    }
  }

  String? _validateAppName(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return 'Enter the application name';
    if (value.length > 50) return 'Use no more than 50 characters';
    if (RegExp(r'[&"<>\']').hasMatch(value)) {
      return 'Do not use &, quotes, <, or >';
    }
    return null;
  }

  String? _validatePackage(String? rawValue) {
    final value = rawValue ?? '';
    if (value.length > 50) return 'Use no more than 50 characters';
    final segments = value.split('.');
    if (segments.length < 2 ||
        segments.any(
          (segment) => !RegExp(r'^[A-Za-z][A-Za-z0-9_]*$').hasMatch(segment),
        )) {
      return 'Enter a valid package, such as com.my.application';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildToolbar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
        bottomNavigationBar: _loading
            ? null
            : _buildBottomActions(),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 62,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _loading ? null : () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          const Text(
            'New Project',
            style: TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : () => Navigator.maybePop(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFFF0EDFF),
                    foregroundColor: const Color(0xFF34323C),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  key: const Key('save-project'),
                  onPressed: _loading ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 26, 16, 32),
        children: [
          _buildIconPicker(),
          const SizedBox(height: 34),
          _field(
            key: const Key('application-name'),
            controller: _appNameController,
            label: 'Application name',
            hintText: 'Enter application name',
            icon: Icons.smartphone_outlined,
            validator: _validateAppName,
            maxLength: 50,
          ),
          _field(
            key: const Key('package-name'),
            controller: _packageController,
            label: 'Package name',
            icon: Icons.inventory_2_outlined,
            validator: _validatePackage,
            maxLength: 50,
            textCapitalization: TextCapitalization.none,
          ),
        ],
      ),
    );
  }

  Widget _buildIconPicker() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Icon(Icons.apps, color: _accent, size: 40),
          ),
          const SizedBox(height: 8),
          const Text(
            'App Icon',
            style: TextStyle(fontSize: 12, color: _accent),
          ),
        ],
      ),
    );
  }

  Widget _field({
    Key? key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    String? Function(String?)? validator,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: key,
        controller: controller,
        validator: validator,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          counterText: '',
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}
