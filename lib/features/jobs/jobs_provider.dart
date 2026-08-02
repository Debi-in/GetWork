// ============================================================
// JOBS PROVIDER — GetWork App
// Riverpod 3.x Notifier state management for filtering, searching & applying
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwork/core/services/dummy_data_service.dart';
import 'package:getwork/models/job_model.dart';

// ── Selected Category Notifier ──────────────────────────────
class SelectedCategoryNotifier extends Notifier<JobCategory> {
  @override
  JobCategory build() => JobCategory.all;

  void setCategory(JobCategory category) {
    state = category;
  }
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, JobCategory>(
  SelectedCategoryNotifier.new,
);

// ── Search Query Notifier ───────────────────────────────────
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// ── Selected Job on Map Notifier ────────────────────────────
class SelectedJobNotifier extends Notifier<JobModel?> {
  @override
  JobModel? build() => null;

  void selectJob(JobModel? job) {
    state = job;
  }
}

final selectedJobProvider = NotifierProvider<SelectedJobNotifier, JobModel?>(
  SelectedJobNotifier.new,
);

// ── Applied Jobs List Notifier ──────────────────────────────
class AppliedJobsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void applyToJob(String jobId) {
    state = {...state, jobId};
  }

  bool isApplied(String jobId) {
    return state.contains(jobId);
  }
}

final appliedJobsProvider =
    NotifierProvider<AppliedJobsNotifier, Set<String>>(
  AppliedJobsNotifier.new,
);

// ── All Jobs List Notifier ──────────────────────────────────
class JobsListNotifier extends Notifier<List<JobModel>> {
  @override
  List<JobModel> build() => DummyDataService.getDummyJobs();

  void addJob(JobModel job) {
    state = [job, ...state];
  }

  void incrementAppliedCount(String jobId) {
    state = [
      for (final job in state)
        if (job.id == jobId)
          job.copyWith(workersApplied: job.workersApplied + 1)
        else
          job,
    ];
  }
}

final allJobsProvider = NotifierProvider<JobsListNotifier, List<JobModel>>(
  JobsListNotifier.new,
);

// ── Filtered Jobs Provider ──────────────────────────────────
final filteredJobsProvider = Provider<List<JobModel>>((ref) {
  final jobs = ref.watch(allJobsProvider);
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  return jobs.where((job) {
    final matchesCategory =
        category == JobCategory.all || job.category == category;

    final matchesQuery = query.isEmpty ||
        job.title.toLowerCase().contains(query) ||
        job.businessName.toLowerCase().contains(query) ||
        job.address.toLowerCase().contains(query);

    return matchesCategory && matchesQuery;
  }).toList();
});
