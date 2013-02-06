var demoApp = angular.module('demoApp', ['ui']);
function eventCtrl($scope) {
	$scope.items = [{
		title: 'Todo リストを作る'
	}, {
		title: 'カレンダーUIを作る'
	}];
	$scope.add = function(){		
		$scope.items.push({title: $scope.newItem});
		$scope.newItem = '';
		return false;
	};
	$scope.removeTodo = function(item) {
		$scope.items.splice($scope.items.indexOf(item), 1);
		$scope.events.splice($scope.events.indexOf(item), 1);
		return false;
	};

	$scope.events = [];

	$scope.appendCalendarEvent = function(item) {
		var date = new Date();
		item.start = new Date(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours() + 1, 0, 0);
		item.end = new Date(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours() + 2, 0, 0);

		item.allDay = false;
		$scope.events.push(item);
	};
}