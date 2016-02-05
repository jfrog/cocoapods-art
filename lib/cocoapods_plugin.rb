require 'pod/command/repo_art'
require 'art_source'
require 'cocoapods-downloader'

Pod::HooksManager.register('cocoapods-repo-art', :source_provider) do |context, options|
    Pod::UI.message 'cocoapods-repo-art received source_provider hook'
    return unless (sources = options['sources'])
    sources.each do |source_name|
        source = create_source_from_name(source_name)
        if source
			# no auto-updates for now
            # update_source(source) unless Pod::Config.instance.skip_repo_update?
        else
          Pod::UI.warn "repo #{source_name} does not exist."
        end
        context.add_source(source)
    end
end

# @param [Source] source The source update
#
def update_source(source)
    name = source.name
    argv = CLAide::ARGV.new([name])
    cmd = Pod::Command::RepoArt::Update.new(argv)
    cmd.run
end

# @param source_name => name of source incoming from the Podfile configuration
#
# @return [ArtSource] source of the local spec repo which corresponds to to the given name
#
def create_source_from_name(source_name)
    repos_dir = Pod::Config.instance.repos_dir
    repo = repos_dir + source_name
    if File.exist?("#{repo}/.artpodrc")
        url = File.read("#{repo}/.artpodrc")
        Pod::ArtSource.new(repo, url)
    elsif Dir.exist?("#{repo}")
        Pod::ArtSource.new(repo, '');
    else
        nil
    end
end

#
# This ugly monkey patch is here just so we can pass the -n flag to curl and thus use the ~/.netrc file
# to manage credentials. Why this trivial option is not included in the first place is beyond me.
#
module Pod
    module Downloader
        class Http

            alias_method :orig_download_file, :download_file

            def download_file(full_filename)
                curl! '-n', '-f', '-L', '-o', full_filename, url, '--create-dirs'
            end

        end
    end
end
