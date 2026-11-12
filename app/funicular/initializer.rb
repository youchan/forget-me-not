# nginx can mount this app under a path prefix (e.g. /forget-me-not) to
# share the domain with other services. The router matches routes against
# window.location.pathname as-is, so it needs the prefix baked into every
# route; it's read from the #app container's data-base attribute, which
# Rails renders from request.script_name (see app/views/tasks/index.html.erb).
app_container = JS.global.document.getElementById("app")
base_path = app_container&.getAttribute("data-base").to_s
# どのカテゴリを見ているか。空文字は「すべて」（絞り込みなし）
category_id = app_container&.getAttribute("data-category").to_s

module Funicular
  def self.mount_base_path
    @mount_base_path.to_s
  end

  def self.mount_base_path=(value)
    @mount_base_path = value
  end

  def self.active_category_id
    @active_category_id.to_s
  end

  def self.active_category_id=(value)
    @active_category_id = value
  end
end
Funicular.mount_base_path = base_path
Funicular.active_category_id = category_id

Funicular.start(container: "app") do |router|
  router.get("#{base_path}/", to: TaskBoard, as: "root")
  router.get("#{base_path}/tasks", to: TaskBoard, as: "tasks")
  router.set_default("#{base_path}/tasks")
end
