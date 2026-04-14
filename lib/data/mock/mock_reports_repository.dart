import '../../domain/models/report_summary.dart';
import '../../domain/repositories/reports_repository.dart';
import 'mock_seed_data.dart';

class MockReportsRepository implements ReportsRepository {
  @override
  Future<List<ReportSummary>> getSummaries() async {
    return MockSeedData.summaries();
  }
}
