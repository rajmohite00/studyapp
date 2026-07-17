import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Light-only theme provider — dark mode removed.
final themeModeProvider = Provider<ThemeMode>((_) => ThemeMode.light);
