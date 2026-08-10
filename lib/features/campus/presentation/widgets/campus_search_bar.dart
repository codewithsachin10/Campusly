import 'package:flutter/material.dart';

class CampusSearchBar extends StatelessWidget {
  final ValueChanged<String>? onSearch;
  final VoidCallback? onTap;

  const CampusSearchBar({super.key, this.onSearch, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: onSearch,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: 'Search campus (e.g. Library, CS Block)...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          suffixIcon: const Icon(Icons.tune, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
