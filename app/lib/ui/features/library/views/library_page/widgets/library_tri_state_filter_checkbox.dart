import 'package:flutter/material.dart';
import 'package:hentai_library/domain/library/library_tri_state_pick.dart';

class LibraryTriStateFilterCheckbox extends StatelessWidget {
  const LibraryTriStateFilterCheckbox({
    super.key,
    required this.state,
    required this.onPressed,
  });

  final LibraryTriStatePick state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Checkbox(
        value: state.checkboxValue,
        tristate: true,
        onChanged: (_) => onPressed(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
