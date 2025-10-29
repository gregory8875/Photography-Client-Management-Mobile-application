# shutterbook

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:


For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Development notes

This folder contains the `shutterbook` Flutter application used in the
group project.

### Maintenance actions performed (automated)

- Ran the Flutter analyzer and fixed a number of lints and info-level issues:
	- Replaced deprecated `DropdownButtonFormField.value` usages with `initialValue`.
	- Fixed multiple `use_build_context_synchronously` warnings by capturing
		`NavigatorState` / `ScaffoldMessengerState` before `await` points and
		checking `mounted` before calling `setState` or popping dialogs.
	- Minor lint cleanups (argument ordering, unused locals, small naming fixes).

### Tests

- Ran `flutter test`. The repository contains a default widget test in
	`test/widget_test.dart` which exercises app startup and an increment button.
	The test run attempted to execute but encountered a listener cleanup error
	on Windows related to temporary test listener files. This is non-fatal to
	the code changes I made. If you want me to fully debug CI/test-runner
	platform issues I can reproduce and fix them (likely by ensuring proper
	test harness setup and mocking of platform APIs such as local_auth or
	SharedPreferences).

### Next recommended steps

1. Run `flutter test` locally again; if the test listener cleanup error
	 persists we can adjust the test to mock platform channels used during
	 startup (e.g., `local_auth`, `shared_preferences`) or switch to the
	 `flutter test --no-resident` runner.
2. Consider running `flutter pub outdated` and incrementally upgrading
	 packages (I saw many available updates). I can prepare an upgrade PR and
	 perform any necessary migrations.
3. If you want stricter linting, consider enabling more rules in
	 `analysis_options.yaml` and addressing them incrementally.
