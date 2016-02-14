require 'util/repo_util'

module Pod
  class Command
    class RepoArt
      class Push < RepoArt
        UTIL = Pod::RepoArt::RepoUtil

        extend Executable
        executable :curl

        self.summary = 'Push a spec to Artifactory'

        self.description = <<-DESC
                Creates a directory and version folder for the pod in the local copy of `REPO` (~/.cocoapods/repos/[REPO]),
                copies the podspec file into the version directory, and finally pushes the spec to Artifactory
        DESC

        self.arguments = [
            CLAide::Argument.new('REPO', true),
            CLAide::Argument.new('NAME.podspec', false)
        ]

        def self.options
          [
              ['--local-only', 'Does not push changes to Artifactory']
          ].concat(super)
        end

        def initialize(argv)
          @local_only = argv.flag?('local-only')
          @repo = argv.shift_argument
          @podspec = argv.shift_argument
          super
        end

        def validate!
          super
          help! 'A spec-repo name is required.' unless @repo
        end

        def run
          # update_repo
          add_specs_to_repo
        end

        # Updates the local repo against the Artifactory backend
        #
        # def update_repo
        #   argv = CLAide::ARGV.new([@repo])
        #   update = Command::RepoArt::Update.new(argv)
        #   update.run
        # end

        # Adds the specs to the local repo and pushes them to Artifactory if required
        #
        def add_specs_to_repo
          UI.puts "Adding the #{'spec'.pluralize(podspec_files.count)} to repo `#{@repo}'\n"
          podspec_files.each do |spec_file|
            spec = Pod::Specification.from_file(spec_file)
            output_path = File.join(repo_specs_dir, spec.name, spec.version.to_s)
            UI.puts " --> #{get_message(output_path, spec)}"
            unless @local_only
              begin
                push_to_remote(spec)
              rescue => e
                raise Informative, "Error pushing to remote '#{@repo}': #{e.message}"
              end

              begin
                create_json_in_path(output_path, spec)
              rescue => e
                raise Informative, "Error writing spec file in target path '#{output_path}': #{e.message}"
              end
            end
          end
        end

        private

        # Creates an op information message based on what's being done
        #
        # @param [Pathname] output_path path where the spec will be written
        #
        # @param [Specification] spec the spec
        #
        def get_message(output_path, spec)
          if Pathname.new(output_path).exist?
            message = "[Fix] #{spec}"
          elsif Pathname.new(File.join(repo_specs_dir, spec.name)).exist?
            message = "[Update] #{spec}"
          else
            message = "[Add] #{spec}"
          end
          message
        end

        # @param  [Pathname] output_path path where to create json spec
        #
        # @param  [Specification] spec to write
        #
        # @return [String] path where the json was written
        #
        def create_json_in_path(output_path, spec)
          url = UTIL.get_art_url(repo_root_dir)
          FileUtils.mkdir_p(output_path)
          podspec_json_path = "#{output_path}/#{spec.name}.podspec.json"
          podspec_json_tmp_path = "#{output_path}/#{spec.name}.podspec.json.tmp"
          FileUtils.remove(podspec_json_path, :force => true)
          podspec_json_temp = File.new(podspec_json_tmp_path, "wb")
          podspec_json_temp.puts(spec.to_pretty_json)
          podspec_json_temp.close
          curl! '-XPOST', "#{url}/index/modifySpec/#{spec.name}/#{spec.version.to_s}", '-n', '-L', '-H', '"Content-Type:application/json"', '-T', "#{podspec_json_tmp_path}", '-o', podspec_json_path, '--create-dirs'
          FileUtils.remove(podspec_json_temp, :force => true)
        end

        # @param  [Specification] spec the spec
        #
        def push_to_remote(spec)
          UI.puts 'Pushing index to Artifactory'
          url = UTIL.get_art_url(repo_root_dir)
          begin
            curl! '-XPUT', '-n', '-f', '-L', '-H', '"Content-Type:application/json"', "#{url}/index/pushSpec/#{spec.name}/#{spec.version.to_s}", '-d', "'#{spec.to_pretty_json}'"
          rescue => e
            raise Informative, "Error pushing spec to Artifactory: #{e.message}"
          end
          UI.puts "Spec #{spec.name}-#{spec.version.to_s} pushed successfully to Artifactory".green
        end

        # @return [Array<Pathname>] The path of the specifications to push.
        #
        def podspec_files
          if @podspec
            path = Pathname(@podspec)
            raise Informative, "Couldn't find #{@podspec}" unless path.exist?
            [path]
          else
            files = Pathname.glob('*.podspec{,.json}')
            raise Informative, "Couldn't find any podspec files in current directory" if files.empty?
            files
          end
        end

        # @return [Pathname] The Specs directory of the repository.
        #
        def repo_specs_dir
          root_dir = config.repos_dir + @repo
          specs_dir = Pathname.new(File.join(root_dir, 'Specs'))
          raise Informative, "'#{@repo}' is not an Artifactory-backed Specs repo" unless UTIL.art_repo?(root_dir)
          raise Informative, "Specs dir of repo `#{@repo}` not found in #{specs_dir}" unless File.exist?(specs_dir)
          specs_dir
        end

        # @return [Pathname] The root directory of the repository.
        #
        def repo_root_dir
          root_dir = config.repos_dir + @repo
          raise Informative, "'#{@repo}' is not an Artifactory-backed Specs repo" unless UTIL.art_repo?(root_dir)
          root_dir
        end

      end
    end
  end
end
