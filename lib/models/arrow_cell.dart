import 'arrow_direction.dart';

class ArrowCell {
  ArrowCell({required this.row, required this.col, Set<ArrowDirection>? arrows})
    : arrows = arrows ?? <ArrowDirection>{};

  final int row;
  final int col;
  final Set<ArrowDirection> arrows;

  bool has(ArrowDirection direction) => arrows.contains(direction);

  bool get isDeadEnd => arrows.length <= 1;
}
