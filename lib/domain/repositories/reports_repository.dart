import '../models/report_summary.dart';

abstract class ReportsRepository {
  Future<List<ReportSummary>> getSummaries();
}
