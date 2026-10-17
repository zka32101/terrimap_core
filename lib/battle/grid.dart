/// 盤面のマス。列(col)・行(row)。
class GridPos implements Comparable<GridPos> {
  final int col, row;
  const GridPos(this.col, this.row);

  @override
  bool operator ==(Object o) => o is GridPos && o.col == col && o.row == row;
  @override
  int get hashCode => col * 1009 + row;
  @override
  int compareTo(GridPos o) => row != o.row ? row.compareTo(o.row) : col.compareTo(o.col);
  @override
  String toString() => '($col,$row)';

  int manhattan(GridPos o) => (col - o.col).abs() + (row - o.row).abs();
  Map<String, int> toJson() => {'col': col, 'row': row};
}

enum Season { spring, summer, autumn, winter }

/// ステージの種別。通常=州ごと／regional=地方決戦／extra=エクストラ（設計書 §6.9。M7で作る）
enum StageKind { normal, regional, extra }
