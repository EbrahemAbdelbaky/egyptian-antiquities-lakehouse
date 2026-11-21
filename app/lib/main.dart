import 'package:flutter/material.dart';

import 'data/gold_data.dart';
import 'shell.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GoldExplorerApp());
}

class GoldExplorerApp extends StatelessWidget {
  const GoldExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gold Explorer',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _LoaderPage(),
    );
  }
}

/// Reads the two JSON files once, then shows the app.
class _LoaderPage extends StatefulWidget {
  const _LoaderPage();

  @override
  State<_LoaderPage> createState() => _LoaderPageState();
}

class _LoaderPageState extends State<_LoaderPage> {
  late final Future<GoldData> _future = GoldData.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GoldData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'The Gold data could not be loaded.\n\n${snapshot.error}',
                  style: AppText.body,
                ),
              ),
            ),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return AppShell(data: data);
      },
    );
  }
}
