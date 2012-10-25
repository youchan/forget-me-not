function TodoEntriesController($scope) {
  $scope.unscheduledEntries = [];
  $scope.scheduledEntries = [];

  $scope.addEntry = function() {
    console.log("addEntry");
    $scope.unscheduledEntries.push({description: $scope.entryDescription, period: 1});
    $scope.entryDescription = "";
  }
}

