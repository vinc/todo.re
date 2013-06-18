angular.module('todore', ['todoreServices']).
  config(['$routeProvider', '$locationProvider', function($routeProvider, $locationProvider) {
    $routeProvider.
      when('/welcome', { templateUrl: 'partials/lists.html', controller: TaskListsCtrl }).
      when('/lists', { templateUrl: 'partials/lists.html', controller: TaskListsCtrl }).
      when('/settings', { templateUrl: 'partials/settings.html', controller: SettingsCtrl }).
      otherwise({ redirectTo: '/lists' });
    $locationProvider.html5Mode(true);
  }]);
