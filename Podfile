platform :ios, '12.0'

inhibit_all_warnings!

target 'Deltroid' do
    use_modular_headers!

    pod 'DeltaCore', :path => 'Cores/DeltaCore'
    pod 'NESDeltaCore', :path => 'Cores/NESDeltaCore'
    pod 'SNESDeltaCore', :path => 'Cores/SNESDeltaCore'
    pod 'N64DeltaCore', :path => 'Cores/N64DeltaCore'
    pod 'GBCDeltaCore', :path => 'Cores/GBCDeltaCore'
    pod 'GBADeltaCore', :path => 'Cores/GBADeltaCore'
    pod 'DSDeltaCore', :path => 'Cores/DSDeltaCore'
    pod 'MelonDSDeltaCore', :path => 'Cores/MelonDSDeltaCore'
end

# Unlink DeltaCore to prevent conflicts with Systems.framework
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
            config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
            config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
        end
        if target.name == "Pods-Deltroid"
            puts "Updating #{target.name} OTHER_LDFLAGS"
            target.build_configurations.each do |config|
                xcconfig_path = config.base_configuration_reference.real_path
                xcconfig = File.read(xcconfig_path)
                new_xcconfig = xcconfig.sub('-l"DeltaCore"', '')
                File.open(xcconfig_path, "w") { |file| file << new_xcconfig }
            end
        end
    end
end
