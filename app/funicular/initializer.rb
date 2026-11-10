Funicular.start(container: "app") do |router|
  router.get("/", to: TaskBoard, as: "root")
  router.get("/tasks", to: TaskBoard, as: "tasks")
  router.set_default("/tasks")
end
