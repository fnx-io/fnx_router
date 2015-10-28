# fnx_router

Declarative hierarchical router for Polymer Dart 1.0. Use it like this:

	<fnx-router>
		
		<a href="#/amazing/stuff">show me amazing stuff</a>
		<a href="#/amazing/features">show me amazing features</a>
	
		<fnx-router route="amazing">
		
			<fnx-router route="stuff">
				<h1>wow!</h1>
			</fnx-router>
			
			<fnx-router route="features">
				<h1>no way!</h1>
			</fnx-router>
			
			...

See [examples](http://demo.fnx.io/fnx_router-examples/).

Comes in with handy Polymer `@bahavior` which you can use to make **any of your elements** routing capable.

_Note: Work in progress, I'll continue to develop this package as I use it in our Polymer projects._

## Routing

The purpose of this package is to allow you to show/hide your elements depending on `window.location.hash`
value. Every element `with FnxRouterBehavior` has `route` attribute and becomes subject of routing.

	<fnx-router route='user'>
		<my-cool-element route='edit'>
			...

Elements create a tree hierarchy of _routing nodes_ (subtree of DOM, if you want).
Their absolute route depends on route of their parents (and recursively up to the root element).

	<fnx-router> <!-- this is a routing root and it has no
	                  "route" attribute , it will be visible always -->
	                  
		<fnx-router route="amazing"> <!-- visible on #/amazing -->
		
			<fnx-router route="stuff"> <!-- visible on #/amazing/stuff -->
			
				<fnx-router route="vol1"> <!-- visible on #/amazing/stuff/vol1 -->

Level separator `/` is a constant provided by *fnx_router*.

## Navigation

Your user can navigate through your app by simply changing location anchor:

	<a href="#/amazing/stuff">show me amazing stuff</a>
	<a href="#/amazing/features">show me amazing features</a>

However - this requires you to know the absolute path (absolute route) to the element,
which is not very practical - hierarchical routing then loses it's purpose.
There are several other ways how to navigate.

	<fnx-router>
		
		<a href="#" data-router="#/amazing">open amazing menu</a>
	
		<fnx-router route="amazing">
			
			<a href="#" data-router="./stuff">stuff</a>
			
			<a href="#" data-router="./features">features</a>
			
			<a href="#" data-router="../regular">hide amazing, show regular</a>
			
			<fnx-router route="stuff">
				<h1>WOW!</h1>
			</fnx-router>
			
			<fnx-router route="features">
				<h1>NO WAY!</h1>
			</fnx-router>
			
		</fnx-router>
		
		<fnx-router route="regular">
			This is pretty regular. Go see
			<a href="#" data-router="../amazing">something amazing</a>.			
		</fnx-router>

All routing nodes listen for `tap` event (`@Listen("tap")`). If the event's target contains `data-router`
attribute, tap event is canceled and processed by router (actual `href` or other default action is ignored).
Possible values of `data-router` are:

- `#/something` - absolute path to required element
- `./something` - relative path to this element's child
- `../something` - relative path to this element's siblink (only single `../` is supported for now, you cannot double-dot your path all the way up like `../../`)

Your `data-router` value must start with either `#/`, `./` or `../`.

	<a href="#" data-router="./baby-boy">pictures of my boy</a>	
	<a href="#" data-router="./baby-girl">pictures of my girl</a>	
	<a href="#" data-router="../my-dumb-brother">pictures of my brother</a>

You can also change the route programmatically, see [dartdoc](http://www.dartdocs.org/documentation/fnx_router/0.2.1/index.html).

## fnx-router element

**fnx_router** package contains `<fnx-router>` element. It's a
simple `display: block;` element which you can use instead of
your regular `<div>`.

Specify dependency in pubspec.yaml:

	dependencies:
	  fnx_router: ^0.2.1

Run `pub get`, import it in your html:

	<link rel="import" href="packages/fnx_router/fnx_router.html">
	
... and in your "index.dart" (or whatever is the name of your main script):
	
	import 'package:fnx_router/fnx_router.dart';

_Note: Importing this element in dart shouldn't be necessary, it seems like a Polymer bug to me. Or maybe I'm doing something wrong. I'm working on it._ 

## Styling

`FnxRouterBehavior` toggles two boolean attributes on your element during routing:

- `route-visible`
- `route-invisible`

Use those attributes to hide your elements however you want: 

	<style>
		fnx-router[route-invisible] {
			display: none;
		}
		.show-ghosts fnx-router[route-invisible] {
			opacity: 0.2;
		}	
	</style>

_Note: It's discouraged to remove elements from DOM tree, see
[polymer-dart wiki](https://github.com/dart-lang/polymer-dart/wiki/data-binding-helper-elements#conditional-templates), that's
one of the reasons we leave handling invisible elements up to you._

To prevent FUOC, add `router-not-initialized` to body element and style it:

	<style>
		body[router-not-initialized] {
			opacity: 0;
		}
	</style>

After successful initialization, *fnx_router* exchanges this attribute for `router-initialized`.

## Routing parameters

It would be nice to have routes like this: `/user/1234/edit`, but in current
state of Polymer it would be difficult to create such link. Polymer doesn't
(support expressions)[https://github.com/Polymer/polymer/issues/1847] at this moment, so you cannot write
`href="/user/{{user.id}}/edit"`.

Because of this, your routes should be "hardwired constants" and everything what changes,
should be provided via parameters.

	<a href="#/my/hardwired/route;3.1415;another-parameter">go for PI</a>

You still cannot render `href="#/my/hardwired/route;{{currentValueOfPI}};another-parameter"`, but you can use additional `data-router` attributes:

	<a href="#"
		data-router="#/my/hardwired/route"
		data-router-param1="{{currentValueOfPI}}"
		data-router-param2="another-parameter"
		>go for PI</a>

_Note: Routing parameters are simply a `List<String>` at this point._

## Using router in your elements

`fnx-router` element is really just a smarter div. You will probably need to fetch data from API
whenever your element becomes visible etc. Good news - thanks to [Polymer behaviors](https://github.com/dart-lang/polymer-dart/wiki/behaviors),
it's can be done really easy.

Enhance your element with `FnxRouterBehavior` like this:

In your template:
	
	<dom-module id="my-smart-rest-element" attributes="route"><!-- new attribute -->

In your class:

	class MySmartRestElement extends PolymerElement with FnxRouterBehavior {  // new behavior
	...
	
And add a callback for visibility changes:
	
	void routeChanged(bool routeVisible, List<String> params, bool visibilityChanged) {
		if (visible) { foo(); } else { bar(); }
	}
	
It cannot be easier! `routeChanged` callback will be invoked each time when:

- your element is invisible and should become visible
- your element is visible and should become invisible
- your element is visible, should stay visible, but params changed (see _Routing parameters_ above)
- your element is visible, should stay visible, but absolute route changed

Use argument `visibilityChanged` to decide whether your visibility actually changed,
or you are just being notified about some other change.

	if (visible && visibilityChanged) {
	  doSomeExpensiveLoadingStuff();
	}
	if (!visible && visibilityChanged) {
	  cancelAllTasks();
	}


## API

With `FnxRouterBehavior` your element has access to:

	// current state of visibility
	@property
	bool routeVisible = false;
	
	// last routing parameters
	@property
	List<String> routerParams = [];
	
	// absolute route to parent element (/amazing)
	@property
	String absoluteParentRoute = null;
	
	// absolute route to this element (/amazing/stuff)
	@property
	String absoluteRoute = null;
	
... and some methods for navigation, see [dartdoc](http://www.dartdocs.org/documentation/fnx_router/0.2.1/index.html).	

## Notes, details and TODOs

Routing rules for element are evaluated in `attached()` Polymer lifecycle method and cannot be changed later.

**fnx-router** works only with **shady DOM**.

## Contact

Feel free to contact me at `<user-element>tomucha</user-element><host-element separator="@">gmail.com</host-element>`,
or fill-in a bugreport on [Github issue tracking](https://github.com/fnx-io/fnx_router/issues).
