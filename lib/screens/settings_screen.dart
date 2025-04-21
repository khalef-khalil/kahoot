import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Provider.of<ThemeProvider>(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            title: 'Appearance',
            children: [
              _buildThemeSelector(context),
            ],
          ),
          const Divider(),
          _buildSection(
            context, 
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Developer'),
                subtitle: const Text('Kahoot Clone Project'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Provider.of<ThemeProvider>(context).primaryColor,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return ExpansionTile(
      leading: const Icon(Icons.color_lens),
      title: const Text('App Theme'),
      subtitle: Text(themeProvider.currentThemeName),
      children: [
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: themeProvider.themes.length,
            itemBuilder: (context, index) {
              final theme = themeProvider.themes[index];
              final isSelected = themeProvider.currentThemeIndex == index;
              
              return GestureDetector(
                onTap: () {
                  themeProvider.setTheme(index);
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected 
                        ? Border.all(color: Colors.white, width: 2) 
                        : null,
                    boxShadow: isSelected 
                        ? [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ] 
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      theme.name.split(' ')[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
} 