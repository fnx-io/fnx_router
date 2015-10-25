// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library fnx_router.web.index;

import 'package:fnx_router/fnx_router.dart';
import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';

/// [MainApp] used!
main() async {

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.loggerName}: ${rec.message} (${rec.time})');
  });

  await initPolymer();
}
