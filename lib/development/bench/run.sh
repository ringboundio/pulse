#!/usr/bin/env bash
set -euo pipefail
flutter run \
	--debug \
	--no-hot \
	--no-pub \
	--no-devtools \
	--no-dds \
	--no-publish-port \
	-d flutter-tester \
	lib/development/bench/main.dart