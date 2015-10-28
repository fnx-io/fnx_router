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
/// Just remember to style invisible elements in CSS.
///
/// 	  <style>
///         *[route-invisible] {
///             display: none;
///         }
///     </style>
///
/// ... and you are good to go.
///
@PolymerRegister("fnx-router")
class FnxRouter extends PolymerElement with FnxRouterBehavior {

  FnxRouter.created() : super.created();

  /// Callback for routing changes.
  ///
  /// It doesn't do anything in this element.
  void routeChanged(bool visible, List<String> params, bool visibilityChanged) {
  }

}