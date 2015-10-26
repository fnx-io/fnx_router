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

List<FnxRouterBehavior> _allRoutingNodes = [];
FnxRouterNavigator _navigatorSingleton = new FnxRouterNavigator();

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
  if (element is HtmlElement) return null;
  Element parent = element.parent;
  if (parent == null) return null;
  return _findParentRouter(parent);
}


/// For unit testing only.
void testConfigureRouterNavigator(FnxRouterNavigator navigator) {
  _navigatorSingleton = navigator;
}

final int _CU_SEMI = ";".codeUnitAt(0);
final int _CU_SLASH = "/".codeUnitAt(0);

/// Routing behavior for Polymer elements.
///
/// Use this to enable routing on your elements.
@behavior
abstract class FnxRouterBehavior {

  Logger _log = new Logger("FnxRouterBehavior");

  /// Relative route provided from mark-up
  @property
  String route = null;

  /// Current state of element
  @property
  bool routerVisible = false;

  /// This element's route calculated from parent
  @property
  String absoluteRoute = null;

  /// Absolute route of parent
  @property
  String absoluteParentRoute = null;

  /// Current router parameters
  @property
  List<String> routerParams = [];

  FnxRouterNavigator _navigatorRef = _navigatorSingleton;

  String _lastMatchedRoute = null;

  FnxRouterBehavior _parentRouter = null;

  bool _initialized = false;

  /// Polymer lifecycle callback.
  ///
  /// At this point the element is initialized, absolute routes are resolved etc.
  void attached() {
    _initRouting();
  }

  /// Listening for user interaction.
  ///
  /// Every router element is listening for 'tap' events on any html elements with data-router="..." attributes.
  @Listen("tap")
  void catchRouteChangeEvents(Event e, detail) {
    if (!(e.target is Element)) return;
    Map<String, String> dataset = (e.target as Element).dataset;
    String route = dataset["router"];
    if (route != null) {
      _log.info("'$absoluteRoute' detected routing event: data-router=$route, stopping event propagation");
      e.stopPropagation();
      e.preventDefault();

      List<String> params = [];
      int a=1;
      String param = null;

      if (dataset["routerParam0"] != null) {
        throw "You have an element with data-router-param0, but first parameter should be data-router-param1";
      }

      while ((param = dataset["routerParam$a"]) != null ) {
        a++;
        _log.fine("'$absoluteRoute' adding route parameter $a=$param");
        params.add(param);
      }

      if (route.startsWith("#/")) {
        route = route.substring(1);
        navigateAbsolute(route, params);

      } else if (route.startsWith("../")) {
        route = route.substring(3);
        navigateToSibling(route, params);

      } else if (route.startsWith("./")) {
        route = route.substring(2);
        navigateToChild(route, params);

      } else {
        throw "Your data-router must start with '#/' or '../' or './'";
      }
    }
  }

  /// Implement this callback in your element.
  ///
  /// will be invoked each time when:
  /// * your element is invisible and should become visible
  /// * your element is visible and should become invisible
  /// * your element is visible and should stay visible, but params changed (see _Routing parameters_ above)
  void routeChanged(bool visible, List<String> params);

  /// Programmatically change current location (route) so the 'element' in argument is visible.
  ///
  /// Element can be any HtmlElement, but it must be nested under FnxRouterBehavior element.
  void navigateToElement(Element element, [List<String> params = null]) {
    FnxRouterBehavior _router = _findParentRouter(element);
    if (_router == null) {
      throw "Cannot navigate to $element, it has no FnxRouterBehavior parent";
    }
    navigateAbsolute(_router.absoluteRoute, params);
  }

  /// Programmatically change current location (route)
  /// so that specified sibling of this element is visible.
  ///
  ///     navigateToSibling("my-brother");
  void navigateToSibling(String route, [List<String> params = null]) {
    navigateAbsolute(absoluteParentRoute + "/" + route, params);
  }

  /// Programmatically change current location (route)
  /// so that specified child element of this element is visible.
  ///
  ///     navigateToSibling("my-child");
  void navigateToChild(String route, [List<String> params = null]) {
    navigateAbsolute(absoluteRoute + "/" + route, params);
  }

  /// Programmatically change current location (route) to any
  /// absolute path.
  ///
  ///     navigateAbsolute("/amazing/stuff/somewhere/deep");
  void navigateAbsolute(String absoluteRoute, [List<String> params = null]) {
    _navigatorRef._navigateTo(absoluteRoute, params);
  }

  void _initRouting() {
    if (_initialized) return;
    _initialized = true;
    _log.info("Router node attached to document");
    _parentRouter = _findParentRouter((this as Element).parent);
    if (route != null && route.startsWith("/")) {
      throw "Routes cannot start with '/' ($route)";
    }
    if (route != null && route.endsWith("/")) {
      throw "Routes cannot end with '/' ($route)";
    }

    _buildAbsoluteRoutes();
    _registerRoutingNode();
    _resolveVisibility(_navigatorRef._currentRoute);

  }

