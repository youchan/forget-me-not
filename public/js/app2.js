var demoApp = angular.module('demoApp', ['ui']);
demoApp.filter('xxx', function() {
  //絞込みを行う関数
  //    array:array    ng-repeatのarray
  //    query:string  ng-repeatのquery
  return function(data, query) {

    //ここで全てのデータを見て検索結果をreturnする

    var result = [];
    for (var i = 0, l = data.length; i < l; i++) {
      !!data[i].start !== query && result.push(data[i]);
    }

    return result;
  };
});

function eventCtrl($scope) {
  $scope.items = [
    {
      title: 'Todo リストを作る'
    },
    {
      title: 'カレンダーUIを作る'
    }
  ];
  $scope.add = function() {
    $scope.items.push({title: $scope.newItem});
    $scope.newItem = '';
    return false;
  };
  $scope.removeTodo = function(item) {
    $scope.items.indexOf(item) >= 0 &&
    $scope.items.splice($scope.items.indexOf(item), 1);

    $scope.events.indexOf(item) >= 0 &&
    $scope.events.splice($scope.events.indexOf(item), 1);
    return false;
  };

  $scope.events = [];

  $scope.appendCalendarEvent = function(item) {
    if ($scope.events.indexOf(item) >= 0) {
      return;
    }

    var date = new Date();
    item.start = new Date(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours() +
        1, 0, 0);
    item.end = new Date(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours() +
        2, 0, 0);

    item.allDay = false;
    $scope.events.push(item);
  };
}