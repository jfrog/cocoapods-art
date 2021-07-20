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
        [:type, :flatten, :sha1, :sha256, :indexDownload, :headers]
      end

      alias_method :orig_download_file, :download_file
      alias_method :orig_should_flatten?, :should_flatten?

      def download_file(full_filename)
        parameters = ["-f", "-L", "-o", full_filename, url, "--create-dirs", "--netrc-optional", '--retry', '2']
        parameters << user_agent_argument if headers.nil? ||
            headers.none? { |header| header.casecmp(USER_AGENT_HEADER).zero? }

        ssl_conf = ["--cert", `git config --global http.sslcert`.gsub("\n", ""), "--key", `git config --global http.sslkey`.gsub("\n", "")]
        parameters.concat(ssl_conf) if !ssl_conf.any?(&:blank?)

        netrc_path = ENV["COCOAPODS_ART_NETRC_PATH"]
        parameters.concat(["--netrc-file", Pathname.new(netrc_path).expand_path]) if netrc_path

        art_credentials = ENV["COCOAPODS_ART_CREDENTIALS"]
        parameters.concat(["--user", art_credentials]) if art_credentials
	
        winssl_no_revoke = ENV["COCOAPODS_ART_SSL_NO_REVOKE"]
        parameters.concat(["--ssl-no-revoke"]) if defined? winssl_no_revoke && "true".casecmp(winssl_no_revoke)

        headers.each do |h|
          parameters << '-H'
          parameters << h
        end unless headers.nil?

        curl! parameters
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

module Pod
    class Source
        class Manager

          alias_method :orig_source_from_path, :source_from_path

          # @return [Source] The Source at a given path.
          #
          # @param [Pathname] path
          #        The local file path to one podspec repo.
          #
          def source_from_path(path)
            @sources_by_path ||= Hash.new do |hash, key|
              art_repo = "#{UTIL.get_repos_art_dir()}/#{key.basename}"
              hash[key] = case
                          when key.basename.to_s == Pod::TrunkSource::TRUNK_REPO_NAME
                            TrunkSource.new(key)
                          when (key + '.url').exist?
                            CDNSource.new(key)
                          when File.exist?("#{art_repo}/.artpodrc")
                            create_source_from_name(key.basename)
                          else
                            Source.new(key)
                          end
            end
            @sources_by_path[path]
          end

        end
    end
end