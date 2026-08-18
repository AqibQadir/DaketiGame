def flutter_install_all_ios_pods(_dir)
  plugins_dir = File.join(_dir, '.symlinks', 'plugins')
  return unless Dir.exist?(plugins_dir)

  Dir.entries(plugins_dir).each do |entry|
    next if entry == '.' || entry == '..'
    plugin_path = File.join(plugins_dir, entry)
    podspecs = Dir.glob(File.join(plugin_path, '*'))
    # Try to find a podspec file inside the plugin folder
    podspec = podspecs.find { |p| p.end_with?('.podspec') }
    if podspec
      pod entry.to_sym, :path => plugin_path
    end
  end
end

def __apply_Xcode_12_5_M1_post_install_workaround(installer)
  # noop - provided for compatibility with Flutter's standard Podfile
end
