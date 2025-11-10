module CssZero
  class Engine < ::Rails::Engine
    isolate_namespace CssZero

    initializer "css_zero.assets" do |app|
      %w[images stylesheets].each do |subdir|
        path = root.join("app/assets", subdir)
        app.config.assets.paths << path if path.exist?
      end

      app.config.assets.paths << root.join("app/javascript")
    end

    config.app_generators do |g|
      g.template_engine :css_zero
    end
  end
end
