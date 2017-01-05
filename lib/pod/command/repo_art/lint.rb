module Pod
  class Command
    class RepoArt
      class Lint < RepoArt
        self.summary = 'Validates all specs in a repo.'

        self.description = <<-DESC
          Lints the spec-repo `NAME`. If a directory is provided it is assumed
          to be the root of a repo. Finally, if `NAME` is not provided this
          will lint all the Artifactory-backed spec-repos known to CocoaPods.
        DESC

        self.arguments = [
            CLAide::Argument.new(%w(NAME DIRECTORY), true)
        ]

        def self.options
          [
              ['--only-errors', 'Lint presents only the errors']
          ].concat(super)
        end

        def initialize(argv)
          init
          @name = argv.shift_argument
          @only_errors = argv.flag?('only-errors')
          super
        end

        def run
          repos = if @name
                      UTIL.get_art_repo(@name)
                    else
                        UTIL.get_art_repos
                    end

          repos.each do |repo|
            UI.puts "\nLinting spec repo `#{repo.name}`\n".yellow

            validator = Source::HealthReporter.new(repo.path)
            validator.pre_check do |_name, _version|
              UI.print '.'
            end
            report = validator.analyze
            UI.puts
            UI.puts

            report.pods_by_warning.each do |message, versions_by_name|
              UI.puts "-> #{message}".yellow
              versions_by_name.each { |name, versions| UI.puts "  - #{name} (#{versions * ', '})" }
              UI.puts
            end

            report.pods_by_error.each do |message, versions_by_name|
              UI.puts "-> #{message}".red
              versions_by_name.each { |name, versions| UI.puts "  - #{name} (#{versions * ', '})" }
              UI.puts
            end

            UI.puts "Analyzed #{report.analyzed_paths.count} podspecs files.\n\n"
            if report.pods_by_error.count.zero?
              UI.puts 'All the specs passed validation.'.green << "\n\n"
            else
              raise Informative, "#{report.pods_by_error.count} podspecs failed validation."
            end
          end
        end

      end
    end
  end
end
