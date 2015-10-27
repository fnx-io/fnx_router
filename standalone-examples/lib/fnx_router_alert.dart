@HtmlImport("fnx_router_alert.html")
/// Simple element with [FnxRouterBehavior].
///
library fnx_router.fnx_router_alert;

import 'dart:html';

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart';
import 'package:fnx_router/fnx_router_behavior.dart';

@PolymerRegister("fnx-router-alert")
class FnxRouterAlert extends PolymerElement with FnxRouterBehavior {

  @property
  String message;

  FnxRouterAlert.created() : super.created();

  void routeChanged(bool visible, List<String> params) {
    if (visible) {
      async(() {
        // window.alert blocks rendering, so we should do it "async"
        window.alert(message);
        navigateAbsolute("#/");
      });
    }
  }

}