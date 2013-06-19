angular.module('todore').
  directive('switchColor', function($log) {
    var colors, nextColor;
   
    colors = ['grey', 'yellow', 'orange', 'red'];
    nextColor = function(color) {
      // TODO: Use underscore.js for IE < 9  
      return colors[(colors.indexOf(color) + 1) % colors.length];
    };

    return function(scope, elem, attrs) {
      elem.bind('click', function(e) {
        scope.$apply(function() {
          if (e.target.tagName != elem.prop('tagName')) { // FIXME: Ugly?
            return;
          }
          if (e.offsetX >= elem.prop('clientLeft')) {
            return;
          }
          $log.info('Changing list color to ' + scope.list.color);
          scope.list.color = nextColor(scope.list.color);
          scope.list.$update();
        });
      });
    };
  }).
  directive('textareaEvent', function($timeout, $log) {
    return function(scope, elem, attrs) {
      // Recompute textarea height
      resize = function() {
        $timeout(function() {
          elem.prop('rows', 1);
          elem.prop('rows', elem.prop('scrollHeight') /
                            elem.prop('clientHeight'));
        });
      };

      resize(); // Recompute at creation time
      
      elem.bind('blur', function(e) {
        scope.$apply(function() {
          var parentScope = scope.$parent.$parent;
          parentScope.status = 'Saving ...';
          $log.info('Updating list');
          scope.list.$update(function() {
            parentScope.status = 'Saved';
            $timeout(function() { parentScope.status = ''; }, 2000);
            $log.info('Changes saved');
          });
        });
      });

      elem.bind('keydown', function(e) {
        scope.$apply(function() {
          switch (e.which || e.keyCode) {
          case 8: // Backspace
            if (elem.val().length === 0) {
              if (scope.list.tasks.length > 1) {
                e.preventDefault();
                $log.info('Suppressing task');
                $timeout(function() {
                  var sib;
                  if (scope.$index > 0) {
                    sib = angular.element(elem.parent()[0].previousSibling);
                  } else {
                    sib = elem.parent().next();
                  }
                  sib.find('textarea')[0].focus();
                  scope.list.tasks.splice(scope.$index, 1);
                });
              } else {
                scope.task.done = false;
              }
            }
            break;
          case 13: // Enter
            e.preventDefault();
            $log.info('Adding task');
            scope.list.tasks.splice(scope.$index + 1, 0, {
              text: '',
              done: false
            });
            $timeout(function() {
              var sib = elem.parent().next();
              sib.find('textarea')[0].focus();
            });
            break;
          }
          resize();
        });
      });
    };
  });
