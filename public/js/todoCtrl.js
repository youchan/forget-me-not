function todoCtrl($scope, todoCalendar) {
	$scope.items = [{
		text: 'Todo リストを作る'
	}, {
		text: 'カレンダーUIを作る'
	}];
	$scope.add = function(){		
		$scope.items.push({text: $scope.newItem});
		$scope.newItem = '';
	};
	$scope.remove = function(item) {
		$scope.items.splice($scope.items.indexOf(item), 1);
	};
	$scope.appendCalendarEvent = function(item){
		console.log(item);
		todoCalendar.insert(item);
	};
}