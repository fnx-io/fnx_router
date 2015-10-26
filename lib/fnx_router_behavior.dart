library fnx_router.lib.fnx_router_behavior;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';

List<FnxRouterBehavior> _allRoutingNodes = [];
FnxRouterNavigator _navigator = new FnxRouterNavigator();

void configureRouterNavigator(FnxRouterNavigator navigator) {
  _navigator = navigator;
}

final int CU_SEMI = ";".codeUnitAt(0);
final int CU_SLASH = "/".codeUnitAt(0);

@behavior
abstract class FnxRouterBehavior {

  Logger _log = new Logger("FnxRouterBehavior");

  @property
  String route = null;

  @property
  bool routerVisible = false;

  @property
  String absoluteRoute = null;

  @property
  String absoluteParentRoute = null;

  List<String> routerParams = [];

  FnxRouterNavigator navigator = _navigator;

  String _lastMatchedRoute = null;

  FnxRouterBehavior _parentRouter = null;

  bool _initialized = false;

  void ready() {
    _initRouting();
  }

  void _initRouting() {
    if (_initialized) return;
    _initialized = true;
    _log.info("Router node attached to document");
    _parentRouter = findParentRouter((this as Element).parent);
    if (route != null && route.startsWith("/")) {
      throw "Routes cannot start with '/' ($route)";
    }
    if (route != null && route.endsWith("/")) {
      throw "Routes cannot end with '/' ($route)";
    }

    _buildAbsoluteRoutes();
    _registerRoutingNode();
    _resolveVisibility(navigator.currentRoute);

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
        navigateToSiblink(route, params);

      } else if (route.startsWith("./")) {
        route = route.substring(2);
        navigateToChild(route, params);

      } else {
        throw "Your data-router must start with '#/' or '../' or './'";
      }
    }
  }

  FnxRouterBehavior findParentRouter(Element element) {
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
    return findParentRouter(parent);
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
          if (code == CU_SEMI || code == CU_SLASH) {
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

  void routeChanged(bool visible, List<String> params);

  void navigateToElement(Element element, [List<String> params = null]) {
    FnxRouterBehavior _router = findParentRouter(element);
    if (_router == null) {
      throw "Cannot navigate to $element, it has no FnxRouterBehavior parent";
    }
    navigateAbsolute(_router.absoluteRoute, params);
  }

  void navigateToSiblink(String route, [List<String> params = null]) {
    navigateAbsolute(absoluteParentRoute + "/" + route, params);
  }

  void navigateToChild(String route, [List<String> params = null]) {
    navigateAbsolute(absoluteRoute + "/" + route, params);
  }

  void navigateAbsolute(String absoluteRoute, [List<String> params = null]) {
    navigator.navigateTo(absoluteRoute, params);
  }

}

class FnxRouterNavigator {

  Logger _log = new Logger("FnxRouterNavigator");

  String currentRoute = "";

  FnxRouterNavigator() {
    _processHashChange();
    document.onLoad.first.then((_) => _processHashChange());
    window.onHashChange.listen((_) => _processHashChange());
  }

  _processHashChange() {
    String hash = getWindowLocationHash();
    _log.info("Processing hash=${hash}");
    if (hash == null || hash.isEmpty) {
      if (currentRoute != "") {
        currentRoute = "";
        _resolveVisibilities(hash);
      }
      return;
    }
    hash = hash.substring(1); // begins with #
    if (hash.length == 0) {
      if (currentRoute != "") {
        currentRoute = "";
        _resolveVisibilities(hash);
      }
      return;
    }
    // hash = Uri.decodeComponent(hash);
    List<String> params = parseRouteParams(hash);

    if (hash == currentRoute) {
      // no change
      return;
    }
    currentRoute = hash;
    _resolveVisibilities(hash, params);
  }

  void navigateTo(String route, [List<String> params]) {
    _log.info("Navigating to '$route' with params $params");
    currentRoute = renderRouteWithParams(route, params);
    setWindowLocationHash(currentRoute);
    _resolveVisibilities(currentRoute, params);
  }

  void _resolveVisibilities(String routeWithParams, [List<String> params]) {
    _log.info("Resolving visibilities for '${routeWithParams}', with params=$params, ${_allRoutingNodes.length} known routing nodes");
    _allRoutingNodes.forEach((FnxRouterBehavior child) => child._resolveVisibility(routeWithParams, params));
  }

  List<String> parseRouteParams(String hash) {
    List<String> params = hash.split(";");
    if (params.length > 1) {
      params = params.sublist(1);
    } else {
      params = [];
    }
    return params;
  }

  String renderRouteWithParams(String route, List<String> params) {
    if (params != null && params.isNotEmpty) {
      return route+";"+params.join(";");
    } else {
      return route;
    }
  }

  String getWindowLocationHash() {
    return window.location.hash;
  }

  void setWindowLocationHash(String hash) {
    window.location.hash = hash;
  }

}