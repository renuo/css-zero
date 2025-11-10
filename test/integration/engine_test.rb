require "test_helper"

class EngineTest < ActionDispatch::IntegrationTest
  test "css zero engine is loaded" do
    assert defined?(CssZero::Engine)
  end

  test "css zero assets are available in asset paths" do
    asset_paths = Rails.application.config.assets.paths
    css_zero_stylesheet_path = asset_paths.find { |path| path.include?("css-zero") && path.include?("stylesheets") }
    
    assert css_zero_stylesheet_path, "CSS Zero stylesheets path should be in asset paths"
    assert File.directory?(css_zero_stylesheet_path), "CSS Zero stylesheets directory should exist"
  end

  test "css zero core files exist" do
    # Find the engine's stylesheet path (not the dummy app's)
    css_zero_path = Rails.application.config.assets.paths.find { |path| 
      path.include?("css-zero") && path.include?("stylesheets") && !path.include?("test/dummy")
    }
    
    assert css_zero_path, "CSS Zero engine stylesheet path should be in asset paths"
    
    core_files = %w[variables.css reset.css colors.css typography.css utilities.css]
    core_files.each do |file|
      full_path = File.join(css_zero_path, "css-zero", file)
      assert File.exist?(full_path), "#{file} should exist in CSS Zero assets at #{full_path}"
    end
  end
end

