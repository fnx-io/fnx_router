@HtmlImport("fnx_router.html")
/// Simple element with [FnxRouterBehavior].
///
library fnx_router.element;

import 'dart:html';

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart';
import 'package:fnx_router/fnx_router_behavior.dart';

/// Use this element as simple div with extra 'route' attribute:
///
///     <fnx-router>
///
///         <fnx-router route="amazing">
///             <fnx-router route="stuff">
///                  <h1>wow!</h1>
///             </fnx-router>
///             <fnx-router route="features">
///                 <h1>no way!</h1>
///             </fnx-router>
///             ...
///
/// Remember to style invisible elements in CSS like this:
///
/// 	  <style>
///         fnx-router:not([router-visible]) {
///             display: none;
///         }
///     </style>
///
/// Or any way you like.
@PolymerRegister("fnx-router")
class FnxRouter extends PolymerElement with FnxRouterBehavior {

  FnxRouter.created() : super.created();

  /// Callback for routing changes.
  ///
  /// Toggles 'router-visible' attribute on this element.
  /// Use it to style invisible elements.
  void routeChanged(bool visible, List<String> params) {
    if (visible) {
      toggleAttribute("router-visible", true);
    } else {
      toggleAttribute("router-visible", false);
    }
  }

}