module Fastlane
  module Actions
    class SimulatorWatch < FastlaneCore::Simulator
      class << self
        def requested_os_type
          'watchOS'
        end
      end
    end

    _ios_sim = FastlaneCore::Simulator.all.last
    _tvos_sim = FastlaneCore::SimulatorTV.all.last
    _watchos_sim = SimulatorWatch.all.last

    BUILD_LOG_DIR = ENV['CIRCLE_ARTIFACTS'] || "fastlane/test_output/build_log"
    TEST_REPORTS_DIR = ENV['CIRCLE_TEST_REPORTS'] || "fastlane/test_output/test_report"

    SIMULATORS = {
      :OSX => "platform=OS X",
      :iOS => _ios_sim && "platform=iOS Simulator,name=#{_ios_sim}",
      :tvOS => _tvos_sim && "platform=tvOS Simulator,name=#{_tvos_sim}",
      :watchOS => _watchos_sim && "platform=watchOS Simulator,name=#{_watchos_sim}"
    }

    class TestUniversalFrameworkAction < Action

      def self._test_platform(platform, scheme: "OSX")
        if SIMULATORS[platform.to_sym].nil? then
          raise "Simulator not found for #{platform}."
        end

        require 'scan'

        config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
          scheme: scheme,
          destination: SIMULATORS[platform],
          code_coverage: true,
          buildlog_path: "#{BUILD_LOG_DIR}/#{platform}",
          output_directory: "#{TEST_REPORTS_DIR}/#{platform}",
          clean: true
          })

        Fastlane::Actions::ScanAction.run(config)
      end

      def self.run(params)
        Helper.log.info "Run TestUniversalFrameworkAction."

        _test_platform(params[:platform], scheme: params[:scheme])
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Runs tests in target platform."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :platform,
                                       env_name: "FL_TEST_UNIVERSAL_FRAMEWORK_PLATFORM",
                                       description: "Xcode simulator platform for testing universal framework",
                                       is_string: false,
                                       verify_block: proc do |value|
                                          raise "No platform for TestUniversalFramework given, pass using `platform: 'platform'`".red unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :scheme,
                                       env_name: "FL_TEST_UNIVERSAL_FRAMEWORK_SCHEME",
                                       description: "Xcode scheme for testing universal framework",
                                       verify_block: proc do |value|
                                          raise "No scheme for TestUniversalFramework given, pass using `scheme: 'scheme'`".red unless (value and not value.empty?)
                                       end)
        ]
      end

      def self.authors
        ["Yasuhiro Inami"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
