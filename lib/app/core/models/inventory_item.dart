class InventoryItem {
  final String title;
  final String date;
  final String status;
  final int records;
  final int totalItems;

  InventoryItem({
    required this.title,
    required this.date,
    required this.status,
    required this.records,
    required this.totalItems,
  });
}

class InventoryCountItem {
  final String unitizerCode; // CX-220, PAL-001
  final String itemCode;     // 7891003
  final String itemName;     // Mouse Óptico USB
  final String time;         // 08:54
  final int totalCount;      // 52, 20
  final int stacks;          // 5, 4
  final int itemsPerStack;   // 10, 5
  final int loose;           // 2, 0

  InventoryCountItem({
    required this.unitizerCode,
    required this.itemCode,
    required this.itemName,
    required this.time,
    required this.totalCount,
    required this.stacks,
    required this.itemsPerStack,
    required this.loose,
  });
}