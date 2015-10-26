@HtmlImport("fnx_router.html")
library fnx_router.lib.fnx_router;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart';
import 'package:fnx_router/fnx_router_behavior.dart';

@PolymerRegister("fnx-router")
class FnxRouter extends PolymerElement with FnxRouterBehavior {

  final int MAX_RETRY = 10;

  FnxRouter.created() : super.created();

  void routeChanged(bool visible, List<String> params) {
    if (visible) {
      toggleAttribute("router-visible", true);
    } else {
      toggleAttribute("router-visible", false);
    }
    if (parent != null && parent.tagName != null) {
      if (
            (parent.tagName.toUpperCase() == "IRON-PAGES") && visible
      ) {
        _displayInParentIronPages();
      }
    }
    if (children != null && children.length == 1) {
      if (children[0].tagName.toUpperCase() == "PAPER-DIALOG") {
        _openPaperDialog();
      }
    }
  }

  int _paper_dialog_retry = 0;

  void _openPaperDialog() {
    try {
      if (routerVisible) {
        children[0].open();
      } else {
        children[0].close();
      }
    } catch (exception) {
      // wasn't able to call methods on iron-pages
      _paper_dialog_retry++;
      if (_paper_dialog_retry < MAX_RETRY) {
        debounce("fnx-router-paper-dialog-$fullRoute", _openPaperDialog, waitTime:200);
      } else {
        throw "Failed to call methods on paper-dialog element for $MAX_RETRY times, giving up, sorry";
      }
    }
  }

  int _iron_pages_retry = 0;

  void _displayInParentIronPages() {
    try {
      parent.select(parent.indexOf(this).toString());
    } catch (exception) {
      // wasn't able to call methods on iron-pages
      print(exception);
      _iron_pages_retry++;
      if (_iron_pages_retry < MAX_RETRY) {
        debounce("fnx-router-iron-pages-$fullParentRoute", _displayInParentIronPages, waitTime:200);
      } else {
        throw "Failed to call methods on iron-pages element for $MAX_RETRY times, giving up, sorry";
      }
    }
  }

}
