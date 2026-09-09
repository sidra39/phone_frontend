import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/app_logo.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_provider.dart';
import '../models/browse_part_model.dart';
import '../services/browse_service.dart';
import 'part_detail_screen.dart';

/// Public marketplace screen for browsing available phone parts.
class BrowseHomeScreen extends StatefulWidget {
  const BrowseHomeScreen({super.key});

  @override
  State<BrowseHomeScreen> createState() => _BrowseHomeScreenState();
}

class _BrowseHomeScreenState extends State<BrowseHomeScreen> {
  final BrowseService _browseService = BrowseService();
  final _modelController = TextEditingController();
  final _cityController = TextEditingController();
  List<BrowsePartModel> _parts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final parts = await _browseService.searchParts(
        model: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
      );
      if (mounted) setState(() => _parts = parts);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(iconSize: 32, fontSize: 18),
        actions: [
          if (auth.token == null)
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Login'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _performSearch,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _modelController,
                      decoration: const InputDecoration(labelText: 'Model'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                  ),
                  IconButton(
                    onPressed: _performSearch,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _parts.isEmpty
                  ? const Center(
                      child: Text('No parts matching your browse criteria'),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: .72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _parts.length,
                      itemBuilder: (context, index) {
                        final part = _parts[index];
                        final imageUrl =
                            part.imageUrl == null || part.imageUrl!.isEmpty
                            ? null
                            : '${ApiConstants.baseUrl}${part.imageUrl}';
                        return InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PartDetailScreen(partId: part.id),
                            ),
                          ),
                          child: Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: imageUrl == null
                                      ? const Center(
                                          child: Icon(
                                            Icons.image_search_rounded,
                                            size: 36,
                                          ),
                                        )
                                      : Image.network(
                                          imageUrl,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    part.modelName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
