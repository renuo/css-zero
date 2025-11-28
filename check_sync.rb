#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'pathname'
require 'open3'

class SyncChecker
  def initialize
    @root = Pathname.new(__dir__)
    @errors = []
    @warnings = []
    @upstream_ref = determine_upstream_ref
  end

  def run
    puts "🔍 Checking CSS Zero sync status...\n\n"
    
    # Fetch upstream to ensure we have the latest refs
    puts "📥 Fetching upstream..."
    fetch_result = run_git_command('git fetch upstream')
    unless fetch_result[:success]
      puts "⚠️  Warning: Could not fetch upstream. Using cached refs.\n\n"
    else
      puts "✓ Upstream fetched\n\n"
    end
    
    unless @upstream_ref
      puts "❌ Could not determine upstream reference. Make sure 'upstream' remote is configured."
      exit 1
    end
    
    puts "📦 Using upstream reference: #{@upstream_ref}\n\n"
    
    check_css_files
    check_css_includes
    check_stimulus_controllers
    
    print_results
    exit(@errors.empty? ? 0 : 1)
  end

  private

  def determine_upstream_ref
    # Try to get the default branch from upstream
    result = run_git_command('git ls-remote --symref upstream HEAD')
    return nil unless result[:success]
    
    # Extract branch name from output like "ref: refs/heads/main	HEAD"
    match = result[:output].match(/ref:\s+refs\/heads\/(\S+)/)
    return "upstream/#{match[1]}" if match
    
    # Fallback: try common branch names
    %w[main master].each do |branch|
      result = run_git_command("git ls-remote --heads upstream #{branch}")
      return "upstream/#{branch}" if result[:success] && !result[:output].empty?
    end
    
    nil
  end

  def run_git_command(cmd)
    stdout, stderr, status = Open3.capture3(cmd, chdir: @root.to_s)
    { success: status.success?, output: stdout, error: stderr }
  end

  def get_file_from_upstream(path)
    git_path = path.relative_path_from(@root).to_s
    result = run_git_command("git show #{@upstream_ref}:#{git_path}")
    result[:success] ? result[:output] : nil
  end

  def get_file_from_upstream_path(git_path)
    result = run_git_command("git show #{@upstream_ref}:#{git_path}")
    result[:success] ? result[:output] : nil
  end

  def file_exists_in_upstream?(path)
    git_path = path.relative_path_from(@root).to_s
    result = run_git_command("git cat-file -e #{@upstream_ref}:#{git_path} 2>/dev/null")
    result[:success]
  end

  def file_exists_in_upstream_path?(git_path)
    result = run_git_command("git cat-file -e #{@upstream_ref}:#{git_path} 2>/dev/null")
    result[:success]
  end

  def check_css_files
    puts "📄 Checking CSS files match upstream..."
    
    current_css_dir = @root.join('app/assets/stylesheets/css-zero')
    return unless current_css_dir.exist?
    
    # Core CSS files that exist in app/assets/stylesheets/css-zero/ in upstream
    core_css_files = %w[
      variables.css reset.css colors.css typography.css sizes.css
      borders.css effects.css filters.css transforms.css transitions.css
      animations.css utilities.css
    ]
    
    # base.css is in install templates, not in app directory
    install_template_css = %w[base.css]
    
    current_files = Dir.glob(current_css_dir.join('*.css')).map { |f| File.basename(f) }
    
    # Check each current file against upstream
    current_files.each do |filename|
      current_path = current_css_dir.join(filename)
      
      # Determine upstream path based on file type
      if core_css_files.include?(filename)
        upstream_path = "app/assets/stylesheets/css-zero/#{filename}"
      elsif install_template_css.include?(filename)
        upstream_path = "lib/generators/css_zero/install/templates/app/assets/stylesheets/#{filename}"
      else
        # Component files are in templates
        upstream_path = "lib/generators/css_zero/add/templates/app/assets/stylesheets/#{filename}"
      end
      
      unless file_exists_in_upstream_path?(upstream_path)
        @warnings << "⚠️  CSS file not in upstream: #{filename}"
        next
      end
      
      upstream_content = get_file_from_upstream_path(upstream_path)
      unless upstream_content
        @errors << "❌ Could not read CSS file from upstream: #{filename}"
        next
      end
      
      upstream_md5 = Digest::MD5.hexdigest(upstream_content)
      current_md5 = Digest::MD5.file(current_path).hexdigest
      
      if upstream_md5 != current_md5
        @errors << "❌ CSS file MD5 mismatch: #{filename} (upstream: #{upstream_md5[0..7]}..., current: #{current_md5[0..7]}...)"
      else
        puts "  ✓ #{filename}"
      end
    end
  end

  def check_css_includes
    puts "\n📋 Checking CSS files are included in css-zero.css..."
    
    css_zero_file = @root.join('app/assets/stylesheets/css-zero.css')
    current_css_dir = @root.join('app/assets/stylesheets/css-zero')
    
    return unless css_zero_file.exist? && current_css_dir.exist?
    
    # Read css-zero.css and extract imported filenames
    css_content = File.read(css_zero_file)
    imported_files = css_content.scan(/@import url\("css-zero\/([^"]+)"\)/).flatten.map { |f| f.sub(/\.css$/, '') + '.css' }
    
    # Get all CSS files in current directory
    current_files = Dir.glob(current_css_dir.join('*.css')).map { |f| File.basename(f) }
    
    # Check each current file is imported
    current_files.each do |filename|
      unless imported_files.include?(filename)
        @errors << "❌ CSS file not included in css-zero.css: #{filename}"
      else
        puts "  ✓ #{filename} included"
      end
    end
    
    # Warn about imports that don't have corresponding files
    imported_files.each do |filename|
      unless current_files.include?(filename)
        @warnings << "⚠️  css-zero.css imports non-existent file: #{filename}"
      end
    end
  end

  def check_stimulus_controllers
    puts "\n🎮 Checking Stimulus controllers match upstream..."
    
    current_js_dir = @root.join('app/javascript/css_zero/controllers')
    return unless current_js_dir.exist?
    
    current_files = Dir.glob(current_js_dir.join('*.js')).map { |f| File.basename(f) }
    
    # Check each current file against upstream (controllers are in templates)
    current_files.each do |filename|
      current_path = current_js_dir.join(filename)
      upstream_path = "lib/generators/css_zero/add/templates/app/javascript/controllers/#{filename}"
      
      unless file_exists_in_upstream_path?(upstream_path)
        @warnings << "⚠️  Stimulus controller not in upstream: #{filename}"
        next
      end
      
      upstream_content = get_file_from_upstream_path(upstream_path)
      unless upstream_content
        @errors << "❌ Could not read Stimulus controller from upstream: #{filename}"
        next
      end
      
      upstream_md5 = Digest::MD5.hexdigest(upstream_content)
      current_md5 = Digest::MD5.file(current_path).hexdigest
      
      if upstream_md5 != current_md5
        @errors << "❌ Stimulus controller MD5 mismatch: #{filename} (upstream: #{upstream_md5[0..7]}..., current: #{current_md5[0..7]}...)"
      else
        puts "  ✓ #{filename}"
      end
    end
  end

  def print_results
    puts "\n" + "=" * 60
    puts "📊 Summary"
    puts "=" * 60
    
    if @errors.empty? && @warnings.empty?
      puts "✅ All checks passed!"
    else
      puts "\n#{@errors.length} error(s) found:" if @errors.any?
      @errors.each { |error| puts "  #{error}" }
      
      puts "\n#{@warnings.length} warning(s) found:" if @warnings.any?
      @warnings.each { |warning| puts "  #{warning}" }
    end
    
    puts "=" * 60
  end
end

SyncChecker.new.run if __FILE__ == $PROGRAM_NAME

