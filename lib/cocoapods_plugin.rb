require 'pod/command/repo_art'
require 'art_source'
require 'cocoapods-downloader'
require 'cocoapods_art'

UTIL = Pod::RepoArt::RepoUtil

Pod::HooksManager.register('cocoapods-art', :source_provider) do |context, options|
  Pod::UI.message 'cocoapods-art received source_provider hook'
  return unless (sources = options['sources'])
  sources.each do |source_name|
    source = create_source_from_name(source_name)
    context.add_source(source)
  end
end

# @param source_name => name of source incoming from the Podfile configuration
#
# @return [ArtSource] source of the local spec repo which corresponds to to the given name
#
def create_source_from_name(source_name)
    art_repo = "#{UTIL.get_repos_art_dir()}/#{source_name}"
    repos_dir = Pod::Config.instance.repos_dir
    repo = repos_dir + source_name

    Pod::UI.puts "#{art_repo}/.artpodrc\n"

    if File.exist?("#{art_repo}/.artpodrc")
        url = File.read("#{art_repo}/.artpodrc")
        Pod::ArtSource.new(art_repo, url)
    elsif Dir.exist?("#{repo}")
        Pod::ArtSource.new(repo, '');
    else
     raise Pod::Informative.exception "repo #{source_name} does not exist."
    end
end

#
# This patch is here just so we can pass the -n flag to curl and thus use the ~/.netrc file
# to manage credentials.
#
module Pod
  module Downloader
    class Http
      # Force flattening of index downloads with :indexDownload => true
      def self.options
        [:type, :flatten, :sha1, :sha256, :indexDownload]
      end

      alias_method :orig_download_file, :download_file
      alias_method :orig_should_flatten?, :should_flatten?

      def download_file(full_filename)
        curl_options = ["-f", "-L", "-o", full_filename, url, "--create-dirs", "--netrc-optional"]

        netrc_path = ENV["COCOAPODS_ART_NETRC_PATH"]
        curl_options.concat(["--netrc-file", Pathname.new(netrc_path).expand_path]) if netrc_path

        curl! curl_options
      end

      # Note that we disabled flattening here for the ENTIRE client to deal with
      # default flattening for non zip archives messing up tarballs incoming
      def should_flatten?
        # TODO uncomment when Artifactory stops sending the :flatten flag
        # if options.key?(:flatten)
        #   true
        # else
        #   false
        # end
        if options.key?(:indexDownload)
          true
        else
          orig_should_flatten?
        end
      end
    end
  end
end

# Override pod's default behavior which is force the master spec repo if
# no sources defined - at this point the plugin sources are not yet fetched from the plugin
# with the source provider hook thus empty Podfiles that only have the plugin declared will
# force a master repo update.
module Pod
    class Installer
        class Analyzer

          alias_method :orig_sources, :sources

          def sources
            if podfile.sources.empty? && podfile.plugins.keys.include?('cocoapods-art')
              sources = Array.new
              plugin_config = podfile.plugins['cocoapods-art']
              # all sources declared in the plugin clause
              plugin_config['sources'].uniq.map do |name|
                sources.push(create_source_from_name(name))
              end
              @sources = sources
            else
              orig_sources
            end
          end
        end
    end
  end
