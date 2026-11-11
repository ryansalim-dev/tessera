import 'package:flutter/material.dart';

import 'app.dart';
import 'progress/progress_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final progress = await ProgressStore.open();
  runApp(TesseraApp(progress: progress));
}