  void _buildAbsoluteRoutes() {
    if (_parentRouter == null) {
      _log.info("New root router: $this");
      // I'm root
      absoluteParentRoute = "";
      if (route == null) {
        absoluteRoute = "";
      } else {
        absoluteRoute = "/$route";
      }
    } else {
      absoluteParentRoute = _parentRouter.absoluteRoute;
      if (route != null) {
        absoluteRoute = absoluteParentRoute + "/" + route;
      } else {
        absoluteRoute = absoluteParentRoute;
      }
    }
    _log.info("Registered route '${absoluteRoute}' for element $this");
  }

  void _registerRoutingNode() {
    _allRoutingNodes.add(this);
  }

  void _resolveVisibility(String routeWithParams, [List<String> params]) {
    _log.fine("'$absoluteRoute' resolving it's visibility for '$routeWithParams' route");
    bool newVisible = false;
    if (routeWithParams == null) {
      // not visible
    } else {
      if (routeWithParams.startsWith(absoluteRoute)) {
        // global route starts with our route, that's almost good, but:
        if (routeWithParams.length == absoluteRoute.length) {
          // that's good
          newVisible = true;
        } else {
          int code = routeWithParams.codeUnitAt(absoluteRoute.length);
          if (code == _CU_SEMI || code == _CU_SLASH) {
            // that's also good
            newVisible = true;
          } else {
            // it's not a match, it's something like:
            // '/route-qwertyu' doesn't match '/rou'
          }
        }

      } else {
        // not visible
      }
    }
    bool _paramsChanged = false;
    if (newVisible) {
      _log.fine("Checking lastMatchedRoute $_lastMatchedRoute vs. $routeWithParams");
      if (_lastMatchedRoute != routeWithParams) {
        _paramsChanged = true;
        _lastMatchedRoute = routeWithParams;
        routerParams = params;
      }
    } else {
      _lastMatchedRoute = null;
      routerParams = [];
    }

    if (routerVisible != newVisible || _paramsChanged ) {
      // visibility changed
      _log.info("'$absoluteRoute' visibility or params changed: visible=$newVisible, params=$routerParams (element $this)");
      routerVisible = newVisible;
      routeChanged(routerVisible, routerParams);
      _log.fine("'$absoluteRoute' is firing 'router-visibility' event");
      (this as PolymerElement).fire("router-visibility", detail: routerVisible);
    }
  }

}

/// [FnxRouterNavigator] is responsible for listening on location.hash changes
/// and distributing changes to routing tree.
///
/// You don't need to care about this class too much, all you need is accessible
/// through methods of your [FnxRouterBehavior] Polymer element.
class FnxRouterNavigator {

  Logger _log = new Logger("FnxRouterNavigator");

  String _currentRoute = "";

  FnxRouterNavigator() {
    _processHashChange();
    document.onLoad.first.then((_) => _processHashChange());
    window.onHashChange.listen((_) => _processHashChange());
  }

  _processHashChange() {
    String hash = getWindowLocationHash();
    _log.info("Processing hash=${hash}");
    if (hash == null || hash.isEmpty) {
      if (_currentRoute != "") {
        _currentRoute = "";
        _resolveVisibilities(hash);
      }
      return;
    }
    hash = hash.substring(1); // begins with #
    if (hash.length == 0) {
      if (_currentRoute != "") {
        _currentRoute = "";
        _resolveVisibilities(hash);
      }
      return;
    }
    // hash = Uri.decodeComponent(hash);
    List<String> params = _parseRouteParams(hash);

    if (hash == _currentRoute) {
      // no change
      return;
    }
    _currentRoute = hash;
    _resolveVisibilities(hash, params);
  }

  void _navigateTo(String route, [List<String> params]) {
    _log.info("Navigating to '$route' with params $params");
    _currentRoute = _renderRouteWithParams(route, params);
    setWindowLocationHash(_currentRoute);
    _resolveVisibilities(_currentRoute, params);
  }

  void _resolveVisibilities(String routeWithParams, [List<String> params]) {
    _log.info("Resolving visibilities for '${routeWithParams}', with params=$params, ${_allRoutingNodes.length} known routing nodes");
    _allRoutingNodes.forEach((FnxRouterBehavior child) => child._resolveVisibility(routeWithParams, params));
  }

  List<String> _parseRouteParams(String hash) {
    List<String> params = hash.split(";");
    if (params.length > 1) {
      params = params.sublist(1);
    } else {
      params = [];
    }
    return params;
  }

  String _renderRouteWithParams(String route, List<String> params) {
    if (params != null && params.isNotEmpty) {
      return route+";"+params.join(";");
    } else {
      return route;
    }
  }

  /// We need to override these methods during test.
  String getWindowLocationHash() {
    return window.location.hash;
  }

  /// We need to override these methods during test.
  void setWindowLocationHash(String hash) {
    window.location.hash = hash;
  }

}