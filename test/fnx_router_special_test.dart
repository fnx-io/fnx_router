@TestOn('browser')
import 'package:test/test.dart';

import 'dart:html';
import 'package:test/test.dart';
import 'package:polymer/polymer.dart';
import 'package:fnx_router/fnx_router.dart';
import 'package:logging/logging.dart';
import 'package:fnx_router/fnx_router_behavior.dart';

main() async {

  FnxRouterNavigator navigator = new _FnxRouterTestNavigator();
  configureRouterNavigator(navigator);

  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.loggerName}: ${rec.message} (${rec.time})');
  });

  await initPolymer();

  FnxRouter rA;
  FnxRouter rB;
  FnxRouter rA1a;
  FnxRouter dummy;

  group("Init test variables", () {
    test("Elements exist", () {
      rA = getNotNullElement("A");
      rB = getNotNullElement("B");
      rA1a = getNotNullElement("A.1.a");
      dummy = getNotNullElement("dummy");
    });
  });

  group("Start state: /1", () {
    test("Visible roots", () {
      print (rA);
      expect(rA.visible, equals(true));
      expect(rB.visible, equals(false));
      expect(rA1a.visible, equals(false));
      expect(dummy.visible, equals(true));
    });
  });

  group("Routing events", () {

    test("Route to '#/'", () {
      dummy.dataset["router"]="#/";
      dummy.fire("tap");

      expect(rA.visible, equals(true), reason: "rA");
      expect(rB.visible, equals(false), reason: "rB");
      expect(rA1a.visible, equals(false), reason: "rA1a");
      expect(dummy.visible, equals(true), reason: "dummy");
    });

    test("Route to '#/another-root'", () {
      dummy.dataset["router"]="#/another-root";
      dummy.fire("tap");

      expect(rA.visible, equals(true), reason: "rA");
      expect(rB.visible, equals(true), reason: "rB");
      expect(rA1a.visible, equals(false), reason: "rA1a");
      expect(dummy.visible, equals(true), reason: "dummy");
    });

  });

}

HtmlElement getNotNullElement(String id) {
  HtmlElement e = document.getElementById(id);
  expect(e, isNotNull, reason:"Element $id is null");
  return e;
}

class _FnxRouterTestNavigator extends FnxRouterNavigator {

  String virtualHash = "";

  String getWindowLocationHash() {
    return virtualHash;
  }

  void setWindowLocationHash(String hash) {
    virtualHash = "#"+hash;
  }

}
