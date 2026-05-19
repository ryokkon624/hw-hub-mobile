import '../../data/housework_settings_repository.dart';

const _pageSize = 10;

/// 家事設定一覧画面の状態。
class HouseworkListState {
  const HouseworkListState({
    this.allHouseworks = const [],
    this.members = const [],
    this.selectedCategory,
    this.currentPage = 1,
    this.errorMessage,
  });

  /// 全家事一覧（APIから取得した生データ）
  final List<HouseworkDto> allHouseworks;

  /// 世帯メンバー一覧（デフォルト担当者名解決用）
  final List<HouseholdMemberDto> members;

  /// カテゴリフィルタ（null=すべて）
  final String? selectedCategory;

  /// 現在のページ番号（1始まり）
  final int currentPage;

  /// エラーメッセージ
  final String? errorMessage;

  /// カテゴリフィルタを適用した家事一覧
  List<HouseworkDto> get filteredHouseworks {
    if (selectedCategory == null) return allHouseworks;
    return allHouseworks.where((h) => h.category == selectedCategory).toList();
  }

  /// 現在ページの家事一覧（ページネーション適用済み）
  List<HouseworkDto> get pagedHouseworks {
    final filtered = filteredHouseworks;
    final start = (currentPage - 1) * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  /// 総ページ数
  int get totalPages {
    final count = filteredHouseworks.length;
    if (count == 0) return 1;
    return ((count - 1) ~/ _pageSize) + 1;
  }

  /// メンバーIDから表示名を返す。
  String? memberNameById(int? userId) {
    if (userId == null) return null;
    final member = members.where((m) => m.userId == userId).firstOrNull;
    return member?.nickname ?? member?.displayName;
  }

  HouseworkListState copyWith({
    List<HouseworkDto>? allHouseworks,
    List<HouseholdMemberDto>? members,
    String? selectedCategory,
    bool clearCategory = false,
    int? currentPage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HouseworkListState(
      allHouseworks: allHouseworks ?? this.allHouseworks,
      members: members ?? this.members,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      currentPage: currentPage ?? this.currentPage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
