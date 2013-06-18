angular.module('todoreServices', ['ngResource']).
  factory('TaskList', function($resource) {
    return $resource('lists/:id.json', { id: '@_id' }, {
      create: { method: 'POST' },
      update: { method: 'PUT' }
    });
  }).
  factory('Settings', function($resource) {
    return $resource('settings.json');
  });
