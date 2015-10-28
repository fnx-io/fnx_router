part of fnx_router.behavior;

/// Your [FnxRouterBehavior] elements will have this attribute when visible. Use it to style your elements in CSS.
const String ATTR_ROUTE_VISIBLE = "route-visible";

/// Your [FnxRouterBehavior] elements will have this attribute when visible. Use it to style your elements in CSS.
const String ATTR_ROUTE_INVISIBLE = "route-invisible";


/// Routing behavior for Polymer elements.
///
/// Use this to enable routing on your elements.
@behavior
abstract class FnxRouterBehavior {

  /// Relative route provided from mark-up
  @property
  String route = null;

  /// Current state of element.
  ///
  /// Please don't change it. Just read it.
  @property
  bool routeVisible = null;

  /// This element's route calculated from the parent [FnxRouterBehavior].
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
  /// At this point the element is registered for initialization. The actual initialization occurs 200ms after last registered element.
  void attached() {
    _log.info("Router node ${(this as HtmlElement).tagName} attached to document");

    // hide everything for now, just to be sure
    (this as PolymerElement).toggleAttribute(ATTR_ROUTE_VISIBLE, false);
    (this as PolymerElement).toggleAttribute(ATTR_ROUTE_INVISIBLE, true);
    _allRoutingNodesToInitialize.add(this);

    (this as PolymerElement).debounce("fnx-router-init", _initializeAllRoutingNodes, waitTime: 200);
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
  /// It will be invoked each time when:
  /// * your element is invisible and should become visible
  /// * your element is visible and should become invisible
  /// * your element is visible, should stay visible, but params changed (see [routerParams])
  /// * your element is visible, should stay visible, but route changed
  ///
  /// Use argument `visibilityChanged` to decide whether your visibility actually changed,
  /// or you are just being notified about some other change.
  ///
  ///     if (visible && visibilityChanged) {
  ///       doSomeExpensiveLoadingStuff();
  ///     }
  ///     if (!visible && visibilityChanged) {
  ///       cancelAllTasks();
  ///     }
  ///
  void routeChanged(bool visible, List<String> params, bool visibilityChanged);

  /// Programmatically change current location (route) so that the `element` in argument becomes visible.
  /// Calling this method will change `window.location.href` accordingly.
  ///
  /// Element in argument can be any HtmlElement, but it must be nested under [FnxRouterBehavior] element.
  void navigateToElement(Element element, [List<String> params = null]) {
    FnxRouterBehavior _router = _findParentRouter(element);
    if (_router == null) {
      throw "Cannot navigate to $element, it has no FnxRouterBehavior parent";
    }
    navigateAbsolute(_router.absoluteRoute, params);
  }

  /// Programmatically change current location (route)
  /// so that the specified sibling of this element is visible.
  /// Calling this method will change `window.location.href` accordingly.
  ///
  ///     navigateToSibling("my-brother");
  void navigateToSibling(String route, [List<String> params = null]) {
    navigateAbsolute(absoluteParentRoute + "/" + route, params);
  }

  /// Programmatically change current location (route)
  /// so that the specified child element of this element is visible.
  /// Calling this method will change `window.location.href` accordingly.
  ///
  ///
  ///     navigateToSibling("my-child");
  void navigateToChild(String route, [List<String> params = null]) {
    navigateAbsolute(absoluteRoute + "/" + route, params);
  }

  /// Programmatically change current location (route) to any
  /// absolute path.
  /// Calling this method will change `window.location.href` accordingly.
  ///
  ///     navigateAbsolute("/amazing/stuff/somewhere/deep");
  void navigateAbsolute(String absoluteRoute, [List<String> params = null]) {
    _navigatorRef._navigateTo(absoluteRoute, params);
  }

  void _initRouting() {
    PolymerElement a;

    if (_initialized) return;
    _initialized = true;
    _parentRouter = _findParentRouter((this as Element).parent);
    if (route != null && route.startsWith("/")) {
      throw "Routes cannot start with '/' ($route)";
    }
    if (route != null && route.endsWith("/")) {
      throw "Routes cannot end with '/' ($route)";
    }
    if (route != null && route.contains(";")) {
      throw "Routes cannot contain ';' symbol ($route)";
    }

    _buildAbsoluteRoutes();
    _registerForRouting();
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

  void _registerForRouting() {
    _allRoutingNodes.add(this);
  }

  void _resolveVisibility(String routeWithParams, [List<String> params]) {
    _log.fine("'$absoluteRoute' is resolving it's visibility for '$routeWithParams' route");
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

    bool _visibilityChanged = routeVisible != newVisible;

    if (_visibilityChanged || _paramsChanged ) {
      // visibility changed

      if (_visibilityChanged) {
        _log.info("'$absoluteRoute' visibility changed: visible=$newVisible, params=$routerParams (element $this)");
      } else {
        _log.info("'$absoluteRoute' params changed: visible=$newVisible, params=$routerParams (element $this)");
      }

      routeVisible = newVisible;

      if (_visibilityChanged) {
        if (routeVisible) {
          (this as PolymerElement).toggleAttribute(ATTR_ROUTE_VISIBLE, true);
          (this as PolymerElement).toggleAttribute(ATTR_ROUTE_INVISIBLE, false);
        } else {
          (this as PolymerElement).toggleAttribute(ATTR_ROUTE_VISIBLE, false);
          (this as PolymerElement).toggleAttribute(ATTR_ROUTE_INVISIBLE, true);
        }
      }

      _log.fine("'$absoluteRoute' is calling routeChanged callback");
      routeChanged(routeVisible, routerParams, _visibilityChanged);

      _log.fine("'$absoluteRoute' is firing 'route-visibility' event");
      (this as PolymerElement).fire("route-visibility", detail: routeVisible);

    }
  }

}