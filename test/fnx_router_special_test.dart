@TestOn('browser')
import 'package:test/test.dart';

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:fnx_router/fnx_router.dart';
import 'package:logging/logging.dart';
import 'package:fnx_router/fnx_router_behavior.dart';

main() async {

  FnxRouterNavigator navigator = new _FnxRouterTestNavigator();
  testConfigureRouterNavigator(navigator);

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
      expect(rA.routeVisible, equals(true), reason:"rA");
      expect(rB.routeVisible, equals(false), reason:"rB");
      expect(rA1a.routeVisible, equals(false), reason:"rA1");
      expect(dummy.routeVisible, equals(false), reason:"dummy");
    });
  });

  group("Routing events", () {

    test("Route to '#/'", () {
      dummy.dataset["router"]="#/";
      dummy.fire("tap");

      expect(rA.routeVisible, equals(true), reason: "rA");
      expect(rB.routeVisible, equals(false), reason: "rB");
      expect(rA1a.routeVisible, equals(false), reason: "rA1a");
      expect(dummy.routeVisible, equals(false), reason: "dummy");
    });

    test("Route to '#/another-root'", () {
      dummy.dataset["router"]="#/another-root";
      dummy.fire("tap");

      expect(rA.routeVisible, equals(true), reason: "rA");
      expect(rB.routeVisible, equals(true), reason: "rB");
      expect(rA1a.routeVisible, equals(false), reason: "rA1a");
      expect(dummy.routeVisible, equals(false), reason: "dummy");
    });

    test("Route to '#/1'", () {
      dummy.dataset["router"]="#/1";
      dummy.fire("tap");

      expect(rA.routeVisible, equals(true), reason: "rA");
      expect(rB.routeVisible, equals(false), reason: "rB");
      expect(rA1a.routeVisible, equals(false), reason: "rA1a");
      expect(dummy.routeVisible, equals(true), reason: "dummy");
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