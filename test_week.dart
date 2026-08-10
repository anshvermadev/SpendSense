void main() {
  DateTime _getStartOfWeek(DateTime date) {
    int diff = date.weekday % 7;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: diff));
  }

  // The transaction date
  DateTime txnDate = DateTime.parse("2026-07-19 12:30:00");
  
  // Suppose today is July 21, 2026
  DateTime today = DateTime.parse("2026-07-21 14:00:00");
  
  DateTime selectedWeekStart = _getStartOfWeek(today);
  DateTime weekEnd = selectedWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  
  print("txnDate: $txnDate");
  print("today: $today");
  print("selectedWeekStart: $selectedWeekStart");
  print("weekEnd: $weekEnd");
  
  bool isAfter = txnDate.isAfter(selectedWeekStart.subtract(const Duration(seconds: 1)));
  bool isBefore = txnDate.isBefore(weekEnd);
  
  print("isAfter: $isAfter");
  print("isBefore: $isBefore");
  print("Included? ${isAfter && isBefore}");
}
