library fnx_router.lib.fnx_router_behavior;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';

List<FnxRouterBehavior> _allRootRouters = [];
FnxRouterNavigator _navigator = new FnxRouterNavigator();

void configureRouterNavigator(FnxRouterNavigator navigator) {
  _navigator = navigator;
}


@behavior
abstract class FnxRouterBehavior {

  Logger _log = new Logger("FnxRouterBehavior");

  @property
  String route = null;

  @property
  bool visible = false;

  FnxRouterNavigator navigator = _navigator;

  FnxRouterBehavior _parentRouter = null;
  FnxRouterBehavior _rootRouter = null;

  @property
  String fullRoute = null;

  @property
  List<String> routerParams = [];

  @property
  String fullParentRoute = null;

  String _lastMatchedRoute = null;

  Map<String, FnxRouterBehavior> _children = null;

  /*
  @Property(computed: 'computeHasEvent(event)')
  bool hasEvent = false;

  @reflectable
  bool computeHasEvent(String e) {
    return e != null;
  }
  */

  void attached() {
    _log.info("Router node attached to document");
    _parentRouter = findParentRouter((this as Element).parent);
    if (route == null && _parentRouter != null) {
        throw "$this route is null, only root router is allowed to have empty route";
    }
    if (route != null && route.startsWith("/")) {
      throw "Routes cannot start with '/' ($route)";
    }
    if (route != null && route.endsWith("/")) {
      throw "Routes cannot end with '/' ($route)";
    }

    _buildFullRoutes();
    _registerToRootRouter();
    _resolveVisibility(navigator.currentRoute);
  }

  void _buildFullRoutes() {
    if (_parentRouter == null) {
      _log.info("New root router: $this");
      // I'm root
      fullParentRoute = "";
      fullRoute = "";
    } else {
      fullParentRoute = _parentRouter.fullRoute;
      fullRoute = fullParentRoute + "/" + route;
    }
    _log.info("Registered route '${fullRoute}'");
  }

  void _registerToRootRouter() {
    if (_parentRouter == null) {
      _rootRouter = this;
      _allRootRouters.add(this);
      _children = {};

    } else {
      _rootRouter = _parentRouter._rootRouter;
      if (_rootRouter._children[fullRoute] != null) {
        throw "There is already registered router node with route $fullRoute";
      } else {
        _rootRouter._children[fullRoute] = this;
      }
    }
  }

  @Listen("tap")
  void catchRouteChangeEvents(Event e, detail) {
    if (!(e.target is Element)) return;
    Map<String, String> dataset = (e.target as Element).dataset;
    String route = dataset["router"];
    if (route != null) {
      _log.info("'$fullRoute' detected routing event: data-router=$route, stopping event propagation");
      e.stopPropagation();
      e.preventDefault();

      List<String> params = [];
      int a=1;
      String param = null;

      if (dataset["routerArg0"] != null) {
        throw "You have an element with data-router-arg0, but first argument should be data-router-arg1";
      }

      while ((param = dataset["routerArg$a"]) != null ) {
        a++;
        _log.fine("'$fullRoute' adding route argument $a=$param");
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
    if (element is FnxRouterBehavior) return element as FnxRouterBehavior;
    if (element is BodyElement) return null;
    if (element is HtmlElement) return null;
    Element parent = element.parent;
    if (parent == null) return null;
    return findParentRouter(parent);
  }

  void _resolveVisibility(String routeWithParams, [List<String> params]) {
    _log.fine("'$fullRoute' resolving it's visibility for '$routeWithParams' route");
    bool newVisible = null;
    if (routeWithParams == null) {
      newVisible = false;
    } else {
      if (routeWithParams.startsWith(fullRoute)) {
        newVisible = true;

      } else {
        newVisible = false;
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

    if (visible != newVisible || _paramsChanged ) {
      // visibility changed
      _log.info("'$fullRoute' visibility or params changed: visible=$newVisible, params=$routerParams (element $this)");
      visible = newVisible;
      routeChanged(visible, routerParams);
      _log.fine("'$fullRoute' is firing 'router-visibility' event");
      (this as PolymerElement).fire("router-visibility", detail: visible);
    }
  }

  void routeChanged(bool visible, List<String> params);

  void navigateToElement(Element element, [List<String> params = null]) {
    FnxRouterBehavior _router = findParentRouter(element);
    if (_router == null) {
      throw "Cannot navigate to $element, it has no FnxRouterBehavior parent";
    }
    navigateAbsolute(_router.fullRoute, params);
  }

  void navigateToSiblink(String route, [List<String> params = null]) {
    navigateAbsolute(fullParentRoute + "/" + route, params);
  }

  void navigateToChild(String route, [List<String> params = null]) {
    navigateAbsolute(fullRoute + "/" + route, params);
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
    _log.info("Resolving visibilities for '${routeWithParams}', with params=$params");
    _allRootRouters.forEach((FnxRouterBehavior root) {
      _log.fine("Resolving visibility of root $root");
      root._resolveVisibility(routeWithParams, params);
      _log.fine("Resolving visibility of ${root._children.length} children");
      root._children.values.forEach((FnxRouterBehavior child) => child._resolveVisibility(routeWithParams, params));
    });
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