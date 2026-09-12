// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

bool printCurrentPage() {
  html.window.print();
  return true;
}
