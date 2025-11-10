class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def index
    # Find CSS Zero asset paths
    engine_root = CssZero::Engine.root
    
    # Get CSS files (individual files in css-zero/ directory)
    css_path = engine_root.join("app/assets/stylesheets/css-zero")
    @css_files = if css_path.exist?
      Dir[css_path.join("*.css")].map { |f| File.basename(f) }.sort
    else
      []
    end
    
    # Check for the bundle file
    @bundle_file = engine_root.join("app/assets/stylesheets/css-zero.css")
    @has_bundle = @bundle_file.exist?
    
    # Get JavaScript controllers
    js_path = engine_root.join("app/javascript/css_zero/controllers")
    @js_controllers = if js_path.exist?
      Dir[js_path.join("*_controller.js")].map { |f| File.basename(f) }.sort
    else
      []
    end
    
    # Get images
    img_path = engine_root.join("app/assets/images/css_zero")
    @images = if img_path.exist?
      Dir[img_path.join("*.svg")].map { |f| File.basename(f) }.sort
    else
      []
    end
    
    # Get asset paths for display
    @asset_paths = Rails.application.config.assets.paths.select do |path|
      path.to_s.include?("css-zero") || path.to_s.include?("css_zero")
    end
  end
end

