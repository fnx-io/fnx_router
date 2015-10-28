library fnx_router.examples;

import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';

import 'package:fnx_router/fnx_router.dart';
import 'package:standalone_examples/fnx_router_alert.dart';
import 'package:standalone_examples/fnx_router_async.dart';

main() async {

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.loggerName}: ${rec.message} (${rec.time})');
  });

  await initPolymer();

}