require 'fileutils'

module PodHelpers
  @kept_aosl_pod = nil

  # Scan all Pods for aosl.xcframework, compare versions via Info.plist,
  # keep the highest version, and delete the rest.
  def self.handle_aosl_conflict(installer)
    pods_root = installer.sandbox.root

    # 1. Find all Pods that contain aosl.xcframework
    aosl_entries = []
    Dir.glob(File.join(pods_root, '*', 'aosl.xcframework')).each do |xcfw_path|
      pod_name = File.basename(File.dirname(xcfw_path))

      # 2. Read version from Info.plist inside any arch slice
      info_plist = Dir.glob(File.join(xcfw_path, 'ios-arm64*', 'aosl.framework', 'Info.plist')).first
      unless info_plist
        puts "[aosl-dedup] WARNING: No Info.plist found in #{xcfw_path}, skipping."
        next
      end

      version_str = %x(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "#{info_plist}" 2>/dev/null).strip
      if version_str.empty?
        puts "[aosl-dedup] WARNING: Could not read version from #{info_plist}, skipping."
        next
      end

      aosl_entries << { pod: pod_name, path: xcfw_path, version: version_str }
    end

    if aosl_entries.empty?
      puts "[aosl-dedup] No aosl.xcframework found, nothing to do."
      return
    end

    # 3. Sort by version (Gem::Version handles semantic version comparison)
    aosl_entries.sort_by! { |e| Gem::Version.new(e[:version]) }

    keep = aosl_entries.last
    @kept_aosl_pod = keep[:pod]

    if aosl_entries.size == 1
      puts "[aosl-dedup] Found 1 aosl.xcframework (#{keep[:pod]} v#{keep[:version]}), no conflict to resolve."
      return
    end

    puts "[aosl-dedup] Found #{aosl_entries.size} aosl.xcframework(s):"
    aosl_entries.each do |entry|
      marker = entry == keep ? '  (keep)' : '  (remove)'
      puts "[aosl-dedup]   #{entry[:pod]}: v#{entry[:version]}#{marker}"
    end

    # 4. Remove all lower-version copies
    aosl_entries[0..-2].each do |entry|
      puts "[aosl-dedup] Removing aosl.xcframework v#{entry[:version]} from #{entry[:pod]}"
      FileUtils.rm_rf(entry[:path])
    end

    puts "[aosl-dedup] Done. Kept aosl.xcframework v#{keep[:version]} from #{keep[:pod]}."
  end

  # Removing a duplicate aosl.xcframework in pre_install is not enough when the
  # losing pod's podspec also declares `weak_frameworks`/`frameworks` with
  # `aosl` (e.g. AgoraVideo_Special_iOS): CocoaPods generates those link flags
  # from the podspec text regardless of file existence, so the target still
  # links `-weak_framework "aosl"` while its FRAMEWORK_SEARCH_PATHS no longer
  # contains any copy, failing with "Framework 'aosl' not found".
  #
  # Strip the aosl link flags from every generated xcconfig that cannot see
  # the kept copy (its FRAMEWORK_SEARCH_PATHS does not include the kept pod).
  def self.scrub_aosl_ldflags(installer)
    keeper = @kept_aosl_pod
    if keeper.nil?
      puts "[aosl-dedup] No kept aosl pod recorded, skipping xcconfig scrub."
      return
    end

    support_dir = File.join(installer.sandbox.root, 'Target Support Files')
    Dir.glob(File.join(support_dir, '**', '*.xcconfig')).each do |xcconfig_path|
      content = File.read(xcconfig_path)
      next unless content.match?(/-(?:weak_)?framework "aosl"/)

      search_paths = content[/^FRAMEWORK_SEARCH_PATHS = .*$/]
      next if search_paths && search_paths.include?("/#{keeper}")

      scrubbed = content.gsub(/ ?-(?:weak_)?framework "aosl"/, '')
      next if scrubbed == content

      File.write(xcconfig_path, scrubbed)
      rel = xcconfig_path.sub("#{installer.sandbox.root}/", '')
      puts "[aosl-dedup] Stripped aosl link flags from #{rel} (no search path to #{keeper})."
    end
  end
end
