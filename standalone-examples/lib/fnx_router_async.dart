@HtmlImport("fnx_router_async.html")
library fnx_router.fnx_router_async;

import 'dart:html';

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart';
import 'package:fnx_router/fnx_router_behavior.dart';

@PolymerRegister("fnx-router-async")
class FnxRouterAsync extends PolymerElement with FnxRouterBehavior {

  static const DELAY = 1000;

  FnxRouterAsync.created() : super.created();

  void routeChanged(bool visible, List<String> params, bool visibilityChanged) {
    if (visible && visibilityChanged) {
      async(stage1, waitTime: DELAY);

    } else if (!visible) {
      classes.remove("loaded");
      $$("#log").children.clear();
    }
  }

  void write(String s) {
    ParagraphElement p = new ParagraphElement();
    p.setInnerHtml(s);
    $$("#log").append(p);
  }

  void stage1() {
    if (!routeVisible) return;
    write("So you want me to load some REST data ...");
    async(stage2, waitTime: DELAY);
  }

  void stage2() {
    if (!routeVisible) return;
    write("Loading ...");
    async(stage3, waitTime: DELAY);
  }

  void stage3() {
    if (!routeVisible) return;
    write("Still loading ...");
    async(stage4, waitTime: DELAY);
  }

  void stage4() {
    if (!routeVisible) return;
    write("Here it comes!");
    classes.add("loaded");
  }

}

