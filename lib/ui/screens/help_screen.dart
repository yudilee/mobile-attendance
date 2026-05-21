import 'dart:math';

import 'package:flutter/material.dart';
import '../../services/app_docs.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DocSection? _selectedSection;
  DocArticle? _selectedArticle;

  List<DocSection> get _filteredSections {
    if (_searchQuery.isEmpty) return AppDocs.allSections;

    return AppDocs.allSections.where((section) {
      if (section.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return true;
      }
      for (final article in section.articles) {
        if (article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            article.content.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_selectedArticle != null) {
      return _buildArticleView(theme);
    }

    if (_selectedSection != null) {
      return _buildSectionView(theme);
    }

    return _buildMainHelpView(theme);
  }

  Widget _buildMainHelpView(ThemeData theme) {
    final sections = _filteredSections;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Documentation'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search documentation...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Sections grid
          Expanded(
            child: sections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          'No results found for "$_searchQuery"',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return _SectionCard(
                        section: section,
                        onTap: () => setState(() => _selectedSection = section),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionView(ThemeData theme) {
    final section = _selectedSection!;

    return Scaffold(
      appBar: AppBar(
        title: Text(section.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() {
            _selectedSection = null;
            _selectedArticle = null;
          }),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(section.icon,
                    size: 40, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    section.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Articles list
          ...section.articles.map((article) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(Icons.article,
                        color: theme.colorScheme.onSecondaryContainer),
                  ),
                  title: Text(article.title),
                  subtitle: Text(
                    '${article.content.substring(0, min(100, article.content.length)).replaceAll('\n', ' ')}...',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      setState(() => _selectedArticle = article),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildArticleView(ThemeData theme) {
    final article = _selectedArticle!;

    return Scaffold(
      appBar: AppBar(
        title: Text(article.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedArticle = null),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article title
            Text(
              article.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Steps list (if available)
            if (article.steps != null && article.steps!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.checklist,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Steps',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...article.steps!.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Article content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child:
                  _buildFormattedContent(article.content, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedContent(
      String content, ThemeData theme) {
    // Simple markdown-like rendering
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('#')) {
        // Header
        int level = 0;
        while (level < line.length && line[level] == '#') {
          level++;
        }
        final text = line.substring(level).trim();
        final size = level == 1 ? 20.0 : level == 2 ? 16.0 : 14.0;
        widgets.add(Padding(
          padding: EdgeInsets.only(top: level <= 2 ? 16 : 8, bottom: 8),
          child: Text(
            text,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
      } else if (line.startsWith('•') || line.startsWith('-')) {
        // Bullet point
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ',
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              Expanded(child: Text(line.substring(1).trim())),
            ],
          ),
        ));
      } else if (line.startsWith('Step') && line.contains(':')) {
        // Step heading (bold)
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            line,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (line.startsWith('  ')) {
        // Indented text
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text(line.trim(),
              style:
                  TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(line),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final DocSection section;
  final VoidCallback onTap;

  const _SectionCard({required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  section.icon,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                section.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${section.articles.length} article${section.articles.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
