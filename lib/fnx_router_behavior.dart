/// Routing behavior for Polymer elements.
///
/// Structure your application and react to `window.location.hash` changes.
///
///
///     <fnx-router>
///
///         <a href="#/amazing/stuff">show me amazing stuff</a>
///         <a href="#/amazing/features">show me amazing features</a>
///
///         <your-amazing-element route="amazing">
///             <fnx-router route="stuff">
///                  <h1>wow!</h1>
///             </fnx-router>
///             <fnx-router route="features">
///                 <h1>no way!</h1>
///             </fnx-router>
///             ...
///
/// [FnxRouterBehavior] from this library allows you to enable routing
/// in any Polymer element.
library fnx_router.behavior;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';

part "fnx_router_behavior_impl.dart";
part "fnx_router_behavior_navigator.dart";

List<FnxRouterBehavior> _allRoutingNodes = [];
List<FnxRouterBehavior> _allRoutingNodesToInitialize = [];
FnxRouterNavigator _navigatorSingleton = new FnxRouterNavigator();
Logger _log = new Logger("FnxRouterBehavior");

/// Add this attribute to the document body to prevent FUOC.
///
/// After successful initialization fnx router will remove this attribute.
/// Use it in CSS to prevent FUOC.
///
///     <style>
///         body[router-not-initialized] {
///           display: none;
///         }
///     </style>
///
const String BODY_ATTR_ROUTER_NOT_INITIALIZED = "router-not-initialized";

/// Router will add this attribute to the document body after successful initialization.
const String BODY_ATTR_ROUTER_INITIALIZED = "router-initialized";

/// Finds the first ancestor element with [FnxRouterBehavior].
///
/// Initializes parent router element if hasn't been initialized yet.
FnxRouterBehavior _findParentRouter(Element element) {
  if (element is FnxRouterBehavior) {
    FnxRouterBehavior p = element as FnxRouterBehavior;
    if (!p._initialized) {
      p._initRouting();
    }
    return p;
  }
  if (element is BodyElement) return null;
  Element parent = element.parent;
  if (parent == null) return null;
  return _findParentRouter(parent);
}

void _initializeAllRoutingNodes() {
  _log.info("Polymer has been calm for a while, let's start router initialization");
  _allRoutingNodesToInitialize.forEach((FnxRouterBehavior rb) => rb._initRouting());
  _allRoutingNodesToInitialize.clear();
  BodyElement body = window.document.querySelector("body");
  body.attributes.remove(BODY_ATTR_ROUTER_NOT_INITIALIZED);
  body.attributes[BODY_ATTR_ROUTER_INITIALIZED] = BODY_ATTR_ROUTER_INITIALIZED;
  _log.info("Router initialization finished");
}

/// For unit testing only.
void testConfigureRouterNavigator(FnxRouterNavigator navigator) {
  _navigatorSingleton = navigator;
}

final int _CU_SEMI = ";".codeUnitAt(0);
final int _CU_SLASH = "/".codeUnitAt(0);