part of fnx_router.behavior;

/// [FnxRouterNavigator] is responsible for listening on location.hash changes
/// and distributing changes to the routing tree.
///
/// You don't need to care about this class too much, all you need is accessible
/// through methods of your [FnxRouterBehavior] Polymer element.
class FnxRouterNavigator {

  String _currentRoute = "";

  FnxRouterNavigator() {
    document.onLoad.first.then((_) => _processHashChange());
    window.onHashChange.listen((_) => _processHashChange());
    _processHashChange();
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