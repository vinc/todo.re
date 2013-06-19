function TaskListsCtrl($scope, $log, $timeout, TaskList) {
  $scope.status = 'Loading ...';

  $scope.lists = TaskList.query(function() {
    setTimeout(function() {
      var textareas;

      textareas = angular.element(document).find('textarea');
      angular.forEach(textareas, function(textarea) {
        this.rows = 1;
        this.rows = this.scrollHeight / this.clientHeight;
      });

      $scope.status = '';
    }, 0);
  });

  $scope.update = function() {
    $scope.status = 'Saving ...';
    this.list.$update(function() {
      $log.info('Changes saved');
      $scope.status = 'Saved';
      $timeout(function() { $scope.status = ''; }, 2000);
    });
  };

  $scope.addList = function() {
    TaskList.create(function(list) {
      $log.info('Adding list');
      $scope.lists.push(list);
    });
  };

  $scope.listKeydown = function(e) {
    var name, tasks;

    name = e.target.value;
    tasks = this.list.tasks || [];
    switch (e.which) {
    case 8: // Backspace
      if (name.length === 0) {
        if (tasks.length > 1) {
           break;
        } else if (tasks.length === 1 && tasks[0].text.length > 0) {
          break;
        }
        $log.info('Suppressing list');
        $scope.lists.splice(this.$index, 1);
        this.list.$delete();
      }
      break;
    case 13: // Enter
      $log.info('Adding task');
      e.preventDefault();
      tasks.splice(0, 0, {
        text: '',
        done: false
      });
      this.list.$update();
      break;
    }
    e.target.rows = 1;
    e.target.rows = e.target.scrollHeight / e.target.clientHeight;
  };
}

function SettingsCtrl($scope, $log, Settings) {
  $scope.settings = Settings.get();
}

TaskListsCtrl.$inject = ['$scope', '$log', '$timeout', 'TaskList'];
SettingsCtrl.$inject = ['$scope', '$log', 'Settings'];
