@HtmlImport("fnx_router.html")
library fnx_router.lib.fnx_router;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart';
import 'package:fnx_router/fnx_router_behavior.dart';

@PolymerRegister("fnx-router")
class FnxRouter extends PolymerElement with FnxRouterBehavior {

  FnxRouter.created() : super.created();

  void routeChanged(bool visible, List<String> params) {
    if (visible) {
      toggleAttribute("router-visible", true);
    } else {
      toggleAttribute("router-visible", false);
    }
  }

}