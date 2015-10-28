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

  FnxRouter rA1;
  FnxRouter rA1a;
  FnxRouter rA2;
  FnxRouter rB1;
  FnxRouter rB1a;

  group("Init test variables", () {
    test("Elements exist", () {
      rA = getNotNullElement("A");
      rB = getNotNullElement("B");
      rA1 = getNotNullElement("A.1");
      rA1a = getNotNullElement("A.1.a");
      rA2 = getNotNullElement("A.2");
      rB1 = getNotNullElement("B.1");
      rB1a = getNotNullElement("B.1.a");
    });
  });

  group("Start state: /1", () {
    test("Visible roots", () {
      print (rA);
      expect(rA.routeVisible, equals(true));
      expect(rB.routeVisible, equals(true));
      expect(rA1.routeVisible, equals(true));
      expect(rA1a.routeVisible, equals(false));
      expect(rA2.routeVisible, equals(false));
      expect(rB1.routeVisible, equals(true));
      expect(rB1a.routeVisible, equals(false));
    });
  });

  group("Routing events", () {

    test("Route to '#/'", () {
      rB1a.dataset["router"]="#/";
      rB1a.fire("tap");

      expect(rA.routeVisible, equals(true), reason: "rA");
      expect(rB.routeVisible, equals(true), reason: "rB");
      expect(rA1.routeVisible, equals(false), reason: "rA1");
      expect(rA1a.routeVisible, equals(false), reason: "rA1a");
      expect(rA2.routeVisible, equals(false), reason: "rA2");
      expect(rB1.routeVisible, equals(false), reason: "rB1");
      expect(rB1a.routeVisible, equals(false), reason: "rB1a");

      expect(navigator.getWindowLocationHash(), "#/");
    });

    test("Route to '#/1'", () {
      rB1a.dataset["router"]="#/1";
      rB1a.fire("tap");

      expect(rA.routeVisible, equals(true), reason: "rA");
      expect(rB.routeVisible, equals(true), reason: "rB");
      expect(rA1.routeVisible, equals(true), reason: "rA1");
      expect(rA1a.routeVisible, equals(false), reason: "rA1a");
      expect(rA2.routeVisible, equals(false), reason: "rA2");
      expect(rB1.routeVisible, equals(true), reason: "rB1");
      expect(rB1a.routeVisible, equals(false), reason: "rB1a");
    });

    test("Route to '#/2'", () {
      rB1a.dataset["router"]="#/2";
      rB1a.fire("tap");

      expect(rA.routeVisible, equals(true), reason: "rA");
      expect(rB.routeVisible, equals(true), reason: "rB");
      expect(rA1.routeVisible, equals(false), reason: "rA1");
      expect(rA1a.routeVisible, equals(false), reason: "rA1a");
      expect(rA2.routeVisible, equals(true), reason: "rA2");
      expect(rB1.routeVisible, equals(false), reason: "rB1");
      expect(rB1a.routeVisible, equals(false), reason: "rB1a");

      expect(rA.routerParams.isEmpty, equals(true), reason: "rA params");
      expect(rB.routerParams.isEmpty, equals(true), reason: "rB params");
      expect(rA1.routerParams.isEmpty, equals(true), reason: "rA1 params");
      expect(rA2.routerParams.isEmpty, equals(true), reason: "rA2 params");
    });

    test("Route to '#/1/a'", () {
      rB1a.dataset["router"]="#/1/a";
      rB1a.fire("tap");

      expect(rA.routeVisible, equals(true), reason: "rA");
      expect(rB.routeVisible, equals(true), reason: "rB");
      expect(rA1.routeVisible, equals(true), reason: "rA1");
      expect(rA1a.routeVisible, equals(true), reason: "rA1a");
      expect(rA2.routeVisible, equals(false), reason: "rA2");
      expect(rB1.routeVisible, equals(true), reason: "rB1");
      expect(rB1a.routeVisible, equals(true), reason: "rB1a");

      expect(rA.routerParams.isEmpty, equals(true), reason: "rA params");
      expect(rB.routerParams.isEmpty, equals(true), reason: "rB params");
      expect(rA1.routerParams.isEmpty, equals(true), reason: "rA1 params");
      expect(rA2.routerParams.isEmpty, equals(true), reason: "rA2 params");

    });

    test("Route to '#/2  with params'", () {
      rB1a.dataset["router"]="#/2";
      rB1a.dataset["routerParam1"]="1234567890";
      rB1a.dataset["routerParam2"]="qwertyuiop";
      rB1a.dataset["routerParam4"]="will be ignored";
      rB1a.fire("tap");

      expect(rA.routeVisible, equals(true), reason: "rA");
      expect(rB.routeVisible, equals(true), reason: "rB");
      expect(rA1.routeVisible, equals(false), reason: "rA1");
      expect(rA1a.routeVisible, equals(false), reason: "rA1a");
      expect(rA2.routeVisible, equals(true), reason: "rA2");
      expect(rB1.routeVisible, equals(false), reason: "rB1");
      expect(rB1a.routeVisible, equals(false), reason: "rB1a");

      expect(rA.routerParams.isEmpty, equals(false), reason: "rA params");
      expect(rB.routerParams.isEmpty, equals(false), reason: "rB params");
      expect(rA1.routerParams.isEmpty, equals(true), reason: "rA1 params");
      expect(rA2.routerParams.isEmpty, equals(false), reason: "rA2 params");

      expect(rA.routerParams.length, equals(2));
      expect(rA2.routerParams.length, equals(2));

      expect(rA.routerParams[0], equals("1234567890"));
      expect(rA2.routerParams[1], equals("qwertyuiop"));

    });

    test("Route to '#/2  with params - second run'", () {
      rB1a.dataset["router"]="#/2";
      rB1a.dataset["routerArg1"]="1234567890";
      rB1a.dataset["routerArg2"]="qwertyuiop";
      rB1a.dataset["routerArg4"]="will be ignored";
      rB1a.fire("tap");

      expect(rA.routeVisible, equals(true), reason: "rA");
      expect(rB.routeVisible, equals(true), reason: "rB");
      expect(rA1.routeVisible, equals(false), reason: "rA1");
      expect(rA1a.routeVisible, equals(false), reason: "rA1a");
      expect(rA2.routeVisible, equals(true), reason: "rA2");
      expect(rB1.routeVisible, equals(false), reason: "rB1");
      expect(rB1a.routeVisible, equals(false), reason: "rB1a");

      expect(rA.routerParams.isEmpty, equals(false), reason: "rA params");
      expect(rB.routerParams.isEmpty, equals(false), reason: "rB params");
      expect(rA1.routerParams.isEmpty, equals(true), reason: "rA1 params");
      expect(rA2.routerParams.isEmpty, equals(false), reason: "rA2 params");

      expect(rA.routerParams.length, equals(2));
      expect(rA2.routerParams.length, equals(2));

      expect(rA.routerParams[0], equals("1234567890"));
      expect(rA2.routerParams[1], equals("qwertyuiop"));

    });

    test("Route to from button in A.1.c to '../a' ( = '#/1/a')", () {
      ButtonElement b = getNotNullElement("A.1.c-button");
      b.dataset["router"]="../a";
      b.click();

      expect(rA.routeVisible, equals(true), reason: "rA");
      expect(rB.routeVisible, equals(true), reason: "rB");
      expect(rA1.routeVisible, equals(true), reason: "rA1");
      expect(rA1a.routeVisible, equals(true), reason: "rA1a");
      expect(rA2.routeVisible, equals(false), reason: "rA2");
      expect(rB1.routeVisible, equals(true), reason: "rB1");
      expect(rB1a.routeVisible, equals(true), reason: "rB1a");

      expect(rA.routerParams.isEmpty, equals(true), reason: "rA params");
      expect(rB.routerParams.isEmpty, equals(true), reason: "rB params");
      expect(rA1.routerParams.isEmpty, equals(true), reason: "rA1 params");
      expect(rA2.routerParams.isEmpty, equals(true), reason: "rA2 params");

    });

  });

}

HtmlElement getNotNullElement(String id) {
  HtmlElement e = document.getElementById(id);
  expect(e, isNotNull, reason:"Element $id is null");
  return e;
}

class _FnxRouterTestNavigator extends FnxRouterNavigator {

  String virtualHash = "#/1";

  String getWindowLocationHash() {
    return virtualHash;
  }

  void setWindowLocationHash(String hash) {
    virtualHash = "#"+hash;
  }

}
